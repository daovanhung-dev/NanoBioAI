enum DashboardRiskLevel { excellent, good, attention, risk }

class DashboardMetricStatus {
  const DashboardMetricStatus({
    required this.code,
    required this.title,
    required this.value,
    required this.label,
    required this.message,
    required this.progress,
  });

  final String code;
  final String title;
  final String value;
  final String label;
  final String message;

  /// Normalized value from 0.0 to 1.0 for progress UI.
  final double progress;
}

class DashboardHealthInsight {
  const DashboardHealthInsight({
    required this.title,
    required this.message,
    required this.priority,
  });

  final String title;
  final String message;

  /// Lower number means higher priority.
  final int priority;
}

class DashboardHealthStatus {
  const DashboardHealthStatus({
    required this.bmi,
    required this.bmiLabel,
    required this.bmiMessage,
    required this.healthScore,
    required this.riskLevel,
    required this.riskLabel,
    required this.summaryMessage,
    required this.metrics,
    required this.insights,
  });

  final double bmi;
  final String bmiLabel;
  final String bmiMessage;
  final int healthScore;
  final DashboardRiskLevel riskLevel;
  final String riskLabel;
  final String summaryMessage;
  final List<DashboardMetricStatus> metrics;
  final List<DashboardHealthInsight> insights;
}
