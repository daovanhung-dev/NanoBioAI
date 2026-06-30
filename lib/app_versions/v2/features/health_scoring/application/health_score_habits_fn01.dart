import 'package:nano_app/core/access/subject_access_context.dart';

import '../domain/entities/health_score_habits_models.dart';
import '../domain/repositories/health_score_habits_repository.dart';
import '../domain/services/health_score_habits_calculator.dart';

class HealthScoreHabitsFn01 {
  final HealthScoreHabitsRepository repository;

  const HealthScoreHabitsFn01({required this.repository});

  Future<HealthScoreHabitsResult> execute(
    CalculateHealthScoreCommand command,
  ) async {
    final actorId = command.actorId.trim();
    if (actorId.isEmpty) throw const HealthScoreHabitsException.authRequired();

    final subjectId = _resolveSubjectId(command);

    final now = command.now ?? DateTime.now();
    final period = command.period ?? HealthScorePeriod.lastDays(now: now);
    final inputs = await repository.loadInputs(
      userId: subjectId,
      period: period,
      now: now,
    );
    return HealthScoreHabitsCalculator.calculate(inputs);
  }

  String _resolveSubjectId(CalculateHealthScoreCommand command) {
    try {
      return SubjectAccessContext(
        actorId: command.actorId,
        requestedSubjectId: command.subjectId,
        isFamilyPlus: command.isFamilyPlus,
      ).resolveSubjectId();
    } on SubjectAccessException catch (error) {
      if (error.code == 'AUTH_REQUIRED') {
        throw const HealthScoreHabitsException.authRequired();
      }
      if (error.code == 'FAMILY_PLUS_REQUIRED') {
        throw const HealthScoreHabitsException.forbidden();
      }
      throw const HealthScoreHabitsException.invalidCommand();
    }
  }
}
