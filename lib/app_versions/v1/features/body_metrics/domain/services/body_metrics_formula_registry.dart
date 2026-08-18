import '../entities/body_metrics_health_metric.dart';

class BodyMetricsFormulaDefinition {
  final String metricId;
  final String version;
  final String reference;
  final List<String> requiredInputs;

  const BodyMetricsFormulaDefinition({
    required this.metricId,
    required this.version,
    required this.reference,
    required this.requiredInputs,
  });
}

class BodyMetricsFormulaRegistry {
  static const release = 'm04_health_dashboard_2026_08';

  static BodyMetricsFormulaDefinition definition(String metricId) {
    return _definitions[metricId] ?? BodyMetricsFormulaDefinition(
      metricId: metricId,
      version: '$release-observation-v1',
      reference: 'NanoBio deterministic wellness aggregation',
      requiredInputs: const [],
    );
  }

  static final Map<String, BodyMetricsFormulaDefinition> _definitions = {
    BodyMetricsMetricIds.bmi: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.bmi,
      version: 'm04_bmi_v2_2026_08',
      reference: 'BMI = weight(kg) / height(m)^2; wellness screening only',
      requiredInputs: ['height_cm', 'weight_kg'],
    ),
    BodyMetricsMetricIds.bmiCategory: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.bmiCategory,
      version: 'm04_bmi_category_v2_2026_08',
      reference: 'Adult BMI reference bands; not a diagnosis',
      requiredInputs: ['bmi'],
    ),
    BodyMetricsMetricIds.healthyWeightLower: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.healthyWeightLower,
      version: 'm04_weight_range_v1_2026_08',
      reference: 'BMI reference band lower bound projected to current height',
      requiredInputs: ['height_cm'],
    ),
    BodyMetricsMetricIds.healthyWeightUpper: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.healthyWeightUpper,
      version: 'm04_weight_range_v1_2026_08',
      reference: 'BMI reference band upper bound projected to current height',
      requiredInputs: ['height_cm'],
    ),
    BodyMetricsMetricIds.restingEnergy: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.restingEnergy,
      version: 'm04_mifflin_v2_2026_08',
      reference: 'Mifflin-St Jeor resting energy equation',
      requiredInputs: ['height_cm', 'weight_kg', 'age', 'sex'],
    ),
    BodyMetricsMetricIds.eer: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.eer,
      version: 'm04_eer_dri_v1_2026_08',
      reference: 'Adult Dietary Reference Intake estimated energy requirement equation',
      requiredInputs: ['height_cm', 'weight_kg', 'age', 'sex', 'activity_level'],
    ),
    BodyMetricsMetricIds.tdee: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.tdee,
      version: 'm04_tdee_v2_2026_08',
      reference: 'Mifflin resting energy multiplied by activity factor',
      requiredInputs: ['resting_energy', 'activity_level'],
    ),
    BodyMetricsMetricIds.fiberDensity: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.fiberDensity,
      version: 'm04_fiber_density_v1_2026_08',
      reference: 'Fiber grams per one thousand kcal',
      requiredInputs: ['fiber_g', 'calories'],
    ),
    BodyMetricsMetricIds.fiberReferenceTarget: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.fiberReferenceTarget,
      version: 'm04_fiber_target_v1_2026_08',
      reference: 'Wellness reference: fourteen grams fiber per one thousand kcal',
      requiredInputs: ['calories'],
    ),
    BodyMetricsMetricIds.sodiumRatio: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.sodiumRatio,
      version: 'm04_sodium_ratio_v1_2026_08',
      reference: 'Ratio against 2300 mg/day adult reference ceiling; context only',
      requiredInputs: ['sodium_mg'],
    ),
    BodyMetricsMetricIds.estimatedMaxHr: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.estimatedMaxHr,
      version: 'm04_hrmax_220_age_v1_2026_08',
      reference: 'Age-predicted maximum heart rate estimate; observation only',
      requiredInputs: ['age'],
    ),
    BodyMetricsMetricIds.moderateHrZone: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.moderateHrZone,
      version: 'm04_hr_zone_v1_2026_08',
      reference: 'Estimated moderate intensity band from age-predicted maximum HR',
      requiredInputs: ['estimated_max_hr'],
    ),
    BodyMetricsMetricIds.vigorousHrZone: const BodyMetricsFormulaDefinition(
      metricId: BodyMetricsMetricIds.vigorousHrZone,
      version: 'm04_hr_zone_v1_2026_08',
      reference: 'Estimated vigorous intensity band from age-predicted maximum HR',
      requiredInputs: ['estimated_max_hr'],
    ),
  };
}
