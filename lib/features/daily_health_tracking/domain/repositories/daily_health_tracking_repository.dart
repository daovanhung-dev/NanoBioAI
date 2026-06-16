import '../entities/daily_health_summary_entity.dart';
import '../entities/daily_health_task_entity.dart';

abstract class DailyHealthTrackingRepository {
  Future<DailyHealthSummaryEntity> getTodaySummary();

  Future<DailyHealthSummaryEntity> refreshToday();

  Future<DailyHealthTaskEntity> updateTask(DailyHealthTaskEntity task);

  Future<DailyHealthTaskEntity> toggleTask(DailyHealthTaskEntity task);

  Future<DailyHealthTaskEntity> addProgress({
    required DailyHealthTaskEntity task,
    required double amount,
  });
}
