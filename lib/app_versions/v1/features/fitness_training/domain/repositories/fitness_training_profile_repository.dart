import '../entities/fitness_training_profile.dart';

abstract interface class FitnessTrainingProfileRepository {
  Future<FitnessTrainingProfileSnapshot> load(String? authenticatedUserId);

  Future<void> saveBirthDate({
    required String userId,
    required DateTime birthDate,
  });
}
