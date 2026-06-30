import 'package:supabase_flutter/supabase_flutter.dart';

class UsageQuotaFeatureKey {
  static const aiChatMessage = 'ai_chat_message';
  static const personalScheduleGeneration = 'personal_schedule_generation';

  const UsageQuotaFeatureKey._();
}

class UsageQuotaDecision {
  final bool allowed;
  final int? usedCount;
  final int? limitCount;
  final DateTime? resetAt;
  final String? reasonCode;

  const UsageQuotaDecision({
    required this.allowed,
    this.usedCount,
    this.limitCount,
    this.resetAt,
    this.reasonCode,
  });

  const UsageQuotaDecision.allowed()
    : this(allowed: true, usedCount: null, limitCount: null);

  const UsageQuotaDecision.denied({
    int? usedCount,
    int? limitCount,
    DateTime? resetAt,
    String? reasonCode,
  }) : this(
         allowed: false,
         usedCount: usedCount,
         limitCount: limitCount,
         resetAt: resetAt,
         reasonCode: reasonCode,
       );

  factory UsageQuotaDecision.fromRpcResponse(Object? response) {
    final row = _firstMap(response);
    if (row == null) {
      if (response is bool) {
        return response
            ? const UsageQuotaDecision.allowed()
            : const UsageQuotaDecision.denied(reasonCode: 'quota_exceeded');
      }
      throw const UsageQuotaUnavailableException();
    }

    final allowed = _readBool(row['allowed'] ?? row['committed']);
    return UsageQuotaDecision(
      allowed: allowed,
      usedCount: _readInt(row['used_count']),
      limitCount: _readInt(row['limit_count']),
      resetAt: DateTime.tryParse(row['reset_at']?.toString() ?? ''),
      reasonCode: row['reason_code']?.toString(),
    );
  }

  static Map<String, Object?>? _firstMap(Object? response) {
    if (response is Map) return Map<String, Object?>.from(response);
    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, Object?>.from(response.first as Map);
    }
    return null;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

abstract class UsageQuotaException implements Exception {
  String get userMessage;
}

class UsageQuotaAuthRequiredException implements UsageQuotaException {
  static const message = 'Bạn đăng nhập để Nabi trò chuyện AI cùng bạn nhé.';

  const UsageQuotaAuthRequiredException();

  @override
  String get userMessage => message;

  @override
  String toString() => userMessage;
}

class UsageQuotaExceededException implements UsageQuotaException {
  static const message =
      'Hôm nay bạn đã dùng hết lượt trò chuyện AI. Mình quay lại cùng nhau sau kỳ làm mới nhé.';

  final UsageQuotaDecision decision;

  const UsageQuotaExceededException(this.decision);

  @override
  String get userMessage => message;

  @override
  String toString() => userMessage;
}

class UsageQuotaUnavailableException implements UsageQuotaException {
  static const message =
      'Nabi chưa kiểm tra được lượt dùng lúc này. Bạn thử lại sau một chút nhé.';

  const UsageQuotaUnavailableException();

  @override
  String get userMessage => message;

  @override
  String toString() => userMessage;
}

abstract class UsageQuotaRpcClient {
  String? get currentUserId;

  Future<Object?> rpc(
    String functionName, {
    Map<String, Object?> params = const {},
  });
}

class SupabaseUsageQuotaRpcClient implements UsageQuotaRpcClient {
  final SupabaseClient? clientOverride;

  const SupabaseUsageQuotaRpcClient({this.clientOverride});

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  @override
  String? get currentUserId => _client?.auth.currentUser?.id;

  @override
  Future<Object?> rpc(
    String functionName, {
    Map<String, Object?> params = const {},
  }) async {
    final client = _client;
    if (client == null) {
      throw const UsageQuotaUnavailableException();
    }
    return client.rpc(functionName, params: params);
  }
}

abstract class UsageQuotaGateway {
  Future<UsageQuotaDecision> checkCurrentUserQuota({
    required String featureKey,
    required String requestId,
    DateTime? at,
  });

  Future<void> commitCurrentUserQuota({
    required String featureKey,
    required String requestId,
    DateTime? at,
  });
}

class TrustedBackendUsageQuotaGateway implements UsageQuotaGateway {
  static const resetTimezone = 'Asia/Ho_Chi_Minh';

  final UsageQuotaRpcClient rpcClient;
  final DateTime Function() now;

  const TrustedBackendUsageQuotaGateway({
    this.rpcClient = const SupabaseUsageQuotaRpcClient(),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  @override
  Future<UsageQuotaDecision> checkCurrentUserQuota({
    required String featureKey,
    required String requestId,
    DateTime? at,
  }) async {
    return checkQuota(
      userId: _requireCurrentUserId(),
      featureKey: featureKey,
      requestId: requestId,
      at: at ?? now(),
    );
  }

  @override
  Future<void> commitCurrentUserQuota({
    required String featureKey,
    required String requestId,
    DateTime? at,
  }) async {
    return commitQuota(
      userId: _requireCurrentUserId(),
      featureKey: featureKey,
      requestId: requestId,
      at: at ?? now(),
    );
  }

  Future<UsageQuotaDecision> checkQuota({
    required String userId,
    required String featureKey,
    required String requestId,
    required DateTime at,
  }) async {
    final response = await rpcClient.rpc(
      'check_usage_quota',
      params: _params(
        userId: userId,
        featureKey: featureKey,
        requestId: requestId,
        at: at,
      ),
    );
    final decision = UsageQuotaDecision.fromRpcResponse(response);
    if (!decision.allowed) throw UsageQuotaExceededException(decision);
    return decision;
  }

  Future<void> commitQuota({
    required String userId,
    required String featureKey,
    required String requestId,
    required DateTime at,
  }) async {
    final response = await rpcClient.rpc(
      'commit_usage_quota',
      params: _params(
        userId: userId,
        featureKey: featureKey,
        requestId: requestId,
        at: at,
      ),
    );
    final decision = UsageQuotaDecision.fromRpcResponse(response);
    if (!decision.allowed) throw UsageQuotaExceededException(decision);
  }

  Map<String, Object?> _params({
    required String userId,
    required String featureKey,
    required String requestId,
    required DateTime at,
  }) {
    return {
      'p_user_id': userId,
      'p_request_id': requestId,
      'p_feature_key': featureKey,
      'p_reset_timezone': resetTimezone,
      'p_requested_at': at.toUtc().toIso8601String(),
    };
  }

  String _requireCurrentUserId() {
    final userId = rpcClient.currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      throw const UsageQuotaAuthRequiredException();
    }
    return userId;
  }
}
