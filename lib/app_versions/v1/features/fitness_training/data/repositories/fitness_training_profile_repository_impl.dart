import '../../domain/entities/fitness_training_profile.dart';
import '../../domain/repositories/fitness_training_profile_repository.dart';
import '../datasources/fitness_training_profile_local_datasource.dart';

class FitnessTrainingProfileRepositoryImpl
    implements FitnessTrainingProfileRepository {
  const FitnessTrainingProfileRepositoryImpl({required this.datasource});

  final FitnessTrainingProfileLocalDatasource datasource;

  @override
  Future<FitnessTrainingProfileSnapshot> load(String? authenticatedUserId) =>
      datasource.load(authenticatedUserId);

  @override
  Future<void> saveBirthDate({
    required String userId,
    required DateTime birthDate,
  }) => datasource.saveBirthDate(userId: userId, birthDate: birthDate);
}
