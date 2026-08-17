import 'daily_health_snapshot_entity.dart';
import 'schedule_health_action_type.dart';

class ScheduleHealthRewardAttemptStatuses {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const notEligible = 'not_eligible';
  static const undoPending = 'undo_pending';
  static const reversed = 'reversed';
}

class ScheduleHealthRewardAttemptEntity {
  final String id;
  final String userId;
  final String scheduleItemId;
  final ScheduleHealthActionType actionType;
  final DailyHealthCheckInInput input;
  final String completionToken;
  final String syncStatus;
  final String? rewardStatus;
  final int pointsDelta;
  final String? lastErrorCode;
  final String createdAt;
  final String updatedAt;

  const ScheduleHealthRewardAttemptEntity({
    required this.id,
    required this.userId,
    required this.scheduleItemId,
    required this.actionType,
    required this.input,
    required this.completionToken,
    required this.syncStatus,
    this.rewardStatus,
    this.pointsDelta = 0,
    this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => syncStatus == ScheduleHealthRewardAttemptStatuses.pending;
  bool get isConfirmed =>
      syncStatus == ScheduleHealthRewardAttemptStatuses.confirmed;

  String get finalizeIdempotencyKey =>
      'health-checkin:$scheduleItemId:$completionToken';

  String get undoIdempotencyKey =>
      'health-checkin-undo:$scheduleItemId:$completionToken';
}
