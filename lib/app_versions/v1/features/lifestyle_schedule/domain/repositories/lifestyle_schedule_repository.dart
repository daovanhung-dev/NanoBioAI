import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/lifestyle_schedule_summary_entity.dart';
import '../entities/schedule_completion_proof_entity.dart';

abstract class LifestyleScheduleRepository {
  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({
    DateTime? anchorDate,
  });

  Future<LifestyleScheduleItemEntity> updateItemCompletion({
    required LifestyleScheduleItemEntity item,
    required bool isCompleted,
    String? completionProofPath,
    String? completionProofCapturedAt,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  });

  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  });

  Future<List<ScheduleCompletionProofEntity>> getCompletionProofs();

  Future<void> updateCompletionProofRemoteState({
    required String proofId,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? cloudObjectPath,
    String? uploadStatus,
    String? rewardStatus,
  });
}
