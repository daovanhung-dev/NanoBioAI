import 'basic_health_calculator_models.dart';

class BodyMetricsPersonalContext {
  final String userId;
  final String? fullName;
  final double? heightCm;
  final double? weightKg;
  final int? ageYears;
  final BasicHealthSex? sex;
  final BasicHealthActivityLevel? activityLevel;
  final double? averagePlannedCalories;
  final int plannedMealDays;
  final int plannedScheduleItems;
  final int plannedExerciseItems;
  final bool weightFromRecentTracking;

  const BodyMetricsPersonalContext({
    required this.userId,
    this.fullName,
    this.heightCm,
    this.weightKg,
    this.ageYears,
    this.sex,
    this.activityLevel,
    this.averagePlannedCalories,
    this.plannedMealDays = 0,
    this.plannedScheduleItems = 0,
    this.plannedExerciseItems = 0,
    this.weightFromRecentTracking = false,
  });

  bool get hasProfileMetrics =>
      heightCm != null && weightKg != null && ageYears != null && sex != null;

  bool get hasPlanContext => plannedMealDays > 0 || plannedScheduleItems > 0;

  double get dataCompleteness {
    var score = 0;
    if (heightCm != null) score++;
    if (weightKg != null) score++;
    if (ageYears != null) score++;
    if (sex != null) score++;
    if (activityLevel != null) score++;
    if (plannedMealDays > 0) score++;
    if (plannedScheduleItems > 0) score++;
    return score / 7;
  }
}

enum BodyMetricsEnergyDirection {
  unknown,
  belowMaintenance,
  nearMaintenance,
  aboveMaintenance,
}

class BodyMetricsThirtyDayScenario {
  final BodyMetricsEnergyDirection energyDirection;
  final double? averagePlannedCalories;
  final int plannedMealDays;
  final int plannedScheduleItems;
  final int plannedExerciseItems;

  const BodyMetricsThirtyDayScenario({
    required this.energyDirection,
    required this.averagePlannedCalories,
    required this.plannedMealDays,
    required this.plannedScheduleItems,
    required this.plannedExerciseItems,
  });

  bool get hasEnoughPlanData => plannedMealDays >= 3 || plannedScheduleItems >= 10;
}

class BodyMetricsAiInsight {
  final String currentStatus;
  final String afterThirtyDays;
  final String confidence;
  final List<String> factors;
  final List<String> assumptions;
  final bool generatedByAi;

  const BodyMetricsAiInsight({
    required this.currentStatus,
    required this.afterThirtyDays,
    required this.confidence,
    required this.factors,
    required this.assumptions,
    required this.generatedByAi,
  });

  const BodyMetricsAiInsight.unavailable({
    this.currentStatus = 'Nabi chưa thể phân tích bằng AI lúc này.',
    this.afterThirtyDays =
        'Các chỉ số nền vẫn được tính bình thường; dự báo AI sẽ xuất hiện khi kết nối sẵn sàng.',
    this.confidence = 'chưa xác định',
    this.factors = const [],
    this.assumptions = const [],
  }) : generatedByAi = false;
}
