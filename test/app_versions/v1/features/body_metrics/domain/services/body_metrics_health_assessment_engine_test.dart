import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_assessment.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_metric.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_report.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_snapshot.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/services/body_metrics_health_assessment_engine.dart';

void main() {
  group('BodyMetricsHealthAssessmentEngine', () {
    test('returns good when evaluable groups are within reference ranges', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 22,
          BodyMetricsMetricIds.sleepAverage7d: 8,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.fiberCoverage: 110,
          BodyMetricsMetricIds.sodiumRatio: 90,
        },
      );

      expect(result.level, BodyMetricsOverallHealthLevel.good);
      expect(result.hasEnoughData, isTrue);
      expect(result.attentionItems, isEmpty);
    });

    test('returns fair when one health group needs attention', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 22,
          BodyMetricsMetricIds.sleepAverage7d: 6,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.fiberCoverage: 100,
          BodyMetricsMetricIds.sodiumRatio: 90,
        },
      );

      expect(result.level, BodyMetricsOverallHealthLevel.fair);
      expect(result.attentionItems, isNotEmpty);
    });

    test('returns attention when two independent groups need attention', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 28,
          BodyMetricsMetricIds.sleepAverage7d: 6,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.fiberCoverage: 100,
          BodyMetricsMetricIds.sodiumRatio: 90,
        },
      );

      expect(result.level, BodyMetricsOverallHealthLevel.attention);
    });

    test('returns concern only when several independent groups need attention', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 31,
          BodyMetricsMetricIds.sleepAverage7d: 6,
          BodyMetricsMetricIds.macroBalanceCount: 0,
          BodyMetricsMetricIds.fiberCoverage: 50,
          BodyMetricsMetricIds.sodiumRatio: 125,
        },
      );

      expect(result.level, BodyMetricsOverallHealthLevel.concern);
    });

    test('does not call missing data healthy', () {
      final result = _assess(
        values: {BodyMetricsMetricIds.bmi: 22},
        completeness: 0.2,
      );

      expect(result.level, BodyMetricsOverallHealthLevel.insufficientData);
      expect(result.hasEnoughData, isFalse);
    });

    test('low adherence does not lower health level', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 22,
          BodyMetricsMetricIds.sleepAverage7d: 8,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.fiberCoverage: 110,
          BodyMetricsMetricIds.sodiumRatio: 90,
          BodyMetricsMetricIds.scheduleCompletion: 0,
          BodyMetricsMetricIds.mealCompletion: 0,
        },
      );

      expect(result.level, BodyMetricsOverallHealthLevel.good);
    });

    test('low data completeness becomes insufficient rather than unhealthy', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 31,
          BodyMetricsMetricIds.sleepAverage7d: 5,
          BodyMetricsMetricIds.macroBalanceCount: 0,
        },
        completeness: 0.3,
      );

      expect(result.level, BodyMetricsOverallHealthLevel.insufficientData);
    });

    test('observation metrics are not interpreted as diagnoses', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 22,
          BodyMetricsMetricIds.sleepAverage7d: 8,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.fiberCoverage: 110,
          BodyMetricsMetricIds.sodiumRatio: 90,
          BodyMetricsMetricIds.latestHeartRate: 180,
          BodyMetricsMetricIds.latestSpO2: 70,
        },
      );

      expect(result.level, BodyMetricsOverallHealthLevel.good);
      expect(
        result.attentionItems.where(
          (item) => item.contains('SpO₂') || item.contains('Nhịp tim'),
        ),
        isEmpty,
      );
    });


    test('does not apply adult BMI classification to minors', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 35,
          BodyMetricsMetricIds.sleepAverage7d: 8,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.fiberCoverage: 110,
          BodyMetricsMetricIds.sodiumRatio: 90,
        },
        ageYears: 16,
      );

      expect(result.level, BodyMetricsOverallHealthLevel.good);
      expect(
        result.attentionItems.where((item) => item.contains('Cân nặng')),
        isEmpty,
      );
    });

    test('summary items are unique and capped at three', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 31,
          BodyMetricsMetricIds.sleepAverage7d: 6,
          BodyMetricsMetricIds.macroBalanceCount: 0,
          BodyMetricsMetricIds.fiberCoverage: 50,
          BodyMetricsMetricIds.sodiumRatio: 125,
        },
      );

      expect(result.attentionItems.length, lessThanOrEqualTo(3));
      expect(result.attentionItems.toSet().length, result.attentionItems.length);
    });

    test('key metrics are prioritized and capped at six', () {
      final result = _assess(
        values: {
          BodyMetricsMetricIds.bmi: 22,
          BodyMetricsMetricIds.sleepAverage7d: 8,
          BodyMetricsMetricIds.waterAverage7d: 1800,
          BodyMetricsMetricIds.stepsAverage: 7000,
          BodyMetricsMetricIds.energyAlignment: 95,
          BodyMetricsMetricIds.macroBalanceCount: 3,
          BodyMetricsMetricIds.latestHeartRate: 72,
          BodyMetricsMetricIds.latestSpO2: 98,
          BodyMetricsMetricIds.fiberCoverage: 110,
          BodyMetricsMetricIds.sodiumRatio: 90,
        },
      );

      expect(result.keyMetricIds.length, 6);
      expect(result.keyMetricIds.first, BodyMetricsMetricIds.bmi);
    });
  });
}

BodyMetricsHealthAssessment _assess({
  required Map<String, double> values,
  double completeness = 0.8,
  int ageYears = 30,
}) {
  return BodyMetricsHealthAssessmentEngine.assess(
    snapshot: _snapshot(ageYears: ageYears),
    report: _report(values: values, completeness: completeness),
  );
}

BodyMetricsHealthSnapshot _snapshot({int ageYears = 30}) {
  return BodyMetricsHealthSnapshot(
    userId: 'test-user',
    ageYears: ageYears,
    tracking: const [],
    nutrition: const [],
    declaredConditions: const [],
    allergies: const [],
    treatments: const [],
    activeGoals: const [],
    schedule: const BodyMetricsScheduleSummary(),
    generatedAt: DateTime(2026, 8, 25),
  );
}

BodyMetricsHealthReport _report({
  required Map<String, double> values,
  required double completeness,
}) {
  return BodyMetricsHealthReport(
    metrics: values.entries.map(_metric).toList(growable: false),
    trends: const {},
    freshnessByGroup: const {},
    dataCompleteness: completeness,
    dataGaps: const [],
    generatedAt: DateTime(2026, 8, 25),
  );
}

BodyMetricsHealthMetric _metric(MapEntry<String, double> entry) {
  final category = switch (entry.key) {
    BodyMetricsMetricIds.bmi => BodyMetricsMetricCategory.body,
    BodyMetricsMetricIds.sleepAverage7d => BodyMetricsMetricCategory.recovery,
    BodyMetricsMetricIds.waterAverage7d => BodyMetricsMetricCategory.hydration,
    BodyMetricsMetricIds.stepsAverage => BodyMetricsMetricCategory.activity,
    BodyMetricsMetricIds.energyAlignment => BodyMetricsMetricCategory.energy,
    BodyMetricsMetricIds.macroBalanceCount ||
    BodyMetricsMetricIds.fiberCoverage ||
    BodyMetricsMetricIds.sodiumRatio => BodyMetricsMetricCategory.nutrition,
    BodyMetricsMetricIds.latestHeartRate ||
    BodyMetricsMetricIds.latestSpO2 => BodyMetricsMetricCategory.observation,
    BodyMetricsMetricIds.scheduleCompletion ||
    BodyMetricsMetricIds.mealCompletion => BodyMetricsMetricCategory.adherence,
    _ => BodyMetricsMetricCategory.dataQuality,
  };

  return BodyMetricsHealthMetric(
    id: entry.key,
    category: category,
    title: entry.key,
    value: entry.value,
    unit: '',
    status: BodyMetricsMetricStatus.info,
    source: category == BodyMetricsMetricCategory.observation
        ? BodyMetricsMetricSource.observation
        : BodyMetricsMetricSource.calculated,
    formulaVersion: 'test-v1',
    reference: 'test reference',
    dataWindow: 'test',
  );
}
