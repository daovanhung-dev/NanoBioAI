import '../entities/basic_health_calculator_models.dart';
import '../entities/body_metrics_personal_context.dart';

class BodyMetricsProjectionPolicy {
  const BodyMetricsProjectionPolicy._();

  static BodyMetricsThirtyDayScenario build({
    required BasicHealthReport report,
    required BodyMetricsPersonalContext? context,
  }) {
    final plannedCalories = context?.averagePlannedCalories;
    final direction = _classifyEnergyDirection(
      tdeeKcal: report.tdeeKcal,
      plannedCalories: plannedCalories,
    );
    return BodyMetricsThirtyDayScenario(
      energyDirection: direction,
      averagePlannedCalories: plannedCalories,
      plannedMealDays: context?.plannedMealDays ?? 0,
      plannedScheduleItems: context?.plannedScheduleItems ?? 0,
      plannedExerciseItems: context?.plannedExerciseItems ?? 0,
    );
  }

  static BodyMetricsEnergyDirection _classifyEnergyDirection({
    required int tdeeKcal,
    required double? plannedCalories,
  }) {
    if (tdeeKcal <= 0 || plannedCalories == null || plannedCalories <= 0) {
      return BodyMetricsEnergyDirection.unknown;
    }
    final ratio = (plannedCalories - tdeeKcal) / tdeeKcal;
    if (ratio <= -0.10) return BodyMetricsEnergyDirection.belowMaintenance;
    if (ratio >= 0.10) return BodyMetricsEnergyDirection.aboveMaintenance;
    return BodyMetricsEnergyDirection.nearMaintenance;
  }
}
