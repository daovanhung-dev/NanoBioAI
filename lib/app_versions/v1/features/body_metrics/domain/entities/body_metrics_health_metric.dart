enum BodyMetricsMetricCategory {
  body,
  energy,
  nutrition,
  hydration,
  recovery,
  activity,
  adherence,
  dataQuality,
  observation,
}

enum BodyMetricsMetricSource { measured, calculated, aggregate, observation }

enum BodyMetricsMetricStatus { normal, attention, info, stale, insufficientData }

class BodyMetricsHealthMetric {
  final String id;
  final BodyMetricsMetricCategory category;
  final String title;
  final double? value;
  final String? textValue;
  final String unit;
  final BodyMetricsMetricStatus status;
  final BodyMetricsMetricSource source;
  final String formulaVersion;
  final String reference;
  final String dataWindow;
  final double confidence;
  final double? rangeMin;
  final double? rangeMax;

  const BodyMetricsHealthMetric({
    required this.id,
    required this.category,
    required this.title,
    required this.unit,
    required this.status,
    required this.source,
    required this.formulaVersion,
    required this.reference,
    required this.dataWindow,
    this.value,
    this.textValue,
    this.confidence = 1,
    this.rangeMin,
    this.rangeMax,
  });

  bool get hasValue => value != null || (textValue?.trim().isNotEmpty ?? false);
}

class BodyMetricsMetricIds {
  static const bmi = 'body.bmi';
  static const bmiCategory = 'body.bmi_category';
  static const healthyWeightLower = 'body.healthy_weight_lower';
  static const healthyWeightUpper = 'body.healthy_weight_upper';
  static const distanceHealthyRange = 'body.distance_healthy_range';
  static const weightChange7d = 'body.weight_change_7d';
  static const weightChange30d = 'body.weight_change_30d';
  static const weightChangePercent = 'body.weight_change_percent';
  static const weightTrendSlope = 'body.weight_trend_slope';
  static const weightVariability = 'body.weight_variability';
  static const restingEnergy = 'energy.mifflin_ree';
  static const eer = 'energy.eer';
  static const tdee = 'energy.tdee';
  static const plannedCalories = 'energy.planned_calories';
  static const energyGap = 'energy.gap';
  static const energyAlignment = 'energy.alignment_percent';
  static const energyAverage7d = 'energy.average_7d';
  static const energyAverage30d = 'energy.average_30d';
  static const proteinPerDay = 'nutrition.protein_g_day';
  static const proteinPerKg = 'nutrition.protein_g_kg';
  static const proteinEnergyPercent = 'nutrition.protein_energy_percent';
  static const carbEnergyPercent = 'nutrition.carb_energy_percent';
  static const fatEnergyPercent = 'nutrition.fat_energy_percent';
  static const macroCalories = 'nutrition.macro_calories';
  static const calorieReconciliationError = 'nutrition.calorie_reconciliation_error';
  static const macroBalanceCount = 'nutrition.macro_balance_count';
  static const fiberDensity = 'nutrition.fiber_density';
  static const fiberReferenceTarget = 'nutrition.fiber_reference_target';
  static const fiberCoverage = 'nutrition.fiber_coverage';
  static const sodiumRatio = 'nutrition.sodium_ratio';
  static const potassiumAverage = 'nutrition.potassium_average';
  static const calciumAverage = 'nutrition.calcium_average';
  static const ironAverage = 'nutrition.iron_average';
  static const sugarAverage = 'nutrition.sugar_average';
  static const saturatedFatAverage = 'nutrition.saturated_fat_average';
  static const waterAverage7d = 'hydration.water_average_7d';
  static const waterAverage30d = 'hydration.water_average_30d';
  static const waterLoggingConsistency = 'hydration.logging_consistency';
  static const waterTrend = 'hydration.trend';
  static const sleepAverage7d = 'recovery.sleep_average_7d';
  static const sleepAverage30d = 'recovery.sleep_average_30d';
  static const sleepAdequacy = 'recovery.sleep_adequacy';
  static const sleepVariability = 'recovery.sleep_variability';
  static const stressAverage = 'recovery.stress_average';
  static const stressTrend = 'recovery.stress_trend';
  static const moodDistribution = 'recovery.mood_distribution';
  static const stepsAverage = 'activity.steps_average';
  static const stepsTrend = 'activity.steps_trend';
  static const estimatedMaxHr = 'activity.estimated_max_hr';
  static const moderateHrZone = 'activity.moderate_hr_zone';
  static const vigorousHrZone = 'activity.vigorous_hr_zone';
  static const latestHeartRate = 'observation.heart_rate_latest';
  static const averageHeartRate30d = 'observation.heart_rate_average_30d';
  static const latestSpO2 = 'observation.spo2_latest';
  static const averageSpO230d = 'observation.spo2_average_30d';
  static const bloodPressureObservation = 'observation.blood_pressure';
  static const bloodSugarObservation = 'observation.blood_sugar';
  static const mealCompletion = 'adherence.meal_completion';
  static const scheduleCompletion = 'adherence.schedule_completion';
  static const dataCompletenessFreshness = 'data.completeness_freshness';

  static const all = <String>[
    bmi,
    bmiCategory,
    healthyWeightLower,
    healthyWeightUpper,
    distanceHealthyRange,
    weightChange7d,
    weightChange30d,
    weightChangePercent,
    weightTrendSlope,
    weightVariability,
    restingEnergy,
    eer,
    tdee,
    plannedCalories,
    energyGap,
    energyAlignment,
    energyAverage7d,
    energyAverage30d,
    proteinPerDay,
    proteinPerKg,
    proteinEnergyPercent,
    carbEnergyPercent,
    fatEnergyPercent,
    macroCalories,
    calorieReconciliationError,
    macroBalanceCount,
    fiberDensity,
    fiberReferenceTarget,
    fiberCoverage,
    sodiumRatio,
    potassiumAverage,
    calciumAverage,
    ironAverage,
    sugarAverage,
    saturatedFatAverage,
    waterAverage7d,
    waterAverage30d,
    waterLoggingConsistency,
    waterTrend,
    sleepAverage7d,
    sleepAverage30d,
    sleepAdequacy,
    sleepVariability,
    stressAverage,
    stressTrend,
    moodDistribution,
    stepsAverage,
    stepsTrend,
    estimatedMaxHr,
    moderateHrZone,
    vigorousHrZone,
    latestHeartRate,
    averageHeartRate30d,
    latestSpO2,
    averageSpO230d,
    bloodPressureObservation,
    bloodSugarObservation,
    mealCompletion,
    scheduleCompletion,
    dataCompletenessFreshness,
  ];
}
