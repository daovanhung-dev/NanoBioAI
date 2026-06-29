import '../domain/entities/health_score_habits_models.dart';
import '../domain/repositories/health_score_habits_repository.dart';
import '../domain/services/health_score_habits_calculator.dart';

class HealthScoreHabitsFn02 {
  final HealthScoreHabitsRepository repository;

  const HealthScoreHabitsFn02({required this.repository});

  Future<HealthScoreHabitsResult> execute(
    LoadHabitProgressCommand command,
  ) async {
    final actorId = command.actorId.trim();
    if (actorId.isEmpty) throw const HealthScoreHabitsException.authRequired();

    final subjectId = (command.subjectId ?? actorId).trim();
    if (subjectId.isEmpty) {
      throw const HealthScoreHabitsException.invalidCommand();
    }
    if (subjectId != actorId) {
      throw const HealthScoreHabitsException.forbidden();
    }

    final now = command.now ?? DateTime.now();
    final period = command.period ?? HealthScorePeriod.lastDays(now: now);
    final inputs = await repository.loadInputs(
      userId: subjectId,
      period: period,
      now: now,
    );
    return HealthScoreHabitsCalculator.calculate(inputs);
  }
}
