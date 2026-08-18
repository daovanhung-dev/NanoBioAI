import 'basic_health_calculator_models.dart';

class BodyMetricsTrackingPoint {
  final DateTime date;
  final double? weightKg;
  final double? calories;
  final double? waterMl;
  final double? sleepHours;
  final double? stressLevel;
  final double? steps;
  final double? heartRateBpm;
  final double? oxygenSaturation;
  final double? dailyScore;
  final String? mood;

  const BodyMetricsTrackingPoint({
    required this.date,
    this.weightKg,
    this.calories,
    this.waterMl,
    this.sleepHours,
    this.stressLevel,
    this.steps,
    this.heartRateBpm,
    this.oxygenSaturation,
    this.dailyScore,
    this.mood,
  });
}

class BodyMetricsNutritionDay {
  final DateTime date;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? waterMl;
  final double? sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final double? cholesterolMg;
  final double? potassiumMg;
  final double? calciumMg;
  final double? ironMg;
  final double mealCompletionRate;
  final int mealCount;

  const BodyMetricsNutritionDay({
    required this.date,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.waterMl,
    this.sugarG,
    this.saturatedFatG,
    this.sodiumMg,
    this.cholesterolMg,
    this.potassiumMg,
    this.calciumMg,
    this.ironMg,
    this.mealCompletionRate = 0,
    this.mealCount = 0,
  });
}

class BodyMetricsLifestyleContext {
  final bool skipBreakfast;
  final bool eatLate;
  final bool eatSweet;
  final bool eatOily;
  final bool lowVegetable;
  final bool lowWater;
  final bool fastFood;
  final bool alcohol;
  final bool coffeeHigh;
  final String? sleepQuality;
  final String? waterPerDay;
  final BasicHealthActivityLevel? activityLevel;
  final DateTime? updatedAt;

  const BodyMetricsLifestyleContext({
    this.skipBreakfast = false,
    this.eatLate = false,
    this.eatSweet = false,
    this.eatOily = false,
    this.lowVegetable = false,
    this.lowWater = false,
    this.fastFood = false,
    this.alcohol = false,
    this.coffeeHigh = false,
    this.sleepQuality,
    this.waterPerDay,
    this.activityLevel,
    this.updatedAt,
  });

  List<String> get activeFlags {
    final result = <String>[];
    if (skipBreakfast) result.add('skip_breakfast');
    if (eatLate) result.add('eat_late');
    if (eatSweet) result.add('eat_sweet');
    if (eatOily) result.add('eat_oily');
    if (lowVegetable) result.add('low_vegetable');
    if (lowWater) result.add('low_water');
    if (fastFood) result.add('fast_food');
    if (alcohol) result.add('alcohol');
    if (coffeeHigh) result.add('coffee_high');
    return result;
  }
}

class BodyMetricsDeclaredCondition {
  final String code;
  final String name;
  final int? severityLevel;

  const BodyMetricsDeclaredCondition({
    required this.code,
    required this.name,
    this.severityLevel,
  });
}

class BodyMetricsDeclaredGoal {
  final String code;
  final String name;

  const BodyMetricsDeclaredGoal({required this.code, required this.name});
}

class BodyMetricsTreatmentContext {
  final String? treatmentName;
  final String? medicationName;

  const BodyMetricsTreatmentContext({this.treatmentName, this.medicationName});
}

class BodyMetricsScheduleSummary {
  final int plannedTaskCount;
  final int completedTaskCount;
  final int plannedExerciseCount;
  final int completedExerciseCount;
  final int plannedHydrationCount;
  final int completedHydrationCount;
  final int plannedSleepCount;
  final int completedSleepCount;
  final DateTime? latestUpdatedAt;

  const BodyMetricsScheduleSummary({
    this.plannedTaskCount = 0,
    this.completedTaskCount = 0,
    this.plannedExerciseCount = 0,
    this.completedExerciseCount = 0,
    this.plannedHydrationCount = 0,
    this.completedHydrationCount = 0,
    this.plannedSleepCount = 0,
    this.completedSleepCount = 0,
    this.latestUpdatedAt,
  });

  double? get completionRate => plannedTaskCount == 0
      ? null
      : completedTaskCount / plannedTaskCount;

  double? get exerciseCompletionRate => plannedExerciseCount == 0
      ? null
      : completedExerciseCount / plannedExerciseCount;
}

/// Read-only snapshot for the current health subject.
///
/// `userId` is required for repository scoping but must never be copied into
/// [BodyMetricsAiContext].
class BodyMetricsHealthSnapshot {
  final String userId;
  final String? fullName;
  final int? ageYears;
  final BasicHealthSex? sex;
  final double? heightCm;
  final double? profileWeightKg;
  final String? occupation;
  final String? bloodPressure;
  final String? bloodSugar;
  final DateTime? profileUpdatedAt;
  final List<BodyMetricsTrackingPoint> tracking;
  final List<BodyMetricsNutritionDay> nutrition;
  final BodyMetricsLifestyleContext? lifestyle;
  final List<BodyMetricsDeclaredCondition> declaredConditions;
  final List<String> allergies;
  final List<BodyMetricsTreatmentContext> treatments;
  final List<BodyMetricsDeclaredGoal> activeGoals;
  final BodyMetricsScheduleSummary schedule;
  final bool contextLoaded;
  final DateTime generatedAt;

  const BodyMetricsHealthSnapshot({
    required this.userId,
    required this.tracking,
    required this.nutrition,
    required this.declaredConditions,
    required this.allergies,
    required this.treatments,
    required this.activeGoals,
    required this.schedule,
    required this.generatedAt,
    this.fullName,
    this.ageYears,
    this.sex,
    this.heightCm,
    this.profileWeightKg,
    this.occupation,
    this.bloodPressure,
    this.bloodSugar,
    this.profileUpdatedAt,
    this.lifestyle,
    this.contextLoaded = true,
  });

  double? get latestTrackedWeightKg {
    for (final point in tracking) {
      if (point.weightKg != null && point.weightKg! > 0) return point.weightKg;
    }
    return null;
  }

  double? get currentWeightKg => latestTrackedWeightKg ?? profileWeightKg;

  BasicHealthActivityLevel? get activityLevel => lifestyle?.activityLevel;

  List<BodyMetricsTrackingPoint> trackingWithinDays(int days) {
    final today = DateTime(generatedAt.year, generatedAt.month, generatedAt.day);
    final threshold = today.subtract(Duration(days: days - 1));
    return tracking
        .where((point) => !point.date.isBefore(threshold))
        .toList(growable: false);
  }

  List<BodyMetricsNutritionDay> nutritionWithinDays(int days) {
    final today = DateTime(generatedAt.year, generatedAt.month, generatedAt.day);
    final threshold = today.subtract(Duration(days: days - 1));
    return nutrition
        .where((point) => !point.date.isBefore(threshold))
        .toList(growable: false);
  }
}
