import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/basic_health_calculator_models.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_metric.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_snapshot.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/services/body_metrics_formula_engine.dart';

void main() {
  test('emits the complete metric registry and keeps numeric truth deterministic', () {
    final now = DateTime(2026, 8, 18);
    final snapshot = BodyMetricsHealthSnapshot(
      userId: 'current-user',
      heightCm: 178,
      profileWeightKg: 75,
      ageYears: 20,
      sex: BasicHealthSex.male,
      lifestyle: const BodyMetricsLifestyleContext(
        activityLevel: BasicHealthActivityLevel.moderate,
      ),
      tracking: List.generate(
        10,
        (index) => BodyMetricsTrackingPoint(
          date: now.subtract(Duration(days: index)),
          weightKg: 75 - index * .1,
          waterMl: 1800 + index * 10,
          sleepHours: 7.5,
          stressLevel: 3,
          steps: 6000 + index * 100,
          heartRateBpm: 72,
          oxygenSaturation: 98,
          mood: 'ổn',
        ),
      ),
      nutrition: List.generate(
        7,
        (index) => BodyMetricsNutritionDay(
          date: now.subtract(Duration(days: index)),
          calories: 2100,
          proteinG: 100,
          carbsG: 250,
          fatG: 70,
          fiberG: 28,
          sodiumMg: 1900,
          potassiumMg: 3000,
          calciumMg: 900,
          ironMg: 12,
          sugarG: 40,
          saturatedFatG: 18,
          mealCompletionRate: .8,
          mealCount: 3,
        ),
      ),
      declaredConditions: const [],
      allergies: const [],
      treatments: const [],
      activeGoals: const [],
      schedule: const BodyMetricsScheduleSummary(
        plannedTaskCount: 10,
        completedTaskCount: 8,
      ),
      generatedAt: now,
    );

    final report = BodyMetricsFormulaEngine.calculate(snapshot);
    expect(report.metrics.length, BodyMetricsMetricIds.all.length);
    expect(report.metrics.length, greaterThan(50));
    expect(report.metric(BodyMetricsMetricIds.bmi)?.value, closeTo(23.67, .1));
    expect(report.metric(BodyMetricsMetricIds.latestSpO2)?.value, 98);
    expect(report.metric(BodyMetricsMetricIds.dataCompletenessFreshness)?.reference,
        contains('not a health score'));
  });

  test('missing input is represented as insufficientData instead of zero', () {
    final snapshot = BodyMetricsHealthSnapshot(
      userId: 'current-user',
      tracking: const [],
      nutrition: const [],
      declaredConditions: const [],
      allergies: const [],
      treatments: const [],
      activeGoals: const [],
      schedule: const BodyMetricsScheduleSummary(),
      generatedAt: DateTime(2026, 8, 18),
    );
    final report = BodyMetricsFormulaEngine.calculate(snapshot);
    final bmi = report.metric(BodyMetricsMetricIds.bmi)!;
    expect(bmi.value, isNull);
    expect(bmi.status, BodyMetricsMetricStatus.insufficientData);
  });
}
