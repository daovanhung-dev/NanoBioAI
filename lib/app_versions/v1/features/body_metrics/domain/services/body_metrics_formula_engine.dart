import 'dart:math' as math;

import '../entities/basic_health_calculator_models.dart';
import '../entities/body_metrics_health_metric.dart';
import '../entities/body_metrics_health_report.dart';
import '../entities/body_metrics_health_snapshot.dart';
import '../entities/body_metrics_trend.dart';
import 'body_metrics_data_quality_calculator.dart';
import 'body_metrics_formula_registry.dart';
import 'body_metrics_trend_calculator.dart';

class BodyMetricsFormulaEngine {
  const BodyMetricsFormulaEngine._();

  static BodyMetricsHealthReport calculate(BodyMetricsHealthSnapshot snapshot) {
    final metrics = <BodyMetricsHealthMetric>[];
    final trends = <String, BodyMetricsTrend>{};
    final quality = BodyMetricsDataQualityCalculator.calculate(snapshot);
    final currentWeight = snapshot.currentWeightKg;
    final heightM = snapshot.heightCm == null ? null : snapshot.heightCm! / 100;

    final weight7 = _trackingSamples(snapshot.trackingWithinDays(7), (row) => row.weightKg);
    final weight30 = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.weightKg);
    final weightTrend7 = BodyMetricsTrendCalculator.calculate(weight7);
    final weightTrend30 = BodyMetricsTrendCalculator.calculate(weight30);
    trends['weight.7d'] = weightTrend7;
    trends['weight.30d'] = weightTrend30;

    final bmi = currentWeight != null && heightM != null && heightM > 0
        ? currentWeight / math.pow(heightM, 2).toDouble()
        : null;
    final healthyLower = heightM == null ? null : 18.5 * math.pow(heightM, 2).toDouble();
    final healthyUpper = heightM == null ? null : 24.9 * math.pow(heightM, 2).toDouble();
    final distanceToHealthy = currentWeight == null || healthyLower == null || healthyUpper == null
        ? null
        : currentWeight < healthyLower
            ? currentWeight - healthyLower
            : currentWeight > healthyUpper
                ? currentWeight - healthyUpper
                : 0.0;

    _metric(metrics, BodyMetricsMetricIds.bmi, BodyMetricsMetricCategory.body, 'BMI', bmi, 'kg/m²',
        text: bmi == null ? null : _bmiCategory(bmi), reference: 'Adult wellness screening reference; not a diagnosis');
    _metric(metrics, BodyMetricsMetricIds.bmiCategory, BodyMetricsMetricCategory.body, 'Nhóm BMI', null, '',
        text: bmi == null ? null : _bmiCategory(bmi));
    _metric(metrics, BodyMetricsMetricIds.healthyWeightLower, BodyMetricsMetricCategory.body, 'Cận dưới khoảng cân nặng tham khảo', healthyLower, 'kg');
    _metric(metrics, BodyMetricsMetricIds.healthyWeightUpper, BodyMetricsMetricCategory.body, 'Cận trên khoảng cân nặng tham khảo', healthyUpper, 'kg');
    _metric(metrics, BodyMetricsMetricIds.distanceHealthyRange, BodyMetricsMetricCategory.body, 'Khoảng cách tới vùng cân nặng tham khảo', distanceToHealthy, 'kg');
    _metric(metrics, BodyMetricsMetricIds.weightChange7d, BodyMetricsMetricCategory.body, 'Thay đổi cân nặng 7 ngày', weightTrend7.delta, 'kg', window: '7d');
    _metric(metrics, BodyMetricsMetricIds.weightChange30d, BodyMetricsMetricCategory.body, 'Thay đổi cân nặng 30 ngày', weightTrend30.delta, 'kg', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.weightChangePercent, BodyMetricsMetricCategory.body, 'Thay đổi cân nặng', weightTrend30.deltaPercentage, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.weightTrendSlope, BodyMetricsMetricCategory.body, 'Độ dốc xu hướng cân nặng', weightTrend30.slope, 'kg/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.weightVariability, BodyMetricsMetricCategory.body, 'Độ dao động cân nặng', weightTrend30.standardDeviation, 'kg', window: '30d');

    final ree = _mifflin(snapshot, currentWeight);
    final eer = _eer(snapshot, currentWeight, heightM);
    final tdee = ree == null || snapshot.activityLevel == null ? null : ree * snapshot.activityLevel!.multiplier;
    final nutrition7 = snapshot.nutritionWithinDays(7);
    final nutrition30 = snapshot.nutritionWithinDays(30);
    final energy7 = _nutritionAverage(nutrition7, (row) => row.calories);
    final energy30 = _nutritionAverage(nutrition30, (row) => row.calories);
    final energyGap = energy30 == null || tdee == null ? null : energy30 - tdee;
    final energyAlignment = energy30 == null || tdee == null || tdee == 0 ? null : energy30 / tdee * 100;

    _metric(metrics, BodyMetricsMetricIds.restingEnergy, BodyMetricsMetricCategory.energy, 'Năng lượng nghỉ Mifflin', ree, 'kcal/ngày');
    _metric(metrics, BodyMetricsMetricIds.eer, BodyMetricsMetricCategory.energy, 'Nhu cầu năng lượng ước tính EER', eer, 'kcal/ngày');
    _metric(metrics, BodyMetricsMetricIds.tdee, BodyMetricsMetricCategory.energy, 'TDEE theo mức vận động', tdee, 'kcal/ngày');
    _metric(metrics, BodyMetricsMetricIds.plannedCalories, BodyMetricsMetricCategory.energy, 'Năng lượng thực đơn trung bình', energy30, 'kcal/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.energyGap, BodyMetricsMetricCategory.energy, 'Chênh lệch năng lượng', energyGap, 'kcal/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.energyAlignment, BodyMetricsMetricCategory.energy, 'Mức khớp năng lượng', energyAlignment, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.energyAverage7d, BodyMetricsMetricCategory.energy, 'Năng lượng trung bình 7 ngày', energy7, 'kcal/ngày', window: '7d');
    _metric(metrics, BodyMetricsMetricIds.energyAverage30d, BodyMetricsMetricCategory.energy, 'Năng lượng trung bình 30 ngày', energy30, 'kcal/ngày', window: '30d');

    final protein = _nutritionAverage(nutrition30, (row) => row.proteinG);
    final carbs = _nutritionAverage(nutrition30, (row) => row.carbsG);
    final fat = _nutritionAverage(nutrition30, (row) => row.fatG);
    final fiber = _nutritionAverage(nutrition30, (row) => row.fiberG);
    final sodium = _nutritionAverage(nutrition30, (row) => row.sodiumMg);
    final potassium = _nutritionAverage(nutrition30, (row) => row.potassiumMg);
    final calcium = _nutritionAverage(nutrition30, (row) => row.calciumMg);
    final iron = _nutritionAverage(nutrition30, (row) => row.ironMg);
    final sugar = _nutritionAverage(nutrition30, (row) => row.sugarG);
    final saturatedFat = _nutritionAverage(nutrition30, (row) => row.saturatedFatG);
    final macroCalories = protein == null || carbs == null || fat == null ? null : protein * 4 + carbs * 4 + fat * 9;
    final proteinPct = macroCalories == null || macroCalories == 0 || protein == null ? null : protein * 4 / macroCalories * 100;
    final carbPct = macroCalories == null || macroCalories == 0 || carbs == null ? null : carbs * 4 / macroCalories * 100;
    final fatPct = macroCalories == null || macroCalories == 0 || fat == null ? null : fat * 9 / macroCalories * 100;
    final reconciliation = energy30 == null || energy30 == 0 || macroCalories == null ? null : (macroCalories - energy30).abs() / energy30 * 100;
    final macroBalanceCount = proteinPct == null || carbPct == null || fatPct == null
        ? null
        : ((proteinPct >= 10 && proteinPct <= 35 ? 1 : 0) +
                (carbPct >= 45 && carbPct <= 65 ? 1 : 0) +
                (fatPct >= 20 && fatPct <= 35 ? 1 : 0))
            .toDouble();
    final fiberDensity = fiber == null || energy30 == null || energy30 == 0 ? null : fiber / energy30 * 1000;
    final fiberTarget = energy30 == null ? null : energy30 / 1000 * 14;
    final fiberCoverage = fiber == null || fiberTarget == null || fiberTarget == 0 ? null : fiber / fiberTarget * 100;
    final sodiumRatio = sodium == null ? null : sodium / 2300 * 100;

    _metric(metrics, BodyMetricsMetricIds.proteinPerDay, BodyMetricsMetricCategory.nutrition, 'Protein trung bình', protein, 'g/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.proteinPerKg, BodyMetricsMetricCategory.nutrition, 'Protein theo cân nặng', protein == null || currentWeight == null || currentWeight == 0 ? null : protein / currentWeight, 'g/kg', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.proteinEnergyPercent, BodyMetricsMetricCategory.nutrition, 'Tỷ lệ năng lượng từ protein', proteinPct, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.carbEnergyPercent, BodyMetricsMetricCategory.nutrition, 'Tỷ lệ năng lượng từ carbohydrate', carbPct, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.fatEnergyPercent, BodyMetricsMetricCategory.nutrition, 'Tỷ lệ năng lượng từ chất béo', fatPct, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.macroCalories, BodyMetricsMetricCategory.nutrition, 'Năng lượng tính từ macro', macroCalories, 'kcal/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.calorieReconciliationError, BodyMetricsMetricCategory.nutrition, 'Sai lệch đối chiếu calories', reconciliation, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.macroBalanceCount, BodyMetricsMetricCategory.nutrition, 'Số nhóm macro trong khoảng tham khảo', macroBalanceCount, '/3', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.fiberDensity, BodyMetricsMetricCategory.nutrition, 'Mật độ chất xơ', fiberDensity, 'g/1000kcal', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.fiberReferenceTarget, BodyMetricsMetricCategory.nutrition, 'Mục tham khảo chất xơ', fiberTarget, 'g/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.fiberCoverage, BodyMetricsMetricCategory.nutrition, 'Mức phủ chất xơ', fiberCoverage, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.sodiumRatio, BodyMetricsMetricCategory.nutrition, 'Tỷ lệ sodium so với mốc tham khảo', sodiumRatio, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.potassiumAverage, BodyMetricsMetricCategory.nutrition, 'Potassium trung bình', potassium, 'mg/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.calciumAverage, BodyMetricsMetricCategory.nutrition, 'Calcium trung bình', calcium, 'mg/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.ironAverage, BodyMetricsMetricCategory.nutrition, 'Iron trung bình', iron, 'mg/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.sugarAverage, BodyMetricsMetricCategory.nutrition, 'Đường trung bình', sugar, 'g/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.saturatedFatAverage, BodyMetricsMetricCategory.nutrition, 'Chất béo bão hòa trung bình', saturatedFat, 'g/ngày', window: '30d');

    final water7Samples = _trackingSamples(snapshot.trackingWithinDays(7), (row) => row.waterMl);
    final water30Samples = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.waterMl);
    final waterTrend = BodyMetricsTrendCalculator.calculate(water30Samples);
    trends['water.30d'] = waterTrend;
    _metric(metrics, BodyMetricsMetricIds.waterAverage7d, BodyMetricsMetricCategory.hydration, 'Nước trung bình 7 ngày', _sampleAverage(water7Samples), 'ml/ngày', window: '7d');
    _metric(metrics, BodyMetricsMetricIds.waterAverage30d, BodyMetricsMetricCategory.hydration, 'Nước trung bình 30 ngày', _sampleAverage(water30Samples), 'ml/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.waterLoggingConsistency, BodyMetricsMetricCategory.hydration, 'Mức đều đặn ghi nước', water30Samples.isEmpty ? null : (water30Samples.length / 30 * 100).clamp(0.0, 100.0).toDouble(), '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.waterTrend, BodyMetricsMetricCategory.hydration, 'Xu hướng lượng nước', waterTrend.slope, 'ml/ngày', window: '30d', text: _directionLabel(waterTrend.direction));

    final sleep7Samples = _trackingSamples(snapshot.trackingWithinDays(7), (row) => row.sleepHours);
    final sleep30Samples = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.sleepHours);
    final sleepTrend = BodyMetricsTrendCalculator.calculate(sleep30Samples);
    trends['sleep.30d'] = sleepTrend;
    final adequateSleepCount = sleep30Samples.where((sample) => sample.value >= 7 && sample.value <= 9).length;
    final sleepAdequacy = sleep30Samples.isEmpty ? null : adequateSleepCount / sleep30Samples.length * 100;
    final stressSamples = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.stressLevel);
    final stressTrend = BodyMetricsTrendCalculator.calculate(stressSamples);
    trends['stress.30d'] = stressTrend;
    final mood = _dominantMood(snapshot.trackingWithinDays(30));

    _metric(metrics, BodyMetricsMetricIds.sleepAverage7d, BodyMetricsMetricCategory.recovery, 'Giấc ngủ trung bình 7 ngày', _sampleAverage(sleep7Samples), 'giờ', window: '7d');
    _metric(metrics, BodyMetricsMetricIds.sleepAverage30d, BodyMetricsMetricCategory.recovery, 'Giấc ngủ trung bình 30 ngày', _sampleAverage(sleep30Samples), 'giờ', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.sleepAdequacy, BodyMetricsMetricCategory.recovery, 'Tỷ lệ đêm trong khoảng ngủ tham khảo', sleepAdequacy, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.sleepVariability, BodyMetricsMetricCategory.recovery, 'Độ dao động thời lượng ngủ', sleepTrend.standardDeviation, 'giờ', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.stressAverage, BodyMetricsMetricCategory.recovery, 'Stress trung bình', _sampleAverage(stressSamples), 'điểm', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.stressTrend, BodyMetricsMetricCategory.recovery, 'Xu hướng stress', stressTrend.slope, 'điểm/ngày', window: '30d', text: _directionLabel(stressTrend.direction));
    _metric(metrics, BodyMetricsMetricIds.moodDistribution, BodyMetricsMetricCategory.recovery, 'Cảm xúc xuất hiện nhiều nhất', null, '', window: '30d', text: mood);

    final stepsSamples = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.steps);
    final stepsTrend = BodyMetricsTrendCalculator.calculate(stepsSamples);
    trends['steps.30d'] = stepsTrend;
    final maxHr = snapshot.ageYears == null ? null : 220.0 - snapshot.ageYears!;
    _metric(metrics, BodyMetricsMetricIds.stepsAverage, BodyMetricsMetricCategory.activity, 'Số bước trung bình', _sampleAverage(stepsSamples), 'bước/ngày', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.stepsTrend, BodyMetricsMetricCategory.activity, 'Xu hướng số bước', stepsTrend.slope, 'bước/ngày', window: '30d', text: _directionLabel(stepsTrend.direction));
    _metric(metrics, BodyMetricsMetricIds.estimatedMaxHr, BodyMetricsMetricCategory.activity, 'Nhịp tim tối đa ước tính', maxHr, 'bpm', reference: 'Ước tính theo tuổi, không phải giới hạn y khoa');
    _metric(metrics, BodyMetricsMetricIds.moderateHrZone, BodyMetricsMetricCategory.activity, 'Vùng nhịp tim vận động vừa ước tính', null, 'bpm',
        text: maxHr == null ? null : '${(maxHr * .50).round()}–${(maxHr * .70).round()}', reference: 'Observation/wellness estimate only');
    _metric(metrics, BodyMetricsMetricIds.vigorousHrZone, BodyMetricsMetricCategory.activity, 'Vùng nhịp tim vận động mạnh ước tính', null, 'bpm',
        text: maxHr == null ? null : '${(maxHr * .70).round()}–${(maxHr * .85).round()}', reference: 'Observation/wellness estimate only');

    final hrSamples = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.heartRateBpm);
    final spo2Samples = _trackingSamples(snapshot.trackingWithinDays(30), (row) => row.oxygenSaturation);
    _metric(metrics, BodyMetricsMetricIds.latestHeartRate, BodyMetricsMetricCategory.observation, 'Nhịp tim ghi nhận gần nhất', hrSamples.isEmpty ? null : hrSamples.first.value, 'bpm', window: 'latest', reference: 'User-recorded observation only; no clinical classification');
    _metric(metrics, BodyMetricsMetricIds.averageHeartRate30d, BodyMetricsMetricCategory.observation, 'Nhịp tim trung bình ghi nhận', _sampleAverage(hrSamples), 'bpm', window: '30d', reference: 'User-recorded observation aggregate; no clinical classification');
    _metric(metrics, BodyMetricsMetricIds.latestSpO2, BodyMetricsMetricCategory.observation, 'SpO₂ ghi nhận gần nhất', spo2Samples.isEmpty ? null : spo2Samples.first.value, '%', window: 'latest', reference: 'User-recorded observation only; no clinical classification');
    _metric(metrics, BodyMetricsMetricIds.averageSpO230d, BodyMetricsMetricCategory.observation, 'SpO₂ trung bình ghi nhận', _sampleAverage(spo2Samples), '%', window: '30d', reference: 'User-recorded observation aggregate; no clinical classification');
    _metric(metrics, BodyMetricsMetricIds.bloodPressureObservation, BodyMetricsMetricCategory.observation, 'Huyết áp đã ghi trong hồ sơ', null, '', text: snapshot.bloodPressure, reference: 'Profile observation only; no clinical classification');
    _metric(metrics, BodyMetricsMetricIds.bloodSugarObservation, BodyMetricsMetricCategory.observation, 'Đường huyết đã ghi trong hồ sơ', null, '', text: snapshot.bloodSugar, reference: 'Profile observation only; no clinical classification');

    final mealCompletion = nutrition30.isEmpty
        ? null
        : nutrition30.map((row) => row.mealCompletionRate).reduce((a, b) => a + b) / nutrition30.length * 100;
    final scheduleCompletion = snapshot.schedule.completionRate == null ? null : snapshot.schedule.completionRate! * 100;
    _metric(metrics, BodyMetricsMetricIds.mealCompletion, BodyMetricsMetricCategory.adherence, 'Mức hoàn thành thực đơn', mealCompletion, '%', window: '30d');
    _metric(metrics, BodyMetricsMetricIds.scheduleCompletion, BodyMetricsMetricCategory.adherence, 'Mức hoàn thành lịch chăm sóc', scheduleCompletion, '%', window: '30d');
    final freshness = _overallFreshness(quality.freshnessByGroup.values, snapshot.generatedAt);
    _metric(metrics, BodyMetricsMetricIds.dataCompletenessFreshness, BodyMetricsMetricCategory.dataQuality, 'Độ đầy đủ dữ liệu', quality.completeness * 100, '%', text: freshness, reference: 'Data quality score; not a health score');

    assert(metrics.length == BodyMetricsMetricIds.all.length);
    return BodyMetricsHealthReport(
      metrics: metrics,
      trends: trends,
      freshnessByGroup: quality.freshnessByGroup,
      dataCompleteness: quality.completeness,
      dataGaps: quality.gaps,
      generatedAt: snapshot.generatedAt,
    );
  }

  static void _metric(
    List<BodyMetricsHealthMetric> target,
    String id,
    BodyMetricsMetricCategory category,
    String title,
    double? value,
    String unit, {
    String? text,
    String window = 'current',
    String? reference,
  }) {
    final definition = BodyMetricsFormulaRegistry.definition(id);
    target.add(BodyMetricsHealthMetric(
      id: id,
      category: category,
      title: title,
      value: value?.isFinite == true ? value : null,
      textValue: text,
      unit: unit,
      status: value == null && (text == null || text.isEmpty)
          ? BodyMetricsMetricStatus.insufficientData
          : BodyMetricsMetricStatus.info,
      source: category == BodyMetricsMetricCategory.observation
          ? BodyMetricsMetricSource.observation
          : BodyMetricsMetricSource.calculated,
      formulaVersion: definition.version,
      reference: reference ?? definition.reference,
      dataWindow: window,
      confidence: value == null && text == null ? 0 : 1,
    ));
  }

  static List<BodyMetricsTrendSample> _trackingSamples(
    List<BodyMetricsTrackingPoint> rows,
    double? Function(BodyMetricsTrackingPoint row) selector,
  ) {
    return rows
        .map((row) => MapEntry(row.date, selector(row)))
        .where((entry) => entry.value != null && entry.value!.isFinite)
        .map((entry) => BodyMetricsTrendSample(entry.key, entry.value!))
        .toList(growable: false);
  }

  static double? _sampleAverage(List<BodyMetricsTrendSample> samples) {
    if (samples.isEmpty) return null;
    return samples.map((sample) => sample.value).reduce((a, b) => a + b) / samples.length;
  }

  static double? _nutritionAverage(
    List<BodyMetricsNutritionDay> rows,
    double? Function(BodyMetricsNutritionDay row) selector,
  ) {
    final values = rows.map(selector).whereType<double>().where((value) => value.isFinite).toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _mifflin(BodyMetricsHealthSnapshot snapshot, double? weightKg) {
    if (weightKg == null || snapshot.heightCm == null || snapshot.ageYears == null || snapshot.sex == null) {
      return null;
    }
    final sexOffset = snapshot.sex == BasicHealthSex.male ? 5.0 : -161.0;
    return 10 * weightKg + 6.25 * snapshot.heightCm! - 5 * snapshot.ageYears! + sexOffset;
  }

  static double? _eer(BodyMetricsHealthSnapshot snapshot, double? weightKg, double? heightM) {
    if (weightKg == null || heightM == null || snapshot.ageYears == null || snapshot.sex == null || snapshot.activityLevel == null) {
      return null;
    }
    final age = snapshot.ageYears!.toDouble();
    if (snapshot.sex == BasicHealthSex.male) {
      final pa = switch (snapshot.activityLevel!) {
        BasicHealthActivityLevel.sedentary => 1.0,
        BasicHealthActivityLevel.light => 1.11,
        BasicHealthActivityLevel.moderate => 1.25,
        BasicHealthActivityLevel.active => 1.48,
      };
      return 662 - 9.53 * age + pa * (15.91 * weightKg + 539.6 * heightM);
    }
    final pa = switch (snapshot.activityLevel!) {
      BasicHealthActivityLevel.sedentary => 1.0,
      BasicHealthActivityLevel.light => 1.12,
      BasicHealthActivityLevel.moderate => 1.27,
      BasicHealthActivityLevel.active => 1.45,
    };
    return 354 - 6.91 * age + pa * (9.36 * weightKg + 726 * heightM);
  }

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'thấp hơn khoảng tham khảo';
    if (bmi < 25) return 'trong khoảng tham khảo';
    if (bmi < 30) return 'cao hơn khoảng tham khảo';
    return 'cao đáng kể so với khoảng tham khảo';
  }

  static String? _dominantMood(List<BodyMetricsTrackingPoint> rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final mood = row.mood?.trim();
      if (mood == null || mood.isEmpty) continue;
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static String? _directionLabel(BodyMetricsTrendDirection direction) => switch (direction) {
        BodyMetricsTrendDirection.increasing => 'tăng',
        BodyMetricsTrendDirection.decreasing => 'giảm',
        BodyMetricsTrendDirection.stable => 'ổn định',
        BodyMetricsTrendDirection.insufficientData => null,
      };

  static String _overallFreshness(Iterable<DateTime?> values, DateTime now) {
    final dates = values.whereType<DateTime>().toList();
    if (dates.isEmpty) return 'Chưa có';
    dates.sort();
    final days = now.difference(dates.last).inDays;
    if (days <= 1) return 'Mới cập nhật';
    if (days <= 7) return 'Khá mới';
    return 'Đã cũ';
  }
}
