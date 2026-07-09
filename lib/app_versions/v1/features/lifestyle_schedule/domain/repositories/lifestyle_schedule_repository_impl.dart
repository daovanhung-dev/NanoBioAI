import '../../data/datasources/lifestyle_schedule_local_datasource.dart';
import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/lifestyle_schedule_summary_entity.dart';
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
  }) {
    return datasource.updateItemCompletion(
      item: item,
      isCompleted: isCompleted,
      completionProofPath: completionProofPath,
      completionProofCapturedAt: completionProofCapturedAt,
    );
  }

  @override
  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
  }) {
    return datasource.completeItemById(
      id,
      completionProofPath: completionProofPath,
    );
  }
}
