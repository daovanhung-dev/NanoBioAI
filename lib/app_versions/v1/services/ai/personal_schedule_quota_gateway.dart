import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nano_app/core/utils/logger/app_logger.dart';

class PersonalScheduleQuotaDecision {
  final bool allowed;
  final DateTime? resetAt;
  final String? reasonCode;

  const PersonalScheduleQuotaDecision._({
    required this.allowed,
    this.resetAt,
    this.reasonCode,
  });

  const PersonalScheduleQuotaDecision.allowed() : this._(allowed: true);

  const PersonalScheduleQuotaDecision.denied({
    DateTime? resetAt,
    String? reasonCode,
  }) : this._(allowed: false, resetAt: resetAt, reasonCode: reasonCode);
}

class PersonalScheduleQuotaExceededException implements Exception {
  static const userMessage =
      'Bạn đã hết lượt tạo lịch tháng này. Hãy chờ kỳ mới hoặc nâng gói.';

  final DateTime? resetAt;

  const PersonalScheduleQuotaExceededException({this.resetAt});

  @override
  String toString() => userMessage;
}

class PersonalScheduleQuotaUnavailableException implements Exception {
  static const userMessage =
      'Nabi chưa kiểm tra được lượt tạo lịch lúc này. Bạn thử lại sau một chút nhé.';

  const PersonalScheduleQuotaUnavailableException();

  @override
  String toString() => userMessage;
}

abstract class PersonalScheduleQuotaGateway {
  Future<PersonalScheduleQuotaDecision> checkGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  });

  Future<void> commitGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  });
}

class TrustedBackendPersonalScheduleQuotaGateway
    implements PersonalScheduleQuotaGateway {
  static const featureKey = 'personal_schedule_generation';
  static const resetTimezone = 'Asia/Ho_Chi_Minh';
  static const _tag = 'SCHEDULE_QUOTA';
  static const _checkRpc = 'check_personal_schedule_generation_quota';
  static const _commitRpc = 'commit_personal_schedule_generation_quota';

  final SupabaseClient? clientOverride;

  const TrustedBackendPersonalScheduleQuotaGateway({this.clientOverride});

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  @override
  Future<PersonalScheduleQuotaDecision> checkGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PersonalScheduleQuotaUnavailableException();
    }

    try {
      _logRpc(rpcName: _checkRpc, stage: 'REQUEST', status: 'started');
      final response = await client.rpc(
        _checkRpc,
        params: {
          'p_user_id': userId,
          'p_request_id': requestId,
          'p_feature_key': featureKey,
          'p_reset_timezone': resetTimezone,
          'p_requested_at': at.toUtc().toIso8601String(),
        },
      );
      final decision = _decisionFromResponse(response);
      if (!decision.allowed) {
        _logRpc(rpcName: _checkRpc, stage: 'RESPONSE', status: 'denied');
        throw PersonalScheduleQuotaExceededException(resetAt: decision.resetAt);
      }
      _logRpc(rpcName: _checkRpc, stage: 'RESPONSE', status: 'allowed');
      return decision;
    } on PersonalScheduleQuotaExceededException catch (error) {
      _logRpc(
        rpcName: _checkRpc,
        stage: 'FAILURE',
        status: 'typed_error',
        error: error,
      );
      rethrow;
    } catch (error) {
      _logRpc(
        rpcName: _checkRpc,
        stage: 'FAILURE',
        status: 'unavailable',
        error: error,
      );
      throw const PersonalScheduleQuotaUnavailableException();
    }
  }

  @override
  Future<void> commitGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PersonalScheduleQuotaUnavailableException();
    }

    try {
      _logRpc(rpcName: _commitRpc, stage: 'REQUEST', status: 'started');
      final response = await client.rpc(
        _commitRpc,
        params: {
          'p_user_id': userId,
          'p_request_id': requestId,
          'p_feature_key': featureKey,
          'p_reset_timezone': resetTimezone,
          'p_committed_at': at.toUtc().toIso8601String(),
        },
      );
      final decision = _decisionFromResponse(response);
      if (!decision.allowed) {
        _logRpc(rpcName: _commitRpc, stage: 'RESPONSE', status: 'denied');
        throw PersonalScheduleQuotaExceededException(resetAt: decision.resetAt);
      }
      _logRpc(rpcName: _commitRpc, stage: 'RESPONSE', status: 'committed');
    } on PersonalScheduleQuotaExceededException catch (error) {
      _logRpc(
        rpcName: _commitRpc,
        stage: 'FAILURE',
        status: 'typed_error',
        error: error,
      );
      rethrow;
    } catch (error) {
      _logRpc(
        rpcName: _commitRpc,
        stage: 'FAILURE',
        status: 'unavailable',
        error: error,
      );
      throw const PersonalScheduleQuotaUnavailableException();
    }
  }

  void _logRpc({
    required String rpcName,
    required String stage,
    required String status,
    Object? error,
  }) {
    final errorType = error == null ? '' : ' errorType=${error.runtimeType}';
    AppLogger.info(_tag, 'rpc=$rpcName stage=$stage status=$status$errorType');
  }

  PersonalScheduleQuotaDecision _decisionFromResponse(Object? response) {
    final row = _firstMap(response);
    if (row == null) {
      if (response is bool) {
        return response
            ? const PersonalScheduleQuotaDecision.allowed()
            : const PersonalScheduleQuotaDecision.denied();
      }
      throw const PersonalScheduleQuotaUnavailableException();
    }

    final allowed = _readBool(row['allowed'] ?? row['committed']);
    if (allowed) return const PersonalScheduleQuotaDecision.allowed();
    return PersonalScheduleQuotaDecision.denied(
      resetAt: DateTime.tryParse(row['reset_at']?.toString() ?? ''),
      reasonCode: row['reason_code']?.toString(),
    );
  }

  Map<String, Object?>? _firstMap(Object? response) {
    if (response is Map) return Map<String, Object?>.from(response);
    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, Object?>.from(response.first as Map);
    }
    return null;
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }
}
