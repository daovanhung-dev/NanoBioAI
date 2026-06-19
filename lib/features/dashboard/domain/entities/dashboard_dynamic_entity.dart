class DashboardDynamicEntity {
  final String? userId;
  final DateTime generatedAt;
  final DashboardDailyMetrics metrics;
  final List<DashboardMealItem> todayMeals;
  final List<DashboardTaskItem> todayTasks;
  final List<DashboardTimelineItem> timeline;
  final List<DashboardInsightItem> insights;
  final List<DashboardRecommendationItem> recommendations;
  final List<DashboardGoalProgressItem> goalProgress;
  final int unreadNotificationCount;
  final String? todayMood;
  final double? todayWeightKg;
  final DashboardPlanStatus planStatus;
  final DashboardSelfCareStreak selfCareStreak;

  const DashboardDynamicEntity({
    required this.userId,
    required this.generatedAt,
    required this.metrics,
    required this.todayMeals,
    required this.todayTasks,
    required this.timeline,
    required this.insights,
    required this.recommendations,
    required this.goalProgress,
    required this.unreadNotificationCount,
    required this.todayMood,
    required this.todayWeightKg,
    required this.planStatus,
    required this.selfCareStreak,
  });

  factory DashboardDynamicEntity.empty() {
    return DashboardDynamicEntity(
      userId: null,
      generatedAt: DateTime.now(),
      metrics: const DashboardDailyMetrics.empty(),
      todayMeals: const [],
      todayTasks: const [],
      timeline: const [],
      insights: const [],
      recommendations: const [],
      goalProgress: const [],
      unreadNotificationCount: 0,
      todayMood: null,
      todayWeightKg: null,
      planStatus: const DashboardPlanStatus.empty(),
      selfCareStreak: const DashboardSelfCareStreak.empty(),
    );
  }

  bool get hasAnyData =>
      todayMeals.isNotEmpty ||
      todayTasks.isNotEmpty ||
      timeline.isNotEmpty ||
      insights.isNotEmpty ||
      recommendations.isNotEmpty ||
      goalProgress.isNotEmpty ||
      unreadNotificationCount > 0 ||
      todayMood != null ||
      todayWeightKg != null ||
      planStatus.hasPlan ||
      selfCareStreak.hasAnyCareDay ||
      metrics.hasAnyData;
}

class DashboardPlanStatus {
  final String? lastPlanDate;
  final int remainingDays;

  const DashboardPlanStatus({
    required this.lastPlanDate,
    required this.remainingDays,
  });

  const DashboardPlanStatus.empty() : lastPlanDate = null, remainingDays = 0;

  bool get hasPlan => lastPlanDate != null && lastPlanDate!.trim().isNotEmpty;
}

class DashboardSelfCareStreak {
  final List<DashboardSelfCareDay> days;
  final int currentStreak;

  const DashboardSelfCareStreak({
    required this.days,
    required this.currentStreak,
  });

  const DashboardSelfCareStreak.empty() : days = const [], currentStreak = 0;

  bool get hasAnyCareDay => days.any((day) => day.hasCareSignal);
}

class DashboardSelfCareDay {
  final String date;
  final bool hasCareSignal;

  const DashboardSelfCareDay({required this.date, required this.hasCareSignal});
}

class DashboardDailyMetrics {
  final int completedTasks;
  final int totalTasks;
  final int completedMeals;
  final int totalMeals;
  final int caloriesLogged;
  final int caloriesPlanned;
  final int waterMl;
  final int stepsCount;
  final double sleepHours;
  final int stressLevel;
  final int? heartRateBpm;
  final double? oxygenSaturation;
  final int dailyScore;
  final int nutritionLogCount;

  const DashboardDailyMetrics({
    required this.completedTasks,
    required this.totalTasks,
    required this.completedMeals,
    required this.totalMeals,
    required this.caloriesLogged,
    required this.caloriesPlanned,
    required this.waterMl,
    required this.stepsCount,
    required this.sleepHours,
    required this.stressLevel,
    this.heartRateBpm,
    this.oxygenSaturation,
    required this.dailyScore,
    required this.nutritionLogCount,
  });

  const DashboardDailyMetrics.empty()
    : completedTasks = 0,
      totalTasks = 0,
      completedMeals = 0,
      totalMeals = 0,
      caloriesLogged = 0,
      caloriesPlanned = 0,
      waterMl = 0,
      stepsCount = 0,
      sleepHours = 0,
      stressLevel = 0,
      heartRateBpm = null,
      oxygenSaturation = null,
      dailyScore = 0,
      nutritionLogCount = 0;

  double get taskCompletionRate =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;
  double get mealCompletionRate =>
      totalMeals == 0 ? 0 : completedMeals / totalMeals;

  bool get hasAnyData =>
      totalTasks > 0 ||
      totalMeals > 0 ||
      caloriesLogged > 0 ||
      caloriesPlanned > 0 ||
      waterMl > 0 ||
      stepsCount > 0 ||
      sleepHours > 0 ||
      stressLevel > 0 ||
      heartRateBpm != null ||
      oxygenSaturation != null ||
      dailyScore > 0 ||
      nutritionLogCount > 0;
}

class DashboardMealItem {
  final String id;
  final String mealType;
  final String mealName;
  final String? description;
  final int calories;
  final int waterMl;
  final int mealOrder;
  final String? startTime;
  final bool isCompleted;

  const DashboardMealItem({
    required this.id,
    required this.mealType,
    required this.mealName,
    required this.description,
    required this.calories,
    required this.waterMl,
    required this.mealOrder,
    required this.startTime,
    required this.isCompleted,
  });
}

class DashboardTaskItem {
  final String id;
  final String category;
  final String title;
  final String? description;
  final double targetValue;
  final double currentValue;
  final String? unit;
  final bool isCompleted;
  final int sortOrder;
  final String? encouragement;
  final String? timeLabel;

  const DashboardTaskItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.isCompleted,
    required this.sortOrder,
    required this.encouragement,
    this.timeLabel,
  });

  double get progress {
    if (isCompleted) return 1;
    if (targetValue <= 0) return currentValue > 0 ? 1 : 0;
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }
}

class DashboardTimelineItem {
  final String id;
  final String sourceType;
  final String? sourceId;
  final String status;
  final bool canComplete;
  final String timeLabel;
  final String title;
  final String subtitle;
  final String category;
  final bool isCompleted;
  final int sortOrder;

  const DashboardTimelineItem({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.status,
    required this.canComplete,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.isCompleted,
    required this.sortOrder,
  });
}

class DashboardTimelineSourceTypes {
  static const schedule = 'schedule';
  static const meal = 'meal';
  static const task = 'task';
  static const notification = 'notification';
}

class DashboardTimelineStatus {
  static const pending = 'pending';
  static const completed = 'completed';
}

class DashboardInsightItem {
  final String id;
  final String type;
  final String title;
  final String content;
  final String riskLevel;
  final String? createdAt;

  const DashboardInsightItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.riskLevel,
    required this.createdAt,
  });
}

class DashboardRecommendationItem {
  final String id;
  final String type;
  final String title;
  final String description;
  final String actionText;
  final bool isRead;
  final String? createdAt;

  const DashboardRecommendationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.actionText,
    required this.isRead,
    required this.createdAt,
  });
}

class DashboardGoalProgressItem {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final bool isActive;

  const DashboardGoalProgressItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.isActive,
  });
}
