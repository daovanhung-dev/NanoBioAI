import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';

import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

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
    requireAuthenticatedGeneratedPlanUser(currentSupabaseUserIdOrNull());

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

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<GeneratedPlanResult> generateAdditionalPlan() async {
    final authUserId = currentSupabaseUserIdOrNull();
    requireAuthenticatedGeneratedPlanUser(authUserId);

    state = const AsyncLoading<void>();
    try {
      final result = await ref
          .read(generatedPlanServiceProvider)
          .generateNextPlan(
            requestId: _memberPlanRequestId(authUserId!),
            days: 7,
            startDate: _today(),
            appendAfterExisting: true,
          );

      ref.invalidate(dashboardProvider);
      ref.invalidate(dashboardDynamicProvider);
      ref.invalidate(lifestyleScheduleControllerProvider);
      ref.invalidate(mealPlanControllerProvider);
      ref.invalidate(getMealPlanProvider);
      ref.invalidate(nutritionSummaryProvider);

      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }

  String _memberPlanRequestId(String userId) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'member_plan:$userId:$timestamp';
  }

  Future<void> saveDailyCheckIn(String mood) async {
    await ref.read(dailyHealthTrackingRepositoryProvider).saveTodayMood(mood);
    _invalidateDashboardDependents();
  }

  Future<void> addWater(int amountMl) async {
    await ref
        .read(dailyHealthTrackingRepositoryProvider)
        .addTodayWater(amountMl);
    _invalidateDashboardDependents();
  }

  Future<void> setWater(int waterMl) async {
    await ref
        .read(dailyHealthTrackingRepositoryProvider)
        .setTodayWater(waterMl);
    _invalidateDashboardDependents();
  }

  Future<void> saveWeight(double weightKg) async {
    await ref
        .read(dailyHealthTrackingRepositoryProvider)
        .saveTodayWeight(weightKg);
    _invalidateDashboardDependents();
  }

  void _invalidateDashboardDependents() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardDynamicProvider);
    ref.invalidate(dailyHealthTrackingControllerProvider);
    ref.invalidate(lifestyleScheduleControllerProvider);
    ref.invalidate(mealPlanControllerProvider);
    ref.invalidate(getMealPlanProvider);
    ref.invalidate(nutritionSummaryProvider);
  }
}
