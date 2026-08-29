import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/providers/body_metrics_providers.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';
import 'package:nano_app/core/health_events/health_event_impact.dart';

import 'health_context_providers.dart';

class RiverpodHealthProjectionInvalidator {
  final Ref ref;

  const RiverpodHealthProjectionInvalidator(this.ref);

  void invalidateAll(
    Set<HealthProjectionTarget> targets, {
    required String subjectId,
  }) {
    for (final target in targets) {
      invalidate(target, subjectId: subjectId);
    }
  }

  void invalidate(
    HealthProjectionTarget target, {
    required String subjectId,
  }) {
    switch (target) {
      case HealthProjectionTarget.healthContext:
        ref.invalidate(healthContextProvider(subjectId));
        break;
      case HealthProjectionTarget.dashboard:
        ref.invalidate(dashboardProvider);
        ref.invalidate(dashboardDynamicProvider);
        ref.invalidate(dailyHealthTrackingControllerProvider);
        break;
      case HealthProjectionTarget.bodyMetrics:
        ref.invalidate(bodyMetricsPersonalContextProvider);
        ref.invalidate(bodyMetricsControllerProvider);
        break;
      case HealthProjectionTarget.nutrition:
        ref.invalidate(nutritionDataBundleProvider);
        ref.invalidate(nutritionSummaryProvider);
        ref.invalidate(nutritionIntelligenceProvider);
        ref.invalidate(nutritionAiReportProvider);
        ref.invalidate(mealPlanControllerProvider);
        ref.invalidate(getMealPlanProvider);
        break;
      case HealthProjectionTarget.schedule:
        ref.invalidate(lifestyleScheduleControllerProvider);
        break;
      case HealthProjectionTarget.weeklySummary:
        // WeeklySummaryPage watches lifestyleScheduleControllerProvider directly.
        // A schedule writer already reloads that authoritative projection; other
        // events must not restart the schedule controller just to refresh a derived
        // weekly view.
        break;
      case HealthProjectionTarget.nabiCare:
        // The NaBi handler performs a subject-checked refresh. Do not destroy an
        // in-flight care state here.
        break;
      case HealthProjectionTarget.notifications:
        // Notification reconciliation is handled by its own side-effect handler.
        break;
    }
  }
}
