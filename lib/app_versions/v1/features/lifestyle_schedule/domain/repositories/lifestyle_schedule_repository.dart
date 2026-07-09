import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/lifestyle_schedule_summary_entity.dart';

abstract class LifestyleScheduleRepository {
  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({
    DateTime? anchorDate,
  });

  Future<LifestyleScheduleItemEntity> updateItemCompletion({
    required LifestyleScheduleItemEntity item,
    required bool isCompleted,
    String? completionProofPath,
    String? completionProofCapturedAt,
  });

  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
  });
}
