import '../../data/datasources/lifestyle_schedule_local_datasource.dart';
import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/lifestyle_schedule_summary_entity.dart';
import '../entities/schedule_completion_proof_entity.dart';
import 'lifestyle_schedule_repository.dart';

class LifestyleScheduleRepositoryImpl implements LifestyleScheduleRepository {
  final LifestyleScheduleLocalDatasource datasource;

  const LifestyleScheduleRepositoryImpl({required this.datasource});

  @override
  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({
    DateTime? anchorDate,
  }) {
    return datasource.getWeekSchedule(anchorDate: anchorDate);
  }

  @override
  Future<LifestyleScheduleItemEntity> updateItemCompletion({
    required LifestyleScheduleItemEntity item,
    required bool isCompleted,
    String? completionProofPath,
    String? completionProofCapturedAt,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) {
    return datasource.updateItemCompletion(
      item: item,
      isCompleted: isCompleted,
      completionProofPath: completionProofPath,
      completionProofCapturedAt: completionProofCapturedAt,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
  }

  @override
  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) {
    return datasource.completeItemById(
      id,
      completionProofPath: completionProofPath,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
  }

  @override
  Future<List<ScheduleCompletionProofEntity>> getCompletionProofs() {
    return datasource.getCompletionProofs();
  }

  @override
  Future<void> updateCompletionProofRemoteState({
    required String proofId,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? cloudObjectPath,
    String? uploadStatus,
    String? rewardStatus,
  }) {
    return datasource.updateCompletionProofRemoteState(
      proofId: proofId,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      cloudObjectPath: cloudObjectPath,
      uploadStatus: uploadStatus,
      rewardStatus: rewardStatus,
    );
  }
}
