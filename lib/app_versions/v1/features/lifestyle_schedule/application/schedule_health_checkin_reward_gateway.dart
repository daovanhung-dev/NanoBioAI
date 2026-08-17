import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/daily_health_snapshot_entity.dart';
import '../domain/entities/lifestyle_schedule_item_entity.dart';
import '../domain/entities/schedule_health_action_type.dart';
import 'schedule_reward_online_gateway.dart';

class ScheduleHealthCheckInRewardResult {
  final String rewardStatus;
  final int pointsDelta;

  const ScheduleHealthCheckInRewardResult({
    required this.rewardStatus,
    required this.pointsDelta,
  });
}

abstract class ScheduleHealthCheckInRewardGateway {
  bool get hasAuthenticatedUser;

  Future<ScheduleHealthCheckInRewardResult> finalizeCheckIn({
    required LifestyleScheduleItemEntity item,
    required ScheduleHealthActionType actionType,
    required DailyHealthCheckInInput input,
    required String idempotencyKey,
  });

  Future<ScheduleHealthCheckInRewardResult> undoCheckIn({
    required String scheduleItemId,
    required String idempotencyKey,
  });
}

class SupabaseScheduleHealthCheckInRewardGateway
    implements ScheduleHealthCheckInRewardGateway {
  final SupabaseClient? clientOverride;

  const SupabaseScheduleHealthCheckInRewardGateway({this.clientOverride});

  SupabaseClient? get _clientOrNull {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get hasAuthenticatedUser =>
      _clientOrNull?.auth.currentUser?.id.trim().isNotEmpty == true;

  @override
  Future<ScheduleHealthCheckInRewardResult> finalizeCheckIn({
    required LifestyleScheduleItemEntity item,
    required ScheduleHealthActionType actionType,
    required DailyHealthCheckInInput input,
    required String idempotencyKey,
  }) async {
    final response = await _rpc(
      'finalize_my_schedule_health_checkin',
      params: {
        'p_item': _itemPayload(item),
        'p_action_type': actionType.stableCode,
        'p_checkin': input.toRewardPayload(),
        'p_idempotency_key': idempotencyKey,
      },
    );
    return _result(response);
  }

  @override
  Future<ScheduleHealthCheckInRewardResult> undoCheckIn({
    required String scheduleItemId,
    required String idempotencyKey,
  }) async {
    final response = await _rpc(
      'undo_my_schedule_health_checkin',
      params: {
        'p_schedule_item_id': scheduleItemId,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return _result(response);
  }

  Map<String, Object?> _itemPayload(LifestyleScheduleItemEntity item) => {
        'schedule_item_id': item.id,
        'schedule_date': item.scheduleDate,
        'start_time': item.startTime,
        'end_time': item.endTime,
        'title': item.title,
        'description': item.description,
        'category': item.category,
        'source_type': item.sourceType,
        'source_id': item.sourceId,
        'target_value': item.targetValue,
        'unit': item.unit,
        'ai_generated': item.aiGenerated,
      };

  ScheduleHealthCheckInRewardResult _result(Object? response) {
    final row = _firstMap(response);
    final errorCode = _readString(row['error_code']);
    if (errorCode.isNotEmpty || row['success'] == false) {
      throw ScheduleRewardException.fromStableCode(errorCode);
    }
    return ScheduleHealthCheckInRewardResult(
      rewardStatus: _readString(row['reward_status'], fallback: 'pending'),
      pointsDelta: _readInt(row['points_delta']),
    );
  }

  Future<Object?> _rpc(
    String functionName, {
    required Map<String, Object?> params,
  }) async {
    try {
      return await _requireClient().rpc(functionName, params: params);
    } on PostgrestException catch (error) {
      throw _safeError(error);
    } on AuthException {
      throw ScheduleRewardException.fromStableCode('auth_required');
    } on ScheduleRewardException {
      rethrow;
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  SupabaseClient _requireClient() {
    final client = _clientOrNull;
    if (client == null || client.auth.currentUser == null) {
      throw ScheduleRewardException.fromStableCode('auth_required');
    }
    return client;
  }

  ScheduleRewardException _safeError(PostgrestException error) {
    final stableText = [
      error.message,
      error.code ?? '',
      error.details?.toString() ?? '',
      error.hint?.toString() ?? '',
    ].join(' ').toLowerCase();
    if (stableText.contains('eligibility_not_found')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.networkUnavailable,
        'Điểm chăm sóc đang chờ xác nhận. Nabi sẽ tự thử lại khi dữ liệu lịch được đồng bộ.',
        canContinueWithoutReward: true,
      );
    }
    if (stableText.contains('manual_reward_daily_limit')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.eligibilityUnavailable,
        'Bạn vẫn hoàn thành nhiệm vụ, nhưng hôm nay đã đạt giới hạn Điểm chăm sóc cho nhiệm vụ tự tạo.',
        canContinueWithoutReward: true,
      );
    }
    if (stableText.contains('health_action_not_rewardable') ||
        stableText.contains('health_action_mismatch') ||
        stableText.contains('manual_health_task_invalid') ||
        stableText.contains('health_checkin_invalid') ||
        stableText.contains('photo_proof_required') ||
        stableText.contains('health_checkin_not_found') ||
        stableText.contains('eligibility_reward_already_awarded') ||
        stableText.contains('idempotency_conflict')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.eligibilityUnavailable,
        'Nhiệm vụ đã được lưu nhưng lần ghi nhận này chưa đủ điều kiện nhận Điểm chăm sóc.',
        canContinueWithoutReward: true,
      );
    }
    final candidates = <String>[
      error.message,
      error.code ?? '',
      error.details?.toString() ?? '',
      error.hint?.toString() ?? '',
    ];
    for (final candidate in candidates) {
      final mapped = ScheduleRewardException.fromStableCode(candidate);
      if (mapped.code != ScheduleRewardErrorCode.unknown) return mapped;
    }
    return ScheduleRewardException.network();
  }
}

Map<String, Object?> _firstMap(Object? response) {
  if (response is Map) {
    return response.map((key, value) => MapEntry(key.toString(), value));
  }
  if (response is List && response.isNotEmpty && response.first is Map) {
    final source = response.first as Map;
    return source.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _readString(Object? value, {String fallback = ''}) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
