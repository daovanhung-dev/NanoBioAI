import 'body_metrics_health_metric.dart';
import 'body_metrics_trend.dart';

class BodyMetricsHealthReport {
  final List<BodyMetricsHealthMetric> metrics;
  final Map<String, BodyMetricsTrend> trends;
  final Map<String, DateTime?> freshnessByGroup;
  final double dataCompleteness;
  final List<String> dataGaps;
  final DateTime generatedAt;

  const BodyMetricsHealthReport({
    required this.metrics,
    required this.trends,
    required this.freshnessByGroup,
    required this.dataCompleteness,
    required this.dataGaps,
    required this.generatedAt,
  });

  BodyMetricsHealthMetric? metric(String id) {
    for (final metric in metrics) {
      if (metric.id == id) return metric;
    }
    return null;
  }

  List<BodyMetricsHealthMetric> category(BodyMetricsMetricCategory category) =>
      metrics.where((metric) => metric.category == category).toList(growable: false);
}
