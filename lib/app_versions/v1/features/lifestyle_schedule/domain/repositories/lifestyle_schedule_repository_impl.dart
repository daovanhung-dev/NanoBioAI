import '../../data/datasources/lifestyle_schedule_local_datasource.dart';
import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/lifestyle_schedule_summary_entity.dart';
import '../entities/schedule_completion_proof_entity.dart';
import 'lifestyle_schedule_repository.dart';

typedef LifestyleScheduleSubjectIdResolver = Future<String> Function();

class LifestyleScheduleRepositoryImpl implements LifestyleScheduleRepository {
  final LifestyleScheduleLocalDatasource datasource;
  final LifestyleScheduleSubjectIdResolver? resolveSubjectId;

  const LifestyleScheduleRepositoryImpl({
    required this.datasource,
    this.resolveSubjectId,
  });

  @override
  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({
    DateTime? anchorDate,
  }) async {
    return datasource.getWeekSchedule(
      userId: await _subjectIdOrNull(),
      anchorDate: anchorDate,
    );
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
  }) async {
    return datasource.updateItemCompletion(
      userId: await _subjectIdOrNull(),
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
  }) async {
    return datasource.completeItemById(
      id,
      userId: await _subjectIdOrNull(),
      completionProofPath: completionProofPath,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
  }

  @override
  Future<List<ScheduleCompletionProofEntity>> getCompletionProofs() async {
    return datasource.getCompletionProofs(
      userId: await _subjectIdOrNull(),
    );
  }

  @override
  Future<void> updateCompletionProofRemoteState({
    required String proofId,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? cloudObjectPath,
    String? uploadStatus,
    String? rewardStatus,
  }) async {
    return datasource.updateCompletionProofRemoteState(
      userId: await _subjectIdOrNull(),
      proofId: proofId,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      cloudObjectPath: cloudObjectPath,
      uploadStatus: uploadStatus,
      rewardStatus: rewardStatus,
    );
  }

  Future<String?> _subjectIdOrNull() async {
    final resolver = resolveSubjectId;
    return resolver == null ? null : resolver();
  }
}
