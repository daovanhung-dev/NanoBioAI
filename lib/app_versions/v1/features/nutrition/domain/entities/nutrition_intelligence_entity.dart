class NutritionNutrientTotals {
  const NutritionNutrientTotals({
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.saturatedFatG,
    this.sodiumMg,
    this.potassiumMg,
    this.calciumMg,
    this.ironMg,
    this.cholesterolMg,
    this.magnesiumMg,
    this.zincMg,
    this.vitaminAMcg,
    this.vitaminCMg,
    this.vitaminDMcg,
    this.vitaminB12Mcg,
    this.folateMcg,
  });

  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final double? potassiumMg;
  final double? calciumMg;
  final double? ironMg;
  final double? cholesterolMg;
  final double? magnesiumMg;
  final double? zincMg;
  final double? vitaminAMcg;
  final double? vitaminCMg;
  final double? vitaminDMcg;
  final double? vitaminB12Mcg;
  final double? folateMcg;

  Map<String, Object?> toPromptPayload() => {
        'energy_kcal': _rounded(energyKcal),
        'protein_g': _rounded(proteinG),
        'carbs_g': _rounded(carbsG),
        'fat_g': _rounded(fatG),
        'fiber_g': _rounded(fiberG),
        'sugar_g': _rounded(sugarG),
        'saturated_fat_g': _rounded(saturatedFatG),
        'sodium_mg': _rounded(sodiumMg),
        'potassium_mg': _rounded(potassiumMg),
        'calcium_mg': _rounded(calciumMg),
        'iron_mg': _rounded(ironMg),
        'cholesterol_mg': _rounded(cholesterolMg),
        'magnesium_mg': _rounded(magnesiumMg),
        'zinc_mg': _rounded(zincMg),
        'vitamin_a_mcg': _rounded(vitaminAMcg),
        'vitamin_c_mg': _rounded(vitaminCMg),
        'vitamin_d_mcg': _rounded(vitaminDMcg),
        'vitamin_b12_mcg': _rounded(vitaminB12Mcg),
        'folate_mcg': _rounded(folateMcg),
      };
}

enum NutritionCoverageStatus {
  insufficientData,
  low,
  nearPlan,
  onTrack,
  abovePlan,
}

class NutritionCoverageMetric {
  const NutritionCoverageMetric({
    required this.code,
    required this.label,
    required this.unit,
    required this.actual,
    required this.planned,
    required this.status,
    required this.dataCoverage,
  });

  final String code;
  final String label;
  final String unit;
  final double? actual;
  final double? planned;
  final NutritionCoverageStatus status;
  final double dataCoverage;

  double? get ratio {
    final target = planned;
    final consumed = actual;
    if (target == null || target <= 0 || consumed == null) return null;
    return consumed / target;
  }

  Map<String, Object?> toPromptPayload() => {
        'code': code,
        'actual': _rounded(actual),
        'planned': _rounded(planned),
        'unit': unit,
        'data_coverage': _rounded(dataCoverage),
        'status': status.name,
      };
}

class NutritionMealDistribution {
  const NutritionMealDistribution({
    required this.mealType,
    required this.energyKcal,
    required this.loggedItems,
  });

  final String mealType;
  final double energyKcal;
  final int loggedItems;

  Map<String, Object?> toPromptPayload() => {
        'meal_type': mealType,
        'energy_kcal': _rounded(energyKcal),
        'logged_items': loggedItems,
      };
}

class NutritionTrendPoint {
  const NutritionTrendPoint({
    required this.date,
    this.energyKcal,
    this.proteinG,
    required this.loggedMeals,
  });

  final DateTime date;
  final double? energyKcal;
  final double? proteinG;
  final int loggedMeals;

  Map<String, Object?> toPromptPayload() => {
        'date': _dateKey(date),
        'energy_kcal': _rounded(energyKcal),
        'protein_g': _rounded(proteinG),
        'logged_meals': loggedMeals,
      };
}

class NutritionHealthContext {
  const NutritionHealthContext({
    this.weightKg,
    this.bmi,
    this.waterMl,
    this.sleepHours,
    this.stressLevel,
    this.stepsCount,
    this.mood,
    this.sevenDayAverageWaterMl,
    this.sevenDayAverageSleepHours,
    this.sevenDayAverageSteps,
  });

  final double? weightKg;
  final double? bmi;
  final int? waterMl;
  final double? sleepHours;
  final int? stressLevel;
  final int? stepsCount;
  final String? mood;
  final double? sevenDayAverageWaterMl;
  final double? sevenDayAverageSleepHours;
  final double? sevenDayAverageSteps;

  bool get hasAnyValue =>
      weightKg != null ||
      bmi != null ||
      waterMl != null ||
      sleepHours != null ||
      stressLevel != null ||
      stepsCount != null ||
      (mood?.trim().isNotEmpty ?? false) ||
      sevenDayAverageWaterMl != null ||
      sevenDayAverageSleepHours != null ||
      sevenDayAverageSteps != null;

  Map<String, Object?> toPromptPayload() => {
        'weight_kg': _rounded(weightKg),
        'bmi': _rounded(bmi),
        'water_ml': waterMl,
        'sleep_hours': _rounded(sleepHours),
        'stress_level': stressLevel,
        'steps_count': stepsCount,
        'mood': _textOrNull(mood),
        'seven_day_average_water_ml': _rounded(sevenDayAverageWaterMl),
        'seven_day_average_sleep_hours':
            _rounded(sevenDayAverageSleepHours),
        'seven_day_average_steps': _rounded(sevenDayAverageSteps),
      };
}

class NutritionDataQuality {
  const NutritionDataQuality({
    required this.score,
    required this.level,
    required this.missingData,
    required this.richNutritionLogRatio,
    required this.daysWithLogsInLast7,
    required this.daysWithLogsInLast30,
  });

  final int score;
  final String level;
  final List<String> missingData;
  final double richNutritionLogRatio;
  final int daysWithLogsInLast7;
  final int daysWithLogsInLast30;

  Map<String, Object?> toPromptPayload() => {
        'score': score,
        'level': level,
        'rich_log_ratio': _rounded(richNutritionLogRatio),
        'days_with_logs_last_7': daysWithLogsInLast7,
        'days_with_logs_last_30': daysWithLogsInLast30,
        'missing_data': missingData,
      };
}

class NutritionIntelligence {
  const NutritionIntelligence({
    required this.selectedDate,
    required this.actual,
    required this.planned,
    required this.coverage,
    required this.mealDistribution,
    required this.sevenDayTrend,
    required this.thirtyDayTrend,
    required this.healthContext,
    required this.dataQuality,
    required this.loggedItems,
    required this.plannedMeals,
  });

  final DateTime selectedDate;
  final NutritionNutrientTotals actual;
  final NutritionNutrientTotals planned;
  final List<NutritionCoverageMetric> coverage;
  final List<NutritionMealDistribution> mealDistribution;
  final List<NutritionTrendPoint> sevenDayTrend;
  final List<NutritionTrendPoint> thirtyDayTrend;
  final NutritionHealthContext healthContext;
  final NutritionDataQuality dataQuality;
  final int loggedItems;
  final int plannedMeals;

  bool get hasUsefulData => loggedItems > 0 || plannedMeals > 0;

  Map<String, Object?> toPromptPayload() => {
        'selected_date': _dateKey(selectedDate),
        'logged_items': loggedItems,
        'planned_meals': plannedMeals,
        'actual': actual.toPromptPayload(),
        'planned': planned.toPromptPayload(),
        'coverage': coverage.map((item) => item.toPromptPayload()).toList(),
        'meal_distribution':
            mealDistribution.map((item) => item.toPromptPayload()).toList(),
        'seven_day_trend':
            sevenDayTrend.map((item) => item.toPromptPayload()).toList(),
        'thirty_day_data_days': dataQuality.daysWithLogsInLast30,
        'health_context': healthContext.toPromptPayload(),
        'data_quality': dataQuality.toPromptPayload(),
      };
}

class NutritionEvidenceSignal {
  const NutritionEvidenceSignal({
    required this.code,
    required this.label,
    this.note,
  });

  final String code;
  final String label;
  final String? note;

  Map<String, Object?> toPromptPayload() => {
        'code': code,
        'label': label,
        if (_textOrNull(note) != null) 'note': _textOrNull(note),
      };
}

class NutritionHealthSnapshot {
  const NutritionHealthSnapshot({
    required this.intelligence,
    this.goal,
    this.restrictions = const [],
    this.allergies = const [],
    this.symptoms = const [],
    this.labs = const [],
    this.medicationCount = 0,
    this.currentStatus,
  });

  final NutritionIntelligence intelligence;
  final NutritionEvidenceSignal? goal;
  final List<NutritionEvidenceSignal> restrictions;
  final List<NutritionEvidenceSignal> allergies;
  final List<NutritionEvidenceSignal> symptoms;
  final List<NutritionEvidenceSignal> labs;
  final int medicationCount;
  final String? currentStatus;

  String? get primaryGoalCode => goal?.code;
  Set<String> get allergyCodes => allergies.map((item) => item.code).toSet();
  Set<String> get avoidanceCodes =>
      restrictions.map((item) => item.code).toSet();
  Set<String> get symptomCodes => symptoms.map((item) => item.code).toSet();
  Set<String> get labCodes => labs.map((item) => item.code).toSet();

  Map<String, Object?> toPromptPayload() => {
        'nutrition': intelligence.toPromptPayload(),
        'goal': goal?.toPromptPayload(),
        'restrictions':
            restrictions.map((item) => item.toPromptPayload()).toList(),
        'allergies': allergies.map((item) => item.toPromptPayload()).toList(),
        'symptoms': symptoms.map((item) => item.toPromptPayload()).toList(),
        'labs': labs.map((item) => item.toPromptPayload()).toList(),
        'active_medication_count': medicationCount,
        'current_status': _textOrNull(currentStatus),
      };
}

class NutritionAiInsight {
  const NutritionAiInsight({
    required this.title,
    required this.body,
    required this.evidenceCodes,
    required this.confidence,
    required this.priority,
  });

  final String title;
  final String body;
  final List<String> evidenceCodes;
  final String confidence;
  final String priority;
}

class NutritionAiReport {
  const NutritionAiReport({
    required this.summary,
    required this.insights,
    required this.todayActions,
    required this.weeklyActions,
    required this.missingData,
    required this.safetyFlags,
    required this.confidence,
    required this.generatedByAi,
  });

  final String summary;
  final List<NutritionAiInsight> insights;
  final List<String> todayActions;
  final List<String> weeklyActions;
  final List<String> missingData;
  final List<String> safetyFlags;
  final String confidence;
  final bool generatedByAi;

  factory NutritionAiReport.fallback({
    String summary =
        'Nabi đang dùng các chỉ số đã tính trong ứng dụng. Phân tích AI chưa sẵn sàng nên sẽ không suy đoán thêm.',
    List<String> missingData = const [],
  }) {
    return NutritionAiReport(
      summary: summary,
      insights: const [],
      todayActions: const [],
      weeklyActions: const [],
      missingData: List.unmodifiable(missingData),
      safetyFlags: const [],
      confidence: 'thấp',
      generatedByAi: false,
    );
  }
}

Object? _rounded(double? value) {
  if (value == null || !value.isFinite) return null;
  final rounded = double.parse(value.toStringAsFixed(2));
  return rounded == rounded.roundToDouble() ? rounded.toInt() : rounded;
}

String? _textOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _dateKey(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
