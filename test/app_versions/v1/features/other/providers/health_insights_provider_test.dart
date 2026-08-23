import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/entities/health_insights_entity.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/repositories/health_insights_repository.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/services/health_insights_analytics_service.dart';
import 'package:nano_app/app_versions/v1/features/other/providers/health_insights_provider.dart';

void main() {
  group('healthInsightsProvider', () {
    test('loads dashboard, history and current dynamic context', () async {
      final repository = _FakeHealthInsightsRepository(_history());
      final container = ProviderContainer(
        overrides: [
          dashboardProvider.overrideWith((ref) async => _dashboard()),
          dashboardDynamicProvider.overrideWith(
            (ref) async => _dynamicDashboard(),
          ),
          healthInsightsRepositoryProvider.overrideWithValue(repository),
          healthInsightsAnalyticsServiceProvider.overrideWithValue(
            HealthInsightsAnalyticsService(
              now: () => DateTime(2026, 8, 23, 12),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(healthInsightsProvider.future);

      expect(repository.requestedDays, [14]);
      expect(result.fullName, 'Nguyễn An');
      expect(result.range, HealthInsightsRange.days7);
      expect(result.healthScore, 84);
      expect(result.metric(HealthMetricType.water)?.currentValue, 2000);
      expect(result.habitSummary.currentStreak, 4);
      expect(result.actions.first.target, HealthActionTarget.waterTracking);
    });

    test('switching to 30 days reloads a 60-day comparison window', () async {
      final repository = _FakeHealthInsightsRepository(_history());
      final container = ProviderContainer(
        overrides: [
          dashboardProvider.overrideWith((ref) async => _dashboard()),
          dashboardDynamicProvider.overrideWith(
            (ref) async => DashboardDynamicEntity.empty(),
          ),
          healthInsightsRepositoryProvider.overrideWithValue(repository),
          healthInsightsAnalyticsServiceProvider.overrideWithValue(
            HealthInsightsAnalyticsService(
              now: () => DateTime(2026, 8, 23, 12),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthInsightsProvider.future);
      container
          .read(healthInsightsRangeProvider.notifier)
          .setRange(HealthInsightsRange.days30);
      final result = await container.read(healthInsightsProvider.future);

      expect(result.range, HealthInsightsRange.days30);
      expect(repository.requestedDays.last, 60);
    });

    test('keeps local history usable when dashboard dynamic data fails', () async {
      final repository = _FakeHealthInsightsRepository(_history());
      final container = ProviderContainer(
        overrides: [
          dashboardProvider.overrideWith((ref) async => _dashboard()),
          dashboardDynamicProvider.overrideWith((ref) async {
            throw StateError('dynamic source unavailable');
          }),
          healthInsightsRepositoryProvider.overrideWithValue(repository),
          healthInsightsAnalyticsServiceProvider.overrideWithValue(
            HealthInsightsAnalyticsService(
              now: () => DateTime(2026, 8, 23, 12),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(healthInsightsProvider.future);

      expect(result.healthScore, 80);
      expect(result.metrics, isNotEmpty);
      expect(result.fullName, 'Nguyễn An');
    });
  });
}

class _FakeHealthInsightsRepository implements HealthInsightsRepository {
  final HealthInsightsHistoryEntity history;
  final List<int> requestedDays = [];

  _FakeHealthInsightsRepository(this.history);

  @override
  Future<HealthInsightsHistoryEntity> readHistory({required int days}) async {
    requestedDays.add(days);
    return history;
  }
}

DashboardEntity _dashboard() {
  return const DashboardEntity(
    userId: 'user-1',
    fullName: 'Nguyễn An',
    email: 'an@example.com',
    phone: '',
    gender: 'other',
    birthYear: 1998,
    occupation: '',
    heightCm: 170,
    weightKg: 65,
    bmi: 22.5,
    goals: [],
    conditions: [],
    habits: [],
    sleepQuality: '',
    activityLevel: '',
    waterPerDay: '',
    allergyName: '',
    allergyNote: '',
    treatmentName: '',
    medicationName: '',
    treatmentNote: '',
    concernText: '',
    surveyAnswers: {},
  );
}

HealthInsightsHistoryEntity _history() {
  return HealthInsightsHistoryEntity(
    userId: 'user-1',
    logs: [
      HealthLogEntry(
        date: DateTime(2026, 8, 23),
        updatedAt: DateTime(2026, 8, 23, 9),
        weightKg: 65,
        calories: 1700,
        waterMl: 1800,
        sleepHours: 7,
        stressLevel: 30,
        stepsCount: 6500,
        heartRateBpm: 70,
        oxygenSaturation: 98,
        dailyScore: 80,
        mood: 'good',
      ),
    ],
    adherence: const [],
  );
}

DashboardDynamicEntity _dynamicDashboard() {
  return DashboardDynamicEntity(
    userId: 'user-1',
    generatedAt: DateTime(2026, 8, 23, 10),
    metrics: const DashboardDailyMetrics(
      completedTasks: 4,
      totalTasks: 5,
      completedMeals: 2,
      totalMeals: 3,
      caloriesLogged: 1800,
      caloriesPlanned: 1900,
      waterMl: 2000,
      stepsCount: 7000,
      sleepHours: 7.2,
      stressLevel: 28,
      heartRateBpm: 71,
      oxygenSaturation: 98.2,
      dailyScore: 84,
      nutritionLogCount: 2,
    ),
    todayMeals: const [],
    todayTasks: const [],
    timeline: const [],
    insights: const [],
    recommendations: const [
      DashboardRecommendationItem(
        id: 'rec-1',
        type: 'water',
        title: 'Theo dõi nước',
        description: 'Tiếp tục ghi nhận lượng nước trong ngày.',
        actionText: 'Mở theo dõi nước',
        isRead: false,
        createdAt: null,
      ),
    ],
    goalProgress: const [],
    unreadNotificationCount: 0,
    todayMood: 'good',
    todayWeightKg: 65,
    planStatus: const DashboardPlanStatus.empty(),
    selfCareStreak: const DashboardSelfCareStreak(
      days: [],
      currentStreak: 4,
    ),
  );
}
