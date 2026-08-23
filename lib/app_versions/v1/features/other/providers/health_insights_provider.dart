import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';

import '../data/datasources/health_insights_local_datasource.dart';
import '../data/repositories/health_insights_repository_impl.dart';
import '../domain/entities/health_insights_entity.dart';
import '../domain/repositories/health_insights_repository.dart';
import '../domain/services/health_insights_analytics_service.dart';

class HealthInsightsRangeController extends Notifier<HealthInsightsRange> {
  @override
  HealthInsightsRange build() => HealthInsightsRange.days7;

  void setRange(HealthInsightsRange range) {
    if (state == range) return;
    state = range;
  }
}

final healthInsightsRangeProvider =
    NotifierProvider<HealthInsightsRangeController, HealthInsightsRange>(
      HealthInsightsRangeController.new,
    );

final healthInsightsLocalDatasourceProvider =
    Provider<HealthInsightsLocalDatasource>((ref) {
      return HealthInsightsLocalDatasource();
    });

final healthInsightsRepositoryProvider = Provider<HealthInsightsRepository>((
  ref,
) {
  return HealthInsightsRepositoryImpl(
    datasource: ref.watch(healthInsightsLocalDatasourceProvider),
  );
});

final healthInsightsAnalyticsServiceProvider =
    Provider<HealthInsightsAnalyticsService>((ref) {
      return HealthInsightsAnalyticsService();
    });

final healthInsightsProvider = FutureProvider<HealthInsightsEntity>((ref) async {
  final range = ref.watch(healthInsightsRangeProvider);
  final repository = ref.watch(healthInsightsRepositoryProvider);
  final analytics = ref.watch(healthInsightsAnalyticsServiceProvider);

  final historyDays = math.max(14, range.days * 2);
  final dashboardFuture = ref.watch(dashboardProvider.future);
  final dynamicFuture = ref.watch(dashboardDynamicProvider.future);
  final historyFuture = repository.readHistory(days: historyDays);

  final dashboard = await dashboardFuture;
  final history = await historyFuture;

  DashboardDynamicEntity dynamicData;
  try {
    dynamicData = await dynamicFuture;
  } catch (_) {
    dynamicData = DashboardDynamicEntity.empty();
  }

  final metrics = dynamicData.metrics;
  final context = HealthInsightsContextData(
    todayHealthScore: metrics.dailyScore > 0 ? metrics.dailyScore : null,
    todayWaterMl: metrics.waterMl > 0 ? metrics.waterMl : null,
    todaySteps: metrics.stepsCount > 0 ? metrics.stepsCount : null,
    todayCaloriesLogged: metrics.caloriesLogged > 0
        ? metrics.caloriesLogged
        : null,
    todaySleepHours: metrics.sleepHours > 0 ? metrics.sleepHours : null,
    todayStressLevel: metrics.stressLevel > 0 ? metrics.stressLevel : null,
    todayHeartRateBpm: metrics.heartRateBpm,
    todayOxygenSaturation: metrics.oxygenSaturation,
    todayWeightKg: dynamicData.todayWeightKg,
    todayMood: dynamicData.todayMood,
    completedTasks: metrics.completedTasks,
    totalTasks: metrics.totalTasks,
    completedMeals: metrics.completedMeals,
    totalMeals: metrics.totalMeals,
    selfCareStreak: dynamicData.selfCareStreak.currentStreak,
    insights: dynamicData.insights
        .map(
          (item) => HealthExternalInsight(
            title: item.title,
            content: item.content,
            riskLevel: item.riskLevel,
          ),
        )
        .toList(growable: false),
    recommendations: dynamicData.recommendations
        .map(
          (item) => HealthExternalRecommendation(
            type: item.type,
            title: item.title,
            description: item.description,
            actionText: item.actionText,
            isRead: item.isRead,
          ),
        )
        .toList(growable: false),
    timeline: dynamicData.timeline
        .map(
          (item) => HealthExternalTimelineEntry(
            id: item.id,
            timeLabel: item.timeLabel,
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            isCompleted: item.isCompleted,
          ),
        )
        .toList(growable: false),
  );

  return analytics.build(
    fullName: dashboard.fullName,
    bmi: dashboard.bmi,
    history: history,
    context: context,
    range: range,
  );
});
