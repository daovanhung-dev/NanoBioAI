import '../entities/meal_plan_entity.dart';
import '../entities/meal_replacement_entities.dart';

abstract class MealPlanRepository {
  const MealPlanRepository();

  Future<List<MealPlanEntity>> getMealByWeeks();

  Future<void> completeMealById(String id);

  Future<List<MealReplacementCandidateEntity>> getReplacementCandidates(
    String mealId,
  );

  Future<MealReplacementResult> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
  });

  @Deprecated('Use getReplacementCandidates + replaceMealByCatalogCode.')
  Future<MealPlanEntity> replaceMealById(String id);
}
