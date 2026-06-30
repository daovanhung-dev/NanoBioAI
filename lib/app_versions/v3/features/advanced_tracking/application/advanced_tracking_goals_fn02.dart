import '../domain/entities/advanced_tracking_models.dart';
import '../domain/repositories/advanced_tracking_repository.dart';

class AdvancedTrackingGoalsFn02 {
  final AdvancedTrackingRepository repository;

  const AdvancedTrackingGoalsFn02({required this.repository});

  Future<AdvancedTrackingRoadmapResult> execute(
    LoadGoalRoadmapCommand command,
  ) async {
    final now = command.now ?? DateTime.now();
    final period = command.period ?? AdvancedTrackingPeriod.lastDays(now: now);
    final subjectUserId = command.actor.resolveSubjectId(command.subjectUserId);

    final goal = await repository.loadActiveGoal(
      subjectUserId: subjectUserId,
      goalCode: advancedTrackingHydrationGoalCode,
    );
    final logs = await repository.loadHydrationLogs(
      subjectUserId: subjectUserId,
      period: period,
    );
    final logsByDate = {for (final log in logs) log.date: log};
    final steps = period.dateKeys
        .map((date) {
          final log = logsByDate[date];
          return AdvancedTrackingRoadmapStep(
            date: date,
            waterMl: log?.waterMl ?? 0,
          );
        })
        .toList(growable: false);

    return AdvancedTrackingRoadmapResult(
      subjectUserId: subjectUserId,
      goal: goal,
      period: period,
      steps: steps,
    );
  }
}
