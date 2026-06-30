import '../domain/entities/advanced_tracking_models.dart';
import '../domain/repositories/advanced_tracking_repository.dart';

class AdvancedTrackingGoalsFn01 {
  final AdvancedTrackingRepository repository;

  const AdvancedTrackingGoalsFn01({required this.repository});

  Future<AdvancedTrackingGoal> execute(
    CreateAdvancedGoalCommand command,
  ) async {
    final now = command.now ?? DateTime.now();
    final subjectUserId = command.actor.resolveSubjectId(command.subjectUserId);

    final existing = await repository.loadActiveGoal(
      subjectUserId: subjectUserId,
      goalCode: advancedTrackingHydrationGoalCode,
    );
    if (existing != null) return existing;

    return repository.createHydrationGoal(
      subjectUserId: subjectUserId,
      now: now,
    );
  }
}
