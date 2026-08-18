enum BodyMetricsTrendDirection { increasing, decreasing, stable, insufficientData }

class BodyMetricsTrend {
  final double? mean;
  final double? min;
  final double? max;
  final double? standardDeviation;
  final double? slope;
  final double? delta;
  final double? deltaPercentage;
  final int sampleCount;
  final BodyMetricsTrendDirection direction;

  const BodyMetricsTrend({
    required this.sampleCount,
    required this.direction,
    this.mean,
    this.min,
    this.max,
    this.standardDeviation,
    this.slope,
    this.delta,
    this.deltaPercentage,
  });

  const BodyMetricsTrend.insufficient()
      : mean = null,
        min = null,
        max = null,
        standardDeviation = null,
        slope = null,
        delta = null,
        deltaPercentage = null,
        sampleCount = 0,
        direction = BodyMetricsTrendDirection.insufficientData;
}
