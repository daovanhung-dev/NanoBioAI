import 'package:nano_app/core/network/backend_api_client.dart';

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

class BackendScheduleHealthCheckInRewardGateway
    implements ScheduleHealthCheckInRewardGateway {
  final BackendApiClient? clientOverride;

  const BackendScheduleHealthCheckInRewardGateway({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  bool get hasAuthenticatedUser =>
      _client.currentUserId?.trim().isNotEmpty == true;

  @override
  Future<ScheduleHealthCheckInRewardResult> finalizeCheckIn({
    required LifestyleScheduleItemEntity item,
    required ScheduleHealthActionType actionType,
    required DailyHealthCheckInInput input,
    required String idempotencyKey,
  }) async {
    try {
      final row = await _client.requestMap(
        'POST',
        '/api/v1/schedule-rewards/health-checkins',
        body: {
          'item': _itemPayload(item),
          'action_type': actionType.stableCode,
          'checkin': input.toRewardPayload(),
          'idempotency_key': idempotencyKey,
        },
      );
      return _result(row);
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } on ScheduleRewardException {
      rethrow;
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  @override
  Future<ScheduleHealthCheckInRewardResult> undoCheckIn({
    required String scheduleItemId,
    required String idempotencyKey,
  }) async {
    try {
      final row = await _client.requestMap(
        'POST',
        '/api/v1/schedule-rewards/health-checkins/undo',
        body: {
          'schedule_item_id': scheduleItemId,
          'idempotency_key': idempotencyKey,
        },
      );
      return _result(row);
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } on ScheduleRewardException {
      rethrow;
    } catch (_) {
      throw ScheduleRewardException.network();
    }
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

  ScheduleHealthCheckInRewardResult _result(Map<String, Object?> row) {
    final errorCode = _readString(row['error_code']);
    if (errorCode.isNotEmpty || row['success'] == false) {
      throw ScheduleRewardException.fromStableCode(errorCode);
    }
    return ScheduleHealthCheckInRewardResult(
      rewardStatus: _readString(row['reward_status'], fallback: 'pending'),
      pointsDelta: _readInt(row['points_delta']),
    );
  }

  ScheduleRewardException _safeError(BackendApiException error) {
    final code = error.businessCode.toLowerCase();
    if (code.contains('eligibility_not_found')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.networkUnavailable,
        'Điểm chăm sóc đang chờ xác nhận. Nabi sẽ tự thử lại khi dữ liệu lịch được đồng bộ.',
        canContinueWithoutReward: true,
      );
    }
    if (code.contains('manual_reward_daily_limit')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.eligibilityUnavailable,
        'Bạn vẫn hoàn thành nhiệm vụ, nhưng hôm nay đã đạt giới hạn Điểm chăm sóc cho nhiệm vụ tự tạo.',
        canContinueWithoutReward: true,
      );
    }
    final mapped = ScheduleRewardException.fromStableCode(code);
    return mapped.code == ScheduleRewardErrorCode.unknown
        ? ScheduleRewardException.network()
        : mapped;
  }
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
