import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'package:nano_app/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/features/meal_plan/providers/meal_plan_provider.dart';

import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';

import 'package:nano_app/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

import 'package:nano_app/services/ai/ai_service.dart';
import 'package:nano_app/services/ai/generated_plan_service.dart';

final generatedPlanServiceProvider = Provider<GeneratedPlanService>((ref) {
  return GeneratedPlanService(
    dashboardRepository: ref.read(dashboardRepositoryProvider),
    dailyHealthDatasource: ref.read(dailyHealthTrackingLocalDatasourceProvider),
    scheduleDatasource: ref.read(lifestyleScheduleLocalDatasourceProvider),
    aiService: ref.read(aiServiceProvider),
  );
});

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, void>(DashboardController.new);

class DashboardController extends AsyncNotifier<void> {
  static const _tag = 'DASHBOARD_CONTROLLER';

  @override
  Future<void> build() async {}

  Future<void> genMealByWeeksToDB({
    bool requireComplete = false,
    DateTime? startDate,
    int days = 7,
  }) async {
    AppLogger.action(_tag, 'Generate weekly meal plan');
    final repository = ref.read(dashboardRepositoryProvider);
    final resolvedStartDate = startDate ?? _tomorrow();

    final DashboardEntity dashboardData = await repository.fetchDashboard();
    AppLogger.info(_tag, 'Dashboard data fetched for meal generation');

    final AIService aiService = ref.read(aiServiceProvider);

    final List<MealPlanModel> mealPlan = await aiService.generateMealPlan(
      healthData: dashboardData,
      userId: dashboardData.userId.toString(),
      startDate: resolvedStartDate,
      days: days,
    );
    AppLogger.info(_tag, 'Generated ${mealPlan.length} meal plan records');

    final expectedCount = days * MealPlanAiNormalizer.mealsPerDay;
    if (requireComplete && mealPlan.length != expectedCount) {
      throw StateError(
        'Expected $expectedCount meal plan records, got ${mealPlan.length}',
      );
    }

    await repository.saveMealPlan(mealPlan);
    AppLogger.success(_tag, 'Saved meal plan to DB successfully');
  }

  DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<GeneratedPlanResult> generateAdditionalPlan() async {
    state = const AsyncLoading<void>();
    try {
      final result = await ref
          .read(generatedPlanServiceProvider)
          .generateNextPlan(days: 7);

      ref.invalidate(dashboardProvider);
      ref.invalidate(dashboardDynamicProvider);
      ref.invalidate(lifestyleScheduleControllerProvider);
      ref.invalidate(getMealPlanProvider);

      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
