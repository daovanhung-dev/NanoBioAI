import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';

import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

import 'package:nano_app/services/ai/ai_service.dart';

import 'package:nano_app/services/ai/prompts/nutrition_prompt.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, void>(DashboardController.new);

class DashboardController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> genMealByWeeksToDB() async {
    print("gen meal plan by weeks to DB function called");
    print("1");
    final repository = ref.read(dashboardRepositoryProvider);
    print("2");

    final DashboardEntity dashboardData = await repository.fetchDashboard();
    print("3");

    final prompt = ref.read(nutritionPromptProvider);
    print("4");

    final AIService aiService = ref.read(aiServiceProvider);
    print("5");

    final List<MealPlanModel> mealPlan = await aiService.generateMealPlan(
      healthData: dashboardData,
    );
    print("6");

    await repository.saveMealPlan(mealPlan);
    print("Saved meal plan to DB successfully");
  }
}
