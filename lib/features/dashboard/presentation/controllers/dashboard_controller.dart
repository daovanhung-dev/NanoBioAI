import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';

import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

import 'package:nano_app/services/ai/ai_service.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, void>(DashboardController.new);

class DashboardController extends AsyncNotifier<void> {
  static const _tag = 'DASHBOARD_CONTROLLER';

  @override
  Future<void> build() async {}

  Future<void> genMealByWeeksToDB() async {
    AppLogger.action(_tag, 'Generate weekly meal plan');
    final repository = ref.read(dashboardRepositoryProvider);

    final DashboardEntity dashboardData = await repository.fetchDashboard();
    AppLogger.info(_tag, 'Dashboard data fetched for meal generation');

    final AIService aiService = ref.read(aiServiceProvider);

    final List<MealPlanModel> mealPlan = await aiService.generateMealPlan(
      healthData: dashboardData,
    );
    AppLogger.info(_tag, 'Generated ${mealPlan.length} meal plan records');

    await repository.saveMealPlan(mealPlan);
    AppLogger.success(_tag, 'Saved meal plan to DB successfully');
  }
}
