import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';

import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

import 'package:nano_app/services/ai/ai_service.dart';

import 'package:nano_app/services/ai/prompts/nutrition_prompt.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<
      DashboardController,
      void
    >(
      DashboardController.new,
    );

class DashboardController
    extends AsyncNotifier<void> {

  @override
  Future<void> build() async {}

  Future<void> pushMealByWeeksToDB()
      async {

    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {

        final repository = ref.read(
          dashboardRepositoryProvider,
        );

        final DashboardEntity
            dashboardData =
                await repository
                    .fetchDashboard();

        final prompt = ref.read(
          nutritionPromptProvider,
        );

        final AIService aiService =
            ref.read(
              aiServiceProvider,
            );

        final List<MealPlanModel>
            mealPlan =
                await aiService
                    .generateMealPlan(
          healthData: dashboardData,
        );

        await repository
            .saveMealPlan(
          mealPlan,
        );
      },
    );
  }
}