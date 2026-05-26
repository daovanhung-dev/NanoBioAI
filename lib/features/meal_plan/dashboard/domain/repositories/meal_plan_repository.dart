import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

abstract class MealPlanRepository {
  const MealPlanRepository();
  Future<List<MealPlanModel>> getMealByWeeks();
}