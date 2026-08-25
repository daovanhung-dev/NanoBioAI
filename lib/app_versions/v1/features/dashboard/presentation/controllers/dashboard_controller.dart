import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/services/notifications/active_notification_subject.dart';
import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/services/health_orchestration/health_domain_event_sink.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:nano_app/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart';

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
    await _refreshRequiredSupabaseMealCatalog();

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
    await _publishHealthEvent(
      type: HealthEventType.mealPlanUpdated,
      subjectId: dashboardData.userId,
      sourceFeature: 'dashboard.meal_plan_generation',
      changedFields: const {'meal_plan'},
    );
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
      await _refreshRequiredSupabaseMealCatalog();
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

      await _publishHealthEvent(
        type: HealthEventType.mealPlanUpdated,
        subjectId: authUserId,
        sourceFeature: 'dashboard.additional_plan',
        changedFields: const {'meal_plan', 'schedule'},
      );

      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _refreshRequiredSupabaseMealCatalog() async {
    final count =
        await MealCatalogCacheRefreshService.refreshFromInitializedSupabase();
    if (count <= 0) {
      throw StateError('Supabase meal_catalog has no active meals.');
    }
  }

  String _memberPlanRequestId(String userId) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'member_plan:$userId:$timestamp';
  }

  Future<void> saveDailyCheckIn(String mood) async {
    await ref.read(dailyHealthTrackingRepositoryProvider).saveTodayMood(mood);
    _invalidateDashboardDependents();
    await _publishHealthEvent(
      type: HealthEventType.dailyHealthRecorded,
      sourceFeature: 'dashboard.daily_checkin',
      changedFields: const {'mood'},
    );
  }

  Future<void> addWater(int amountMl) async {
    await ref
        .read(dailyHealthTrackingRepositoryProvider)
        .addTodayWater(amountMl);
    _invalidateDashboardDependents();
    await _publishHealthEvent(
      type: HealthEventType.waterLogged,
      sourceFeature: 'dashboard.daily_health',
      changedFields: const {'water_ml'},
    );
  }

  Future<void> setWater(int waterMl) async {
    await ref
        .read(dailyHealthTrackingRepositoryProvider)
        .setTodayWater(waterMl);
    _invalidateDashboardDependents();
    await _publishHealthEvent(
      type: HealthEventType.waterLogged,
      sourceFeature: 'dashboard.daily_health',
      changedFields: const {'water_ml'},
    );
  }

  Future<void> saveWeight(double weightKg) async {
    await ref
        .read(dailyHealthTrackingRepositoryProvider)
        .saveTodayWeight(weightKg);
    _invalidateDashboardDependents();
    await _publishHealthEvent(
      type: HealthEventType.dailyHealthRecorded,
      sourceFeature: 'dashboard.daily_health',
      changedFields: const {'weight_kg'},
    );
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

  Future<void> _publishHealthEvent({
    required HealthEventType type,
    required String sourceFeature,
    String? subjectId,
    Set<String> changedFields = const <String>{},
  }) async {
    try {
      final resolved = (subjectId ?? await resolveActiveNotificationSubject())
          ?.trim();
      if (resolved == null || resolved.isEmpty) return;
      await ref.read(healthDomainEventSinkProvider).publish(
            HealthDomainEvent.create(
              type: type,
              subjectId: resolved,
              sourceFeature: sourceFeature,
              changedFields: changedFields,
            ),
          );
    } catch (_) {
      // Persistence remains authoritative if orchestration enrichment fails.
    }
  }
}
