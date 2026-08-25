import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';
import 'package:nano_app/services/health_orchestration/health_domain_event_sink.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../domain/repositories/lifestyle_schedule_repository.dart';

/// Emits cross-feature health events only after the authoritative schedule
/// repository has committed its write. Event delivery is best-effort so a
/// refresh/AI failure can never roll back a valid completion transaction.
final class HealthEventLifestyleScheduleRepository
    implements LifestyleScheduleRepository {
  final LifestyleScheduleRepository delegate;
  final HealthDomainEventSink eventSink;
  final Future<String?> Function() resolveSubjectId;

  const HealthEventLifestyleScheduleRepository({
    required this.delegate,
    required this.eventSink,
    required this.resolveSubjectId,
  });

  @override
  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({
    DateTime? anchorDate,
  }) {
    return delegate.getWeekSchedule(anchorDate: anchorDate);
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
    final updated = await delegate.updateItemCompletion(
      item: item,
      isCompleted: isCompleted,
      completionProofPath: completionProofPath,
      completionProofCapturedAt: completionProofCapturedAt,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
    await _publishCompletion(updated, completed: isCompleted);
    return updated;
  }

  @override
  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) async {
    final updated = await delegate.completeItemById(
      id,
      completionProofPath: completionProofPath,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
    await _publishCompletion(updated, completed: true);
    return updated;
  }

  @override
  Future<List<ScheduleCompletionProofEntity>> getCompletionProofs() {
    return delegate.getCompletionProofs();
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
    return delegate.updateCompletionProofRemoteState(
      proofId: proofId,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      cloudObjectPath: cloudObjectPath,
      uploadStatus: uploadStatus,
      rewardStatus: rewardStatus,
    );
  }

  Future<void> _publishCompletion(
    LifestyleScheduleItemEntity item, {
    required bool completed,
  }) async {
    try {
      final direct = item.userId?.trim();
      final fallback = direct == null || direct.isEmpty
          ? (await resolveSubjectId())?.trim()
          : direct;
      if (fallback == null || fallback.isEmpty) return;
      await eventSink.publish(
        HealthDomainEvent.create(
          type: completed
              ? HealthEventType.taskCompleted
              : HealthEventType.scheduleUpdated,
          subjectId: fallback,
          sourceFeature: 'lifestyle_schedule',
          entityId: item.id,
          changedFields: {
            'is_completed',
            if (completed) 'completion_proof',
          },
        ),
      );
    } catch (_) {
      // The local completion transaction already committed successfully.
    }
  }
}
