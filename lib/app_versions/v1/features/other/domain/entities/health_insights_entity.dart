enum HealthInsightsRange { today, days7, days30, days90 }

extension HealthInsightsRangeX on HealthInsightsRange {
  int get days => switch (this) {
    HealthInsightsRange.today => 1,
    HealthInsightsRange.days7 => 7,
    HealthInsightsRange.days30 => 30,
    HealthInsightsRange.days90 => 90,
  };

  String get label => switch (this) {
    HealthInsightsRange.today => 'Hôm nay',
    HealthInsightsRange.days7 => '7 ngày',
    HealthInsightsRange.days30 => '30 ngày',
    HealthInsightsRange.days90 => '90 ngày',
  };
}

enum HealthMetricType {
  healthScore,
  sleep,
  water,
  steps,
  calories,
  stress,
  weight,
  heartRate,
  oxygen,
  mood,
  taskCompletion,
  mealCompletion,
}

enum HealthTrendDirection { up, down, stable, unknown }

enum HealthDataFreshness { today, recent, stale, missing }

enum HealthInsightConfidence { high, medium, low, insufficient }

enum HealthSignalKind { attention, progress, dataGap, info }

enum HealthActionTarget {
  healthTracking,
  weeklySummary,
  bodyMetrics,
  waterTracking,
  sleepTracking,
  stressTracking,
  mealPlan,
  lifestyleSchedule,
  none,
}

class HealthMetricPoint {
  final DateTime date;
  final double value;

  const HealthMetricPoint({required this.date, required this.value});
}

class HealthMetricSummary {
  final HealthMetricType type;
  final bool isCore;
  final double? currentValue;
  final String? currentText;
  final double? periodAverage;
  final double? previousPeriodAverage;
  final double? minimum;
  final double? maximum;
  final double? delta;
  final double? deltaPercent;
  final HealthTrendDirection trend;
  final HealthInsightConfidence confidence;
  final HealthDataFreshness freshness;
  final int sampleCount;
  final int previousSampleCount;
  final DateTime? latestRecordedAt;
  final List<HealthMetricPoint> series;

  const HealthMetricSummary({
    required this.type,
    required this.isCore,
    required this.currentValue,
    required this.currentText,
    required this.periodAverage,
    required this.previousPeriodAverage,
    required this.minimum,
    required this.maximum,
    required this.delta,
    required this.deltaPercent,
    required this.trend,
    required this.confidence,
    required this.freshness,
    required this.sampleCount,
    required this.previousSampleCount,
    required this.latestRecordedAt,
    required this.series,
  });

  bool get hasValue => currentValue != null || (currentText?.trim().isNotEmpty ?? false);

  bool get hasTrend =>
      trend != HealthTrendDirection.unknown &&
      confidence != HealthInsightConfidence.insufficient &&
      delta != null;
}

class HealthChangeItem {
  final HealthMetricType metric;
  final HealthTrendDirection direction;
  final double delta;
  final double? deltaPercent;
  final HealthInsightConfidence confidence;

  const HealthChangeItem({
    required this.metric,
    required this.direction,
    required this.delta,
    required this.deltaPercent,
    required this.confidence,
  });
}

class HealthSignalItem {
  final HealthSignalKind kind;
  final String title;
  final String message;
  final HealthMetricType? metric;
  final HealthActionTarget actionTarget;
  final String? sourceLabel;

  const HealthSignalItem({
    required this.kind,
    required this.title,
    required this.message,
    this.metric,
    this.actionTarget = HealthActionTarget.none,
    this.sourceLabel,
  });
}

class HealthActionItem {
  final String title;
  final String description;
  final String actionLabel;
  final HealthActionTarget target;
  final bool isRead;

  const HealthActionItem({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.target,
    required this.isRead,
  });
}

class HealthTimelineEntry {
  final String id;
  final String timeLabel;
  final String title;
  final String subtitle;
  final String category;
  final bool isCompleted;

  const HealthTimelineEntry({
    required this.id,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.isCompleted,
  });
}

class HealthWeeklySummary {
  final int daysWithLogs;
  final double? averageScore;
  final int? bestScore;
  final DateTime? bestScoreDate;
  final double? averageSleepHours;
  final double? averageWaterMl;
  final double? averageSteps;
  final double? averageStress;
  final double? taskCompletionRate;
  final double? mealCompletionRate;

  const HealthWeeklySummary({
    required this.daysWithLogs,
    required this.averageScore,
    required this.bestScore,
    required this.bestScoreDate,
    required this.averageSleepHours,
    required this.averageWaterMl,
    required this.averageSteps,
    required this.averageStress,
    required this.taskCompletionRate,
    required this.mealCompletionRate,
  });
}

class HealthHabitSummary {
  final int currentStreak;
  final int careDays7;
  final double? taskCompletionRate7;
  final double? mealCompletionRate7;

  const HealthHabitSummary({
    required this.currentStreak,
    required this.careDays7,
    required this.taskCompletionRate7,
    required this.mealCompletionRate7,
  });
}

class HealthLogEntry {
  final DateTime date;
  final DateTime? updatedAt;
  final double? weightKg;
  final int? calories;
  final int? waterMl;
  final double? sleepHours;
  final int? stressLevel;
  final int? stepsCount;
  final int? heartRateBpm;
  final double? oxygenSaturation;
  final int? dailyScore;
  final String? mood;

  const HealthLogEntry({
    required this.date,
    required this.updatedAt,
    required this.weightKg,
    required this.calories,
    required this.waterMl,
    required this.sleepHours,
    required this.stressLevel,
    required this.stepsCount,
    required this.heartRateBpm,
    required this.oxygenSaturation,
    required this.dailyScore,
    required this.mood,
  });
}

class HealthDailyAdherenceEntry {
  final DateTime date;
  final int completedTasks;
  final int totalTasks;
  final int completedMeals;
  final int totalMeals;

  const HealthDailyAdherenceEntry({
    required this.date,
    required this.completedTasks,
    required this.totalTasks,
    required this.completedMeals,
    required this.totalMeals,
  });

  double? get taskCompletionRate =>
      totalTasks <= 0 ? null : completedTasks / totalTasks;

  double? get mealCompletionRate =>
      totalMeals <= 0 ? null : completedMeals / totalMeals;

  bool get hasCareSignal => completedTasks > 0 || completedMeals > 0;
}

class HealthInsightsHistoryEntity {
  final String userId;
  final List<HealthLogEntry> logs;
  final List<HealthDailyAdherenceEntry> adherence;

  const HealthInsightsHistoryEntity({
    required this.userId,
    required this.logs,
    required this.adherence,
  });
}

class HealthExternalInsight {
  final String title;
  final String content;
  final String riskLevel;

  const HealthExternalInsight({
    required this.title,
    required this.content,
    required this.riskLevel,
  });
}

class HealthExternalRecommendation {
  final String type;
  final String title;
  final String description;
  final String actionText;
  final bool isRead;

  const HealthExternalRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.actionText,
    required this.isRead,
  });
}

class HealthExternalTimelineEntry {
  final String id;
  final String timeLabel;
  final String title;
  final String subtitle;
  final String category;
  final bool isCompleted;

  const HealthExternalTimelineEntry({
    required this.id,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.isCompleted,
  });
}

class HealthInsightsContextData {
  final int? todayHealthScore;
  final int? todayWaterMl;
  final int? todaySteps;
  final int? todayCaloriesLogged;
  final double? todaySleepHours;
  final int? todayStressLevel;
  final int? todayHeartRateBpm;
  final double? todayOxygenSaturation;
  final double? todayWeightKg;
  final String? todayMood;
  final int completedTasks;
  final int totalTasks;
  final int completedMeals;
  final int totalMeals;
  final int selfCareStreak;
  final List<HealthExternalInsight> insights;
  final List<HealthExternalRecommendation> recommendations;
  final List<HealthExternalTimelineEntry> timeline;

  const HealthInsightsContextData({
    required this.todayHealthScore,
    required this.todayWaterMl,
    required this.todaySteps,
    required this.todayCaloriesLogged,
    required this.todaySleepHours,
    required this.todayStressLevel,
    required this.todayHeartRateBpm,
    required this.todayOxygenSaturation,
    required this.todayWeightKg,
    required this.todayMood,
    required this.completedTasks,
    required this.totalTasks,
    required this.completedMeals,
    required this.totalMeals,
    required this.selfCareStreak,
    required this.insights,
    required this.recommendations,
    required this.timeline,
  });

  const HealthInsightsContextData.empty()
    : todayHealthScore = null,
      todayWaterMl = null,
      todaySteps = null,
      todayCaloriesLogged = null,
      todaySleepHours = null,
      todayStressLevel = null,
      todayHeartRateBpm = null,
      todayOxygenSaturation = null,
      todayWeightKg = null,
      todayMood = null,
      completedTasks = 0,
      totalTasks = 0,
      completedMeals = 0,
      totalMeals = 0,
      selfCareStreak = 0,
      insights = const [],
      recommendations = const [],
      timeline = const [];
}

class HealthInsightsEntity {
  final String userId;
  final String fullName;
  final double bmi;
  final DateTime generatedAt;
  final DateTime? lastUpdatedAt;
  final HealthInsightsRange range;
  final HealthDataFreshness overallFreshness;
  final int? healthScore;
  final int? previousHealthScore;
  final double? healthScoreDelta;
  final double dataCompleteness;
  final int coreMetricsAvailable;
  final int coreMetricsExpected;
  final List<HealthMetricSummary> metrics;
  final List<HealthChangeItem> changes;
  final List<HealthSignalItem> signals;
  final List<HealthMetricType> missingMetrics;
  final List<HealthActionItem> actions;
  final HealthWeeklySummary weeklySummary;
  final HealthHabitSummary habitSummary;
  final List<HealthTimelineEntry> timeline;

  const HealthInsightsEntity({
    required this.userId,
    required this.fullName,
    required this.bmi,
    required this.generatedAt,
    required this.lastUpdatedAt,
    required this.range,
    required this.overallFreshness,
    required this.healthScore,
    required this.previousHealthScore,
    required this.healthScoreDelta,
    required this.dataCompleteness,
    required this.coreMetricsAvailable,
    required this.coreMetricsExpected,
    required this.metrics,
    required this.changes,
    required this.signals,
    required this.missingMetrics,
    required this.actions,
    required this.weeklySummary,
    required this.habitSummary,
    required this.timeline,
  });

  HealthMetricSummary? metric(HealthMetricType type) {
    for (final item in metrics) {
      if (item.type == type) return item;
    }
    return null;
  }

  bool get hasAnyData =>
      metrics.any((item) => item.hasValue) ||
      signals.isNotEmpty ||
      actions.isNotEmpty ||
      timeline.isNotEmpty;
}
