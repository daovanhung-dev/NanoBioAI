import '../entities/daily_health_snapshot_entity.dart';
import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/manual_health_task_draft.dart';
import '../entities/schedule_health_reward_attempt_entity.dart';

abstract class DailyHealthHubRepository {
  Future<DailyHealthSnapshotEntity> getSnapshot(DateTime date);

  Future<DailyHealthSnapshotEntity> recordStandaloneCheckIn({
    required DateTime date,
    required DailyHealthCheckInInput input,
  });

  Future<List<LifestyleScheduleItemEntity>> createManualTaskSeries(
    ManualHealthTaskDraft draft,
  );

  Future<List<LifestyleScheduleItemEntity>> replaceManualTaskSeries({
    required LifestyleScheduleItemEntity existingItem,
    required ManualHealthTaskDraft draft,
  });

  Future<void> deleteManualTaskSeries(
    LifestyleScheduleItemEntity item, {
    bool fromThisDateForward = true,
  });

  Future<LifestyleScheduleItemEntity> completeCheckInTask({
    required LifestyleScheduleItemEntity item,
    required DailyHealthCheckInInput input,
    required bool queueReward,
  });

  Future<LifestyleScheduleItemEntity> undoCheckInTask(
    LifestyleScheduleItemEntity item, {
    bool rewardUndoPending = false,
  });

  Future<LifestyleScheduleItemEntity?> getScheduleItem(String id);

  Future<ScheduleHealthRewardAttemptEntity?> latestRewardAttempt(
    String scheduleItemId,
  );

  Future<List<ScheduleHealthRewardAttemptEntity>> pendingRewardAttempts({
    int limit = 20,
  });

  Future<void> updateRewardAttempt({
    required String id,
    required String syncStatus,
    String? rewardStatus,
    int? pointsDelta,
    String? lastErrorCode,
  });
}
