// lib/features/dashboard/domain/repositories/dashboard_repository.dart
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

import '../entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> fetchDashboard();
  Future<void> saveMealPlan(List<MealPlanModel> mealPlans);
}
