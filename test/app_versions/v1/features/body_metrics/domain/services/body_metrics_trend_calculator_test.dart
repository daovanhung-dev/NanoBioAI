import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_trend.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/services/body_metrics_trend_calculator.dart';

void main() {
  test('calculates increasing trend with deterministic statistics', () {
    final start = DateTime(2026, 8, 1);
    final trend = BodyMetricsTrendCalculator.calculate([
      BodyMetricsTrendSample(start, 70),
      BodyMetricsTrendSample(start.add(const Duration(days: 1)), 71),
      BodyMetricsTrendSample(start.add(const Duration(days: 2)), 72),
    ]);

    expect(trend.sampleCount, 3);
    expect(trend.mean, closeTo(71, .001));
    expect(trend.delta, closeTo(2, .001));
    expect(trend.slope, closeTo(1, .001));
    expect(trend.direction, BodyMetricsTrendDirection.increasing);
  });

  test('returns insufficient data for one sample', () {
    final trend = BodyMetricsTrendCalculator.calculate([
      BodyMetricsTrendSample(DateTime(2026, 8, 1), 70),
    ]);
    expect(trend.direction, BodyMetricsTrendDirection.insufficientData);
  });
}
