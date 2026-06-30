import '../../domain/entities/advanced_tracking_models.dart';
import '../../domain/repositories/advanced_tracking_repository.dart';
import '../datasources/sqlite_advanced_tracking_local_datasource.dart';

class LocalAdvancedTrackingRepository implements AdvancedTrackingRepository {
  final SqliteAdvancedTrackingLocalDatasource datasource;

  const LocalAdvancedTrackingRepository({required this.datasource});

  @override
  Future<AdvancedTrackingGoal?> loadActiveGoal({
    required String subjectUserId,
    required String goalCode,
  }) {
    return datasource.loadActiveGoal(
      subjectUserId: subjectUserId,
      goalCode: goalCode,
    );
  }

  @override
  Future<AdvancedTrackingGoal> createHydrationGoal({
    required String subjectUserId,
    required DateTime now,
  }) {
    return datasource.createHydrationGoal(
      subjectUserId: subjectUserId,
      now: now,
    );
  }

  @override
  Future<List<AdvancedTrackingHydrationLog>> loadHydrationLogs({
    required String subjectUserId,
    required AdvancedTrackingPeriod period,
  }) {
    return datasource.loadHydrationLogs(
      subjectUserId: subjectUserId,
      period: period,
    );
  }
}
