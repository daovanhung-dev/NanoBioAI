import 'dart:math' as math;

import '../entities/body_metrics_trend.dart';

class BodyMetricsTrendSample {
  final DateTime date;
  final double value;

  const BodyMetricsTrendSample(this.date, this.value);
}

class BodyMetricsTrendCalculator {
  const BodyMetricsTrendCalculator._();

  static BodyMetricsTrend calculate(List<BodyMetricsTrendSample> input) {
    if (input.length < 2) return const BodyMetricsTrend.insufficient();
    final samples = [...input]..sort((a, b) => a.date.compareTo(b.date));
    final values = samples.map((sample) => sample.value).toList(growable: false);
    if (values.any((value) => !value.isFinite)) {
      return const BodyMetricsTrend.insufficient();
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final variance = values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    final standardDeviation = math.sqrt(variance);
    final firstDate = samples.first.date;
    final x = samples
        .map((sample) => sample.date.difference(firstDate).inHours / 24.0)
        .toList(growable: false);
    final xMean = x.reduce((a, b) => a + b) / x.length;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var index = 0; index < samples.length; index++) {
      final dx = x[index] - xMean;
      numerator += dx * (values[index] - mean);
      denominator += dx * dx;
    }
    final slope = denominator == 0 ? 0.0 : numerator / denominator;
    final delta = values.last - values.first;
    final deltaPercentage = values.first == 0 ? null : delta / values.first * 100;
    final scale = math.max(mean.abs(), 1.0);
    final threshold = scale * 0.002;
    final direction = slope.abs() <= threshold
        ? BodyMetricsTrendDirection.stable
        : slope > 0
            ? BodyMetricsTrendDirection.increasing
            : BodyMetricsTrendDirection.decreasing;

    return BodyMetricsTrend(
      mean: mean,
      min: minimum,
      max: maximum,
      standardDeviation: standardDeviation,
      slope: slope,
      delta: delta,
      deltaPercentage: deltaPercentage,
      sampleCount: values.length,
      direction: direction,
    );
  }
}
