import '../entities/nutrition_profile_entity.dart';

abstract class NutritionProfileRepository {
  const NutritionProfileRepository();

  Future<NutritionProfileEntity> load(String userId);

  Future<void> save(NutritionProfileEntity profile);
}
