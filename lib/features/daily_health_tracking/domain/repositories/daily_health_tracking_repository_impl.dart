import '../../data/datasources/daily_health_tracking_local_datasource.dart';
import '../entities/daily_health_summary_entity.dart';
import '../entities/daily_health_task_entity.dart';
import 'daily_health_tracking_repository.dart';

class DailyHealthTrackingRepositoryImpl
    implements DailyHealthTrackingRepository {
  final DailyHealthTrackingLocalDatasource datasource;

  const DailyHealthTrackingRepositoryImpl({required this.datasource});

  @override
  Future<DailyHealthSummaryEntity> getTodaySummary() {
    return datasource.getTodaySummary();
  }

  @override
  Future<DailyHealthSummaryEntity> refreshToday() {
    return datasource.getTodaySummary(forceReload: true);
  }

  @override
  Future<DailyHealthTaskEntity> updateTask(DailyHealthTaskEntity task) {
    return datasource.updateTask(task);
  }

  @override
  Future<DailyHealthTaskEntity> toggleTask(DailyHealthTaskEntity task) {
    final currentValue = task.isCompleted ? 0.0 : task.targetValue;
    return datasource.updateTask(
      task.copyWith(currentValue: currentValue, isCompleted: !task.isCompleted),
    );
  }

  @override
  Future<DailyHealthTaskEntity> addProgress({
    required DailyHealthTaskEntity task,
    required double amount,
  }) {
    final nextValue = (task.currentValue + amount).clamp(0, task.targetValue);
    return datasource.updateTask(
      task.copyWith(
        currentValue: nextValue.toDouble(),
        isCompleted: nextValue >= task.targetValue,
      ),
    );
  }
}
