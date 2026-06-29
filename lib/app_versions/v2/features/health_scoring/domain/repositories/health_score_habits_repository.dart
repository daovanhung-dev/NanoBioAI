import '../entities/health_score_habits_models.dart';

abstract class HealthScoreHabitsRepository {
  Future<HealthScoreInputSnapshot> loadInputs({
    required String userId,
    required HealthScorePeriod period,
    required DateTime now,
  });
}
