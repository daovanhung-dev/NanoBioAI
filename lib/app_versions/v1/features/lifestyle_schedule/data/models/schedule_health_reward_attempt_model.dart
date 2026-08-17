import 'dart:convert';

import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../domain/entities/schedule_health_reward_attempt_entity.dart';

class ScheduleHealthRewardAttemptModel {
  final String id;
  final String userId;
  final String scheduleItemId;
  final String actionType;
  final String payload;
  final String completionToken;
  final String syncStatus;
  final String? rewardStatus;
  final int pointsDelta;
  final String? lastErrorCode;
  final String createdAt;
  final String updatedAt;

  const ScheduleHealthRewardAttemptModel({
    required this.id,
    required this.userId,
    required this.scheduleItemId,
    required this.actionType,
    required this.payload,
    required this.completionToken,
    required this.syncStatus,
    this.rewardStatus,
    this.pointsDelta = 0,
    this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleHealthRewardAttemptModel.fromMap(Map<String, Object?> map) {
    return ScheduleHealthRewardAttemptModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      scheduleItemId: map['schedule_item_id']?.toString() ?? '',
      actionType: map['action_type']?.toString() ?? '',
      payload: map['payload']?.toString() ?? '{}',
      completionToken: map['completion_token']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ??
          ScheduleHealthRewardAttemptStatuses.pending,
      rewardStatus: map['reward_status']?.toString(),
      pointsDelta: _readInt(map['points_delta']),
      lastErrorCode: map['last_error_code']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
    );
  }

  factory ScheduleHealthRewardAttemptModel.fromEntity(
    ScheduleHealthRewardAttemptEntity entity,
  ) {
    return ScheduleHealthRewardAttemptModel(
      id: entity.id,
      userId: entity.userId,
      scheduleItemId: entity.scheduleItemId,
      actionType: entity.actionType.stableCode,
      payload: jsonEncode(entity.input.toRewardPayload()),
      completionToken: entity.completionToken,
      syncStatus: entity.syncStatus,
      rewardStatus: entity.rewardStatus,
      pointsDelta: entity.pointsDelta,
      lastErrorCode: entity.lastErrorCode,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'schedule_item_id': scheduleItemId,
        'action_type': actionType,
        'payload': payload,
        'completion_token': completionToken,
        'sync_status': syncStatus,
        'reward_status': rewardStatus,
        'points_delta': pointsDelta,
        'last_error_code': lastErrorCode,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  ScheduleHealthRewardAttemptEntity toEntity() {
    final action = ScheduleHealthActionTypeX.fromStableCode(actionType) ??
        ScheduleHealthActionType.quickComplete;
    return ScheduleHealthRewardAttemptEntity(
      id: id,
      userId: userId,
      scheduleItemId: scheduleItemId,
      actionType: action,
      input: _input(payload),
      completionToken: completionToken,
      syncStatus: syncStatus,
      rewardStatus: rewardStatus,
      pointsDelta: pointsDelta,
      lastErrorCode: lastErrorCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DailyHealthCheckInInput _input(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return const DailyHealthCheckInInput();
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      return DailyHealthCheckInInput(
        waterDeltaMl: _readInt(map['amount_ml']),
        sleepHours: _readDoubleOrNull(map['sleep_hours']),
        stressLevel: _readIntOrNull(map['stress_level']),
        mood: map['mood']?.toString(),
        weightKg: _readDoubleOrNull(map['weight_kg']),
      );
    } catch (_) {
      return const DailyHealthCheckInInput();
    }
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _readDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
