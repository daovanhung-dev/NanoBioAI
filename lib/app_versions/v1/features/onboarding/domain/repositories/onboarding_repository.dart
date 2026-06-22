import '../entities/onboarding_entity.dart';

abstract class OnboardingRepository {
  Future<void> save(OnboardingEntity entity);

  Future<void> markCompleted();
}
