import '../../domain/entities/nutrition_profile_entity.dart';
import '../../domain/repositories/nutrition_profile_repository.dart';
import '../datasources/nutrition_profile_local_datasource.dart';

class NutritionProfileRepositoryImpl implements NutritionProfileRepository {
  const NutritionProfileRepositoryImpl({required this.localDatasource});

  final NutritionProfileLocalDatasource localDatasource;

  @override
  Future<NutritionProfileEntity> load(String userId) {
    return localDatasource.load(userId);
  }

  @override
  Future<void> save(NutritionProfileEntity profile) {
    return localDatasource.save(profile);
  }
}
