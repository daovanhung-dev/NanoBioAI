import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/core/storage/localdb/models/health_profile_model.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';

import '../domain/entities/nutrition_intelligence_entity.dart';

/// Pure, deterministic nutrition calculations.
///
/// This layer never asks AI to create a number. It only totals values already
/// persisted by the app and compares consumed values with the user's generated
/// meal plan. Missing micronutrients remain null instead of being silently
/// treated as zero.
class NutritionMetricsEngine {
  const NutritionMetricsEngine();

  NutritionIntelligence analyze({
    required DateTime selectedDate,
    required List<NutritionLogModel> allLogs,
    required List<MealPlanModel> allMeals,
    required List<HealthTrackingLogModel> healthHistory,
    HealthProfileModel? healthProfile,
    bool hasProfileContext = false,
  }) {
    final date = _day(selectedDate);
    final todayLogs = allLogs
        .where((item) => _sameDay(_parseDate(item.eatenAt), date))
        .toList(growable: false);
    final todayMeals = allMeals
        .where((item) => _sameDay(_parseDate(item.planDate), date))
        .toList(growable: false);

    final actual = _totalsFromLogs(todayLogs);
    final planned = _totalsFromMeals(todayMeals);
    final coverage = _coverageMetrics(
      logs: todayLogs,
      actual: actual,
      planned: planned,
    );
    final sevenDayTrend = _buildTrend(
      endDate: date,
      days: 7,
      logs: allLogs,
    );
    final thirtyDayTrend = _buildTrend(
      endDate: date,
      days: 30,
      logs: allLogs,
    );
    final healthContext = _buildHealthContext(
      selectedDate: date,
      healthProfile: healthProfile,
      healthHistory: healthHistory,
    );
    final quality = _buildDataQuality(
      logs: todayLogs,
      meals: todayMeals,
      sevenDayTrend: sevenDayTrend,
      thirtyDayTrend: thirtyDayTrend,
      healthContext: healthContext,
      hasProfileContext: hasProfileContext,
    );

    return NutritionIntelligence(
      selectedDate: date,
      actual: actual,
      planned: planned,
      coverage: coverage,
      mealDistribution: _mealDistribution(todayLogs),
      sevenDayTrend: sevenDayTrend,
      thirtyDayTrend: thirtyDayTrend,
      healthContext: healthContext,
      dataQuality: quality,
      loggedItems: todayLogs.length,
      plannedMeals: todayMeals.length,
    );
  }

  NutritionNutrientTotals _totalsFromLogs(List<NutritionLogModel> logs) {
    return NutritionNutrientTotals(
      energyKcal: _sumKnown(
        logs.map((item) => item.calories?.toDouble() ?? _nutrient(item, const ['energy_kcal', 'calories', 'kcal'])),
      ),
      proteinG: _sumKnown(
        logs.map((item) => item.protein ?? _nutrient(item, const ['protein_g', 'protein'])),
      ),
      carbsG: _sumKnown(
        logs.map((item) => item.carbs ?? _nutrient(item, const ['carbs_g', 'carbohydrate_g', 'carbs', 'carbohydrates'])),
      ),
      fatG: _sumKnown(
        logs.map((item) => item.fat ?? _nutrient(item, const ['fat_g', 'total_fat_g', 'fat'])),
      ),
      fiberG: _sumKnown(
        logs.map((item) => _nutrient(item, const ['fiber_g', 'fibre_g', 'fiber', 'fibre'])),
      ),
      sugarG: _sumKnown(
        logs.map((item) => _nutrient(item, const ['sugar_g', 'total_sugar_g', 'sugar', 'sugars'])),
      ),
      saturatedFatG: _sumKnown(
        logs.map((item) => _nutrient(item, const ['saturated_fat_g', 'sat_fat_g', 'saturated_fat'])),
      ),
      sodiumMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['sodium_mg', 'sodium'])),
      ),
      potassiumMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['potassium_mg', 'potassium'])),
      ),
      calciumMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['calcium_mg', 'calcium'])),
      ),
      ironMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['iron_mg', 'iron'])),
      ),
      cholesterolMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['cholesterol_mg', 'cholesterol'])),
      ),
      magnesiumMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['magnesium_mg', 'magnesium'])),
      ),
      zincMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['zinc_mg', 'zinc'])),
      ),
      vitaminAMcg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['vitamin_a_mcg', 'vitamin_a_ug', 'vitamin_a_mcg_rae', 'vitamin_a'])),
      ),
      vitaminCMg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['vitamin_c_mg', 'vitamin_c'])),
      ),
      vitaminDMcg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['vitamin_d_mcg', 'vitamin_d_ug', 'vitamin_d'])),
      ),
      vitaminB12Mcg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['vitamin_b12_mcg', 'vitamin_b12_ug', 'vitamin_b12'])),
      ),
      folateMcg: _sumKnown(
        logs.map((item) => _nutrient(item, const ['folate_mcg', 'folate_ug', 'folate_b9_mcg', 'folate'])),
      ),
    );
  }

  NutritionNutrientTotals _totalsFromMeals(List<MealPlanModel> meals) {
    if (meals.isEmpty) return const NutritionNutrientTotals();
    return NutritionNutrientTotals(
      energyKcal: meals.fold<double>(0, (sum, item) => sum + item.calories),
      proteinG: meals.fold<double>(0, (sum, item) => sum + item.protein),
      carbsG: meals.fold<double>(0, (sum, item) => sum + item.carbs),
      fatG: meals.fold<double>(0, (sum, item) => sum + item.fat),
      fiberG: meals.fold<double>(0, (sum, item) => sum + item.fiber),
      sugarG: _sumKnown(meals.map((item) => item.sugarG)),
      saturatedFatG: _sumKnown(meals.map((item) => item.saturatedFatG)),
      sodiumMg: _sumKnown(meals.map((item) => item.sodiumMg)),
      potassiumMg: _sumKnown(meals.map((item) => item.potassiumMg)),
      calciumMg: _sumKnown(meals.map((item) => item.calciumMg)),
      ironMg: _sumKnown(meals.map((item) => item.ironMg)),
      cholesterolMg: _sumKnown(meals.map((item) => item.cholesterolMg)),
    );
  }

  List<NutritionCoverageMetric> _coverageMetrics({
    required List<NutritionLogModel> logs,
    required NutritionNutrientTotals actual,
    required NutritionNutrientTotals planned,
  }) {
    final totalLogs = logs.length;
    double coverageFor(List<String> aliases, {String? legacy}) {
      if (totalLogs == 0) return 0;
      var known = 0;
      for (final log in logs) {
        final legacyValue = switch (legacy) {
          'calories' => log.calories?.toDouble(),
          'protein' => log.protein,
          'carbs' => log.carbs,
          'fat' => log.fat,
          _ => null,
        };
        if (legacyValue != null || _nutrient(log, aliases) != null) known++;
      }
      return known / totalLogs;
    }

    NutritionCoverageMetric metric({
      required String code,
      required String label,
      required String unit,
      required double? consumed,
      required double? target,
      required double dataCoverage,
    }) {
      return NutritionCoverageMetric(
        code: code,
        label: label,
        unit: unit,
        actual: consumed,
        planned: target,
        status: _coverageStatus(consumed, target, dataCoverage),
        dataCoverage: dataCoverage,
      );
    }

    return [
      metric(
        code: 'energy',
        label: 'Năng lượng',
        unit: 'kcal',
        consumed: actual.energyKcal,
        target: planned.energyKcal,
        dataCoverage: coverageFor(const ['energy_kcal', 'calories', 'kcal'], legacy: 'calories'),
      ),
      metric(
        code: 'protein',
        label: 'Protein',
        unit: 'g',
        consumed: actual.proteinG,
        target: planned.proteinG,
        dataCoverage: coverageFor(const ['protein_g', 'protein'], legacy: 'protein'),
      ),
      metric(
        code: 'carbs',
        label: 'Carbohydrate',
        unit: 'g',
        consumed: actual.carbsG,
        target: planned.carbsG,
        dataCoverage: coverageFor(const ['carbs_g', 'carbohydrate_g', 'carbs'], legacy: 'carbs'),
      ),
      metric(
        code: 'fat',
        label: 'Chất béo',
        unit: 'g',
        consumed: actual.fatG,
        target: planned.fatG,
        dataCoverage: coverageFor(const ['fat_g', 'total_fat_g', 'fat'], legacy: 'fat'),
      ),
      metric(
        code: 'fiber',
        label: 'Chất xơ',
        unit: 'g',
        consumed: actual.fiberG,
        target: planned.fiberG,
        dataCoverage: coverageFor(const ['fiber_g', 'fibre_g', 'fiber', 'fibre']),
      ),
      metric(
        code: 'sodium',
        label: 'Natri',
        unit: 'mg',
        consumed: actual.sodiumMg,
        target: planned.sodiumMg,
        dataCoverage: coverageFor(const ['sodium_mg', 'sodium']),
      ),
      metric(
        code: 'potassium',
        label: 'Kali',
        unit: 'mg',
        consumed: actual.potassiumMg,
        target: planned.potassiumMg,
        dataCoverage: coverageFor(const ['potassium_mg', 'potassium']),
      ),
      metric(
        code: 'calcium',
        label: 'Canxi',
        unit: 'mg',
        consumed: actual.calciumMg,
        target: planned.calciumMg,
        dataCoverage: coverageFor(const ['calcium_mg', 'calcium']),
      ),
      metric(
        code: 'iron',
        label: 'Sắt',
        unit: 'mg',
        consumed: actual.ironMg,
        target: planned.ironMg,
        dataCoverage: coverageFor(const ['iron_mg', 'iron']),
      ),
      metric(
        code: 'sugar',
        label: 'Đường',
        unit: 'g',
        consumed: actual.sugarG,
        target: planned.sugarG,
        dataCoverage: coverageFor(
          const ['sugar_g', 'total_sugar_g', 'sugar', 'sugars'],
        ),
      ),
      metric(
        code: 'saturated_fat',
        label: 'Chất béo bão hòa',
        unit: 'g',
        consumed: actual.saturatedFatG,
        target: planned.saturatedFatG,
        dataCoverage: coverageFor(
          const ['saturated_fat_g', 'sat_fat_g', 'saturated_fat'],
        ),
      ),
      metric(
        code: 'cholesterol',
        label: 'Cholesterol',
        unit: 'mg',
        consumed: actual.cholesterolMg,
        target: planned.cholesterolMg,
        dataCoverage: coverageFor(const ['cholesterol_mg', 'cholesterol']),
      ),
      metric(
        code: 'magnesium',
        label: 'Magie',
        unit: 'mg',
        consumed: actual.magnesiumMg,
        target: planned.magnesiumMg,
        dataCoverage: coverageFor(const ['magnesium_mg', 'magnesium']),
      ),
      metric(
        code: 'zinc',
        label: 'Kẽm',
        unit: 'mg',
        consumed: actual.zincMg,
        target: planned.zincMg,
        dataCoverage: coverageFor(const ['zinc_mg', 'zinc']),
      ),
      metric(
        code: 'vitamin_a',
        label: 'Vitamin A',
        unit: 'mcg',
        consumed: actual.vitaminAMcg,
        target: planned.vitaminAMcg,
        dataCoverage: coverageFor(
          const [
            'vitamin_a_mcg',
            'vitamin_a_ug',
            'vitamin_a_mcg_rae',
            'vitamin_a',
          ],
        ),
      ),
      metric(
        code: 'vitamin_c',
        label: 'Vitamin C',
        unit: 'mg',
        consumed: actual.vitaminCMg,
        target: planned.vitaminCMg,
        dataCoverage: coverageFor(const ['vitamin_c_mg', 'vitamin_c']),
      ),
      metric(
        code: 'vitamin_d',
        label: 'Vitamin D',
        unit: 'mcg',
        consumed: actual.vitaminDMcg,
        target: planned.vitaminDMcg,
        dataCoverage: coverageFor(
          const ['vitamin_d_mcg', 'vitamin_d_ug', 'vitamin_d'],
        ),
      ),
      metric(
        code: 'vitamin_b12',
        label: 'Vitamin B12',
        unit: 'mcg',
        consumed: actual.vitaminB12Mcg,
        target: planned.vitaminB12Mcg,
        dataCoverage: coverageFor(
          const ['vitamin_b12_mcg', 'vitamin_b12_ug', 'vitamin_b12'],
        ),
      ),
      metric(
        code: 'folate',
        label: 'Folate',
        unit: 'mcg',
        consumed: actual.folateMcg,
        target: planned.folateMcg,
        dataCoverage: coverageFor(
          const ['folate_mcg', 'folate_ug', 'folate_b9_mcg', 'folate'],
        ),
      ),
    ];
  }

  NutritionCoverageStatus _coverageStatus(
    double? actual,
    double? planned,
    double dataCoverage,
  ) {
    if (actual == null || planned == null || planned <= 0 || dataCoverage < .5) {
      return NutritionCoverageStatus.insufficientData;
    }
    final ratio = actual / planned;
    if (ratio < .65) return NutritionCoverageStatus.low;
    if (ratio < .85) return NutritionCoverageStatus.nearPlan;
    if (ratio <= 1.2) return NutritionCoverageStatus.onTrack;
    return NutritionCoverageStatus.abovePlan;
  }

  List<NutritionMealDistribution> _mealDistribution(
    List<NutritionLogModel> logs,
  ) {
    final energyByType = <String, double>{};
    final countByType = <String, int>{};
    for (final log in logs) {
      final type = _normalizeMealType(log.mealType);
      final energy = log.calories?.toDouble() ??
          _nutrient(log, const ['energy_kcal', 'calories', 'kcal']) ??
          0;
      energyByType[type] = (energyByType[type] ?? 0) + energy;
      countByType[type] = (countByType[type] ?? 0) + 1;
    }
    const order = [
      'breakfast',
      'morning_snack',
      'lunch',
      'afternoon_snack',
      'dinner',
      'snack',
      'other',
    ];
    return order
        .where((type) => countByType.containsKey(type))
        .map(
          (type) => NutritionMealDistribution(
            mealType: type,
            energyKcal: energyByType[type] ?? 0,
            loggedItems: countByType[type] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  List<NutritionTrendPoint> _buildTrend({
    required DateTime endDate,
    required int days,
    required List<NutritionLogModel> logs,
  }) {
    final byDate = <String, List<NutritionLogModel>>{};
    for (final log in logs) {
      final parsed = _parseDate(log.eatenAt);
      if (parsed == null) continue;
      byDate.putIfAbsent(_dateKey(parsed), () => []).add(log);
    }
    return List.generate(days, (index) {
      final date = endDate.subtract(Duration(days: days - index - 1));
      final dayLogs = byDate[_dateKey(date)] ?? const <NutritionLogModel>[];
      final totals = _totalsFromLogs(dayLogs);
      return NutritionTrendPoint(
        date: date,
        energyKcal: totals.energyKcal,
        proteinG: totals.proteinG,
        loggedMeals: dayLogs.length,
      );
    });
  }

  NutritionHealthContext _buildHealthContext({
    required DateTime selectedDate,
    required HealthProfileModel? healthProfile,
    required List<HealthTrackingLogModel> healthHistory,
  }) {
    HealthTrackingLogModel? selected;
    for (final item in healthHistory) {
      if (_sameDay(_parseDate(item.logDate), selectedDate)) {
        selected = item;
        break;
      }
    }
    final from = selectedDate.subtract(const Duration(days: 6));
    final recent = healthHistory.where((item) {
      final date = _parseDate(item.logDate);
      if (date == null) return false;
      final normalized = _day(date);
      return !normalized.isBefore(from) && !normalized.isAfter(selectedDate);
    }).toList(growable: false);

    return NutritionHealthContext(
      weightKg: selected?.weightKg ?? healthProfile?.weightKg,
      bmi: healthProfile?.bmi,
      waterMl: selected != null && selected.waterMl > 0 ? selected.waterMl : null,
      sleepHours: selected?.sleepHours,
      stressLevel: selected?.stressLevel,
      stepsCount: selected != null && selected.stepsCount > 0 ? selected.stepsCount : null,
      mood: _nonEmpty(selected?.mood),
      sevenDayAverageWaterMl: _average(
        recent.map((item) => item.waterMl > 0 ? item.waterMl.toDouble() : null),
      ),
      sevenDayAverageSleepHours: _average(
        recent.map((item) => item.sleepHours),
      ),
      sevenDayAverageSteps: _average(
        recent.map((item) => item.stepsCount > 0 ? item.stepsCount.toDouble() : null),
      ),
    );
  }

  NutritionDataQuality _buildDataQuality({
    required List<NutritionLogModel> logs,
    required List<MealPlanModel> meals,
    required List<NutritionTrendPoint> sevenDayTrend,
    required List<NutritionTrendPoint> thirtyDayTrend,
    required NutritionHealthContext healthContext,
    required bool hasProfileContext,
  }) {
    final richRatio = logs.isEmpty
        ? 0.0
        : logs.where((item) => item.nutrition.isNotEmpty).length / logs.length;
    final days7 = sevenDayTrend.where((item) => item.loggedMeals > 0).length;
    final days30 = thirtyDayTrend.where((item) => item.loggedMeals > 0).length;
    var score = 0.0;
    if (logs.isNotEmpty) score += 25;
    if (meals.isNotEmpty) score += 20;
    score += richRatio * 20;
    score += (days7 / 7).clamp(0.0, 1.0).toDouble() * 15;
    if (healthContext.hasAnyValue) score += 10;
    if (hasProfileContext) score += 10;

    final missing = <String>[];
    if (logs.isEmpty) missing.add('Chưa có nhật ký ăn trong ngày đã chọn');
    if (meals.isEmpty) missing.add('Chưa có thực đơn để làm mốc so sánh');
    if (logs.isNotEmpty && richRatio < .5) {
      missing.add('Phần lớn bữa ăn chưa có dữ liệu vi chất');
    }
    if (days7 < 3) missing.add('Lịch sử 7 ngày còn thưa');
    if (!healthContext.hasAnyValue) {
      missing.add('Chưa có dữ liệu nước, ngủ hoặc vận động gần đây');
    }
    if (!hasProfileContext) {
      missing.add('Hồ sơ dinh dưỡng cá nhân chưa đầy đủ');
    }

    final rounded = score.round().clamp(0, 100).toInt();
    final level = rounded >= 80
        ? 'cao'
        : rounded >= 55
            ? 'vừa'
            : 'thấp';
    return NutritionDataQuality(
      score: rounded,
      level: level,
      missingData: List.unmodifiable(missing),
      richNutritionLogRatio: richRatio,
      daysWithLogsInLast7: days7,
      daysWithLogsInLast30: days30,
    );
  }

  double? _nutrient(NutritionLogModel log, List<String> aliases) {
    if (log.nutrition.isEmpty) return null;
    final normalizedAliases = aliases.map(_normalizeKey).toSet();
    Object? search(Object? value) {
      if (value is Map) {
        for (final entry in value.entries) {
          if (normalizedAliases.contains(_normalizeKey(entry.key.toString()))) {
            final parsed = _readDouble(entry.value);
            if (parsed != null) return parsed;
          }
        }
        for (final nestedKey in const [
          'nutrition',
          'nutrients',
          'totals',
          'macros',
          'micronutrients',
          'vitamins',
          'minerals',
        ]) {
          final nested = value.entries
              .where((entry) => _normalizeKey(entry.key.toString()) == nestedKey)
              .map((entry) => entry.value)
              .firstOrNull;
          final found = search(nested);
          if (found != null) return found;
        }
      }
      return null;
    }
    return _readDouble(search(log.nutrition));
  }

  double? _sumKnown(Iterable<double?> values) {
    var hasValue = false;
    var total = 0.0;
    for (final value in values) {
      if (value == null || !value.isFinite) continue;
      hasValue = true;
      total += value;
    }
    return hasValue ? total : null;
  }

  double? _average(Iterable<double?> values) {
    var total = 0.0;
    var count = 0;
    for (final value in values) {
      if (value == null || !value.isFinite) continue;
      total += value;
      count++;
    }
    return count == 0 ? null : total / count;
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  String _normalizeKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  String _normalizeMealType(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'breakfast' || 'morning_snack' || 'lunch' || 'afternoon_snack' ||
      'dinner' || 'snack' => normalized,
      _ => 'other',
    };
  }

  DateTime? _parseDate(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return _day(parsed.toLocal());
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime? left, DateTime right) =>
      left != null &&
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
