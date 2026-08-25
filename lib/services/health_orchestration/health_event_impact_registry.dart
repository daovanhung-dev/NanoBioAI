import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_impact.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';

class HealthEventImpactRegistry {
  const HealthEventImpactRegistry();

  HealthEventImpact resolve(HealthDomainEvent event) {
    final base = switch (event.type) {
      HealthEventType.profileUpdated => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.bodyMetrics,
            HealthProjectionTarget.nutrition,
            HealthProjectionTarget.nabiCare,
          },
          evaluateNabi: true,
        ),
      HealthEventType.healthCheckInRecorded => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.nabiCare,
          },
          evaluateNabi: true,
        ),
      HealthEventType.dailyHealthRecorded => HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
            if (event.changedFields.contains('weight_kg'))
              HealthProjectionTarget.bodyMetrics,
          },
          evaluateNabi: event.changedFields.any(
            const {'mood', 'weight_kg', 'stress_level', 'sleep_hours'}.contains,
          ),
        ),
      HealthEventType.waterLogged => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
          },
        ),
      HealthEventType.waterTargetUpdated => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
          },
        ),
      HealthEventType.waterGoalReached => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
          },
        ),
      HealthEventType.sleepSummaryUpdated => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.nabiCare,
          },
          evaluateNabi: true,
        ),
      HealthEventType.sleepRiskDetected => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.nabiCare,
            HealthProjectionTarget.notifications,
          },
          evaluateNabi: true,
          reconcileNotifications: true,
        ),
      HealthEventType.stressRecorded => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.nabiCare,
          },
          evaluateNabi: true,
        ),
      HealthEventType.nutritionUpdated ||
      HealthEventType.nutritionProfileUpdated => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.nutrition,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.nabiCare,
          },
          evaluateNabi: true,
        ),
      HealthEventType.foodScanConfirmedConsumed => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.nutrition,
            HealthProjectionTarget.weeklySummary,
          },
        ),
      HealthEventType.mealPlanUpdated => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.nutrition,
            HealthProjectionTarget.schedule,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.notifications,
          },
          reconcileNotifications: true,
        ),
      HealthEventType.scheduleUpdated ||
      HealthEventType.taskRescheduled => const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.schedule,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.notifications,
          },
          reconcileNotifications: true,
        ),
      HealthEventType.taskCompleted || HealthEventType.taskSkipped =>
        const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.weeklySummary,
          },
        ),
      HealthEventType.goalUpdated || HealthEventType.goalCompleted =>
        const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.bodyMetrics,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.nabiCare,
          },
          evaluateNabi: true,
        ),
      HealthEventType.authIdentityChanged || HealthEventType.cloudSyncCompleted =>
        const HealthEventImpact(
          targets: {
            HealthProjectionTarget.healthContext,
            HealthProjectionTarget.dashboard,
            HealthProjectionTarget.bodyMetrics,
            HealthProjectionTarget.nutrition,
            HealthProjectionTarget.schedule,
            HealthProjectionTarget.weeklySummary,
            HealthProjectionTarget.nabiCare,
          },
        ),
    };
    return base;
  }
}
