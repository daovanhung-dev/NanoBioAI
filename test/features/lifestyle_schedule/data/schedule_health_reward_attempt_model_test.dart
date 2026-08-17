import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/schedule_health_reward_attempt_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/daily_health_snapshot_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_health_action_type.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_health_reward_attempt_entity.dart';

void main() {
  test('reward attempt preserves typed self-report for durable retry', () {
    const entity = ScheduleHealthRewardAttemptEntity(
      id: 'attempt-1',
      userId: 'user-1',
      scheduleItemId: 'item-1',
      actionType: ScheduleHealthActionType.moodStress,
      input: DailyHealthCheckInInput(mood: 'good', stressLevel: 2),
      completionToken: '2026-08-17T10:10:00.000',
      syncStatus: ScheduleHealthRewardAttemptStatuses.pending,
      createdAt: '2026-08-17T10:10:00.000',
      updatedAt: '2026-08-17T10:10:00.000',
    );

    final restored = ScheduleHealthRewardAttemptModel.fromMap(
      ScheduleHealthRewardAttemptModel.fromEntity(entity).toMap(),
    ).toEntity();

    expect(restored.actionType, ScheduleHealthActionType.moodStress);
    expect(restored.input.mood, 'good');
    expect(restored.input.stressLevel, 2);
    expect(restored.finalizeIdempotencyKey, contains('item-1'));
    expect(restored.finalizeIdempotencyKey, contains(entity.completionToken));
  });
}
