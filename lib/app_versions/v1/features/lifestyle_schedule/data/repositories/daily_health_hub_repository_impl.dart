import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/manual_health_task_draft.dart';
import '../../domain/entities/schedule_health_reward_attempt_entity.dart';
import '../../domain/repositories/daily_health_hub_repository.dart';
import '../datasources/daily_health_hub_local_datasource.dart';

class DailyHealthHubRepositoryImpl implements DailyHealthHubRepository {
  final DailyHealthHubLocalDatasource datasource;

  const DailyHealthHubRepositoryImpl({required this.datasource});

  @override
  Future<DailyHealthSnapshotEntity> getSnapshot(DateTime date) {
    return datasource.getSnapshot(date);
  }

  @override
  Future<DailyHealthSnapshotEntity> recordStandaloneCheckIn({
    required DateTime date,
    required DailyHealthCheckInInput input,
  }) {
    return datasource.recordStandaloneCheckIn(date: date, input: input);
  }

  @override
  Future<List<LifestyleScheduleItemEntity>> createManualTaskSeries(
    ManualHealthTaskDraft draft,
  ) {
    return datasource.createManualTaskSeries(draft);
  }

  @override
  Future<List<LifestyleScheduleItemEntity>> replaceManualTaskSeries({
    required LifestyleScheduleItemEntity existingItem,
    required ManualHealthTaskDraft draft,
  }) {
    return datasource.replaceManualTaskSeries(
      existingItem: existingItem,
      draft: draft,
    );
  }

  @override
  Future<void> deleteManualTaskSeries(
    LifestyleScheduleItemEntity item, {
    bool fromThisDateForward = true,
  }) {
    return datasource.deleteManualTaskSeries(
      item,
      fromThisDateForward: fromThisDateForward,
    );
  }

  @override
  Future<LifestyleScheduleItemEntity> completeCheckInTask({
    required LifestyleScheduleItemEntity item,
    required DailyHealthCheckInInput input,
    required bool queueReward,
  }) {
    return datasource.completeCheckInTask(
      item: item,
      input: input,
      queueReward: queueReward,
    );
  }

  @override
  Future<LifestyleScheduleItemEntity> undoCheckInTask(
    LifestyleScheduleItemEntity item, {
    bool rewardUndoPending = false,
  }) {
    return datasource.undoCheckInTask(
      item,
      rewardUndoPending: rewardUndoPending,
    );
  }

  @override
  Future<LifestyleScheduleItemEntity?> getScheduleItem(String id) {
    return datasource.getScheduleItem(id);
  }

  @override
  Future<ScheduleHealthRewardAttemptEntity?> latestRewardAttempt(
    String scheduleItemId,
  ) {
    return datasource.latestRewardAttempt(scheduleItemId);
  }

  @override
  Future<List<ScheduleHealthRewardAttemptEntity>> pendingRewardAttempts({
    int limit = 20,
  }) {
    return datasource.pendingRewardAttempts(limit: limit);
  }

  @override
  Future<void> updateRewardAttempt({
    required String id,
    required String syncStatus,
    String? rewardStatus,
    int? pointsDelta,
    String? lastErrorCode,
  }) {
    return datasource.updateRewardAttempt(
      id: id,
      syncStatus: syncStatus,
      rewardStatus: rewardStatus,
      pointsDelta: pointsDelta,
      lastErrorCode: lastErrorCode,
    );
  }
}
