import '../entities/meal_plan_entity.dart';

abstract class MealPlanRepository {
  const MealPlanRepository();
  Future<List<MealPlanEntity>> getMealByWeeks();

  Future<void> completeMealById(String id);
}
