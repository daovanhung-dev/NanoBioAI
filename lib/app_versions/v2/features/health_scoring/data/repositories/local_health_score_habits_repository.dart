import '../../domain/entities/health_score_habits_models.dart';
import '../../domain/repositories/health_score_habits_repository.dart';
import '../datasources/sqlite_health_score_habits_local_datasource.dart';

class LocalHealthScoreHabitsRepository implements HealthScoreHabitsRepository {
  final SqliteHealthScoreHabitsLocalDatasource datasource;

  const LocalHealthScoreHabitsRepository({required this.datasource});

  @override
  Future<HealthScoreInputSnapshot> loadInputs({
    required String userId,
    required HealthScorePeriod period,
    required DateTime now,
  }) {
    return datasource.loadInputs(userId: userId, period: period, now: now);
  }
}
