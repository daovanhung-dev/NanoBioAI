import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/entities/health_insights_entity.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/services/health_insights_analytics_service.dart';

void main() {
  final now = DateTime(2026, 8, 23, 10, 30);
  late HealthInsightsAnalyticsService service;

  setUp(() {
    service = HealthInsightsAnalyticsService(now: () => now);
  });

  group('HealthInsightsAnalyticsService', () {
    test('builds 7-day trend from real current and previous samples', () {
      final history = HealthInsightsHistoryEntity(
        userId: 'user-1',
        logs: List<HealthLogEntry>.generate(14, (index) {
          final date = DateTime(2026, 8, 10).add(Duration(days: index));
          final score = 60 + index;
          return _log(
            date: date,
            score: score,
            sleep: 6 + index * .05,
            water: 1500 + index * 25,
            steps: 5000 + index * 100,
            calories: 1600 + index * 10,
            stress: 50 - index,
            weight: 70 + index * .02,
            mood: index.isEven ? 'good' : 'okay',
          );
        }),
        adherence: List<HealthDailyAdherenceEntry>.generate(14, (index) {
          final date = DateTime(2026, 8, 10).add(Duration(days: index));
          return HealthDailyAdherenceEntry(
            date: date,
            completedTasks: index < 7 ? 2 : 4,
            totalTasks: 5,
            completedMeals: index < 7 ? 1 : 2,
            totalMeals: 3,
          );
        }),
      );

      final result = service.build(
        fullName: 'Nguyễn An',
        bmi: 22.4,
        history: history,
        context: const HealthInsightsContextData.empty(),
        range: HealthInsightsRange.days7,
      );

      final score = result.metric(HealthMetricType.healthScore);
      expect(score, isNotNull);
      expect(score?.sampleCount, 7);
      expect(score?.previousSampleCount, 7);
      expect(score?.currentValue, 73);
      expect(score?.periodAverage, closeTo(70, .001));
      expect(score?.previousPeriodAverage, closeTo(63, .001));
      expect(score?.delta, closeTo(7, .001));
      expect(score?.trend, HealthTrendDirection.up);
      expect(score?.confidence, HealthInsightConfidence.high);
      expect(result.changes, isNotEmpty);
      expect(result.dataCompleteness, 1);
      expect(result.coreMetricsAvailable, result.coreMetricsExpected);
      expect(result.weeklySummary.daysWithLogs, 7);
    });

    test('keeps numeric zero distinct from missing data', () {
      final history = HealthInsightsHistoryEntity(
        userId: 'user-1',
        logs: [
          _log(
            date: DateTime(2026, 8, 23),
            score: 80,
            sleep: 7,
            water: 0,
            steps: 0,
            calories: 0,
            stress: 0,
            weight: 70,
            mood: 'okay',
          ),
        ],
        adherence: const [],
      );

      final result = service.build(
        fullName: 'Nguyễn An',
        bmi: 22.4,
        history: history,
        context: const HealthInsightsContextData.empty(),
        range: HealthInsightsRange.today,
      );

      expect(result.metric(HealthMetricType.water)?.currentValue, 0);
      expect(result.metric(HealthMetricType.steps)?.currentValue, 0);
      expect(result.metric(HealthMetricType.calories)?.currentValue, 0);
      expect(result.metric(HealthMetricType.stress)?.currentValue, 0);
      expect(result.missingMetrics, isNot(contains(HealthMetricType.water)));
      expect(result.missingMetrics, isNot(contains(HealthMetricType.steps)));
    });

    test('does not invent a trend when the previous period has no samples', () {
      final result = service.build(
        fullName: 'Nguyễn An',
        bmi: 22.4,
        history: HealthInsightsHistoryEntity(
          userId: 'user-1',
          logs: [
            _log(
              date: DateTime(2026, 8, 23),
              score: 82,
              sleep: 7.1,
              water: 1800,
              steps: 6200,
              calories: 1700,
              stress: 35,
              weight: 70,
              mood: 'good',
            ),
          ],
          adherence: const [],
        ),
        context: const HealthInsightsContextData.empty(),
        range: HealthInsightsRange.days7,
      );

      final score = result.metric(HealthMetricType.healthScore);
      expect(score?.currentValue, 82);
      expect(score?.previousPeriodAverage, isNull);
      expect(score?.delta, isNull);
      expect(score?.trend, HealthTrendDirection.unknown);
      expect(result.changes, isEmpty);
    });

    test('uses stored recommendations before deterministic fallback actions', () {
      final result = service.build(
        fullName: 'Nguyễn An',
        bmi: 22.4,
        history: HealthInsightsHistoryEntity(
          userId: 'user-1',
          logs: [
            _log(
              date: DateTime(2026, 8, 23),
              score: 80,
              sleep: 7,
              water: 1800,
              steps: 7000,
              calories: 1800,
              stress: 30,
              weight: 70,
              mood: 'good',
            ),
          ],
          adherence: const [],
        ),
        context: const HealthInsightsContextData(
          todayHealthScore: null,
          todayWaterMl: null,
          todaySteps: null,
          todayCaloriesLogged: null,
          todaySleepHours: null,
          todayStressLevel: null,
          todayHeartRateBpm: null,
          todayOxygenSaturation: null,
          todayWeightKg: null,
          todayMood: null,
          completedTasks: 0,
          totalTasks: 0,
          completedMeals: 0,
          totalMeals: 0,
          selfCareStreak: 2,
          insights: [],
          recommendations: [
            HealthExternalRecommendation(
              type: 'water',
              title: 'Bổ sung nước',
              description: 'Tiếp tục ghi nhận lượng nước trong ngày.',
              actionText: 'Mở theo dõi nước',
              isRead: false,
            ),
          ],
          timeline: [],
        ),
        range: HealthInsightsRange.days7,
      );

      expect(result.actions, isNotEmpty);
      expect(result.actions.first.title, 'Bổ sung nước');
      expect(result.actions.first.target, HealthActionTarget.waterTracking);
    });
  });
}

HealthLogEntry _log({
  required DateTime date,
  required int score,
  required double sleep,
  required int water,
  required int steps,
  required int calories,
  required int stress,
  required double weight,
  required String mood,
}) {
  return HealthLogEntry(
    date: date,
    updatedAt: DateTime(date.year, date.month, date.day, 20),
    weightKg: weight,
    calories: calories,
    waterMl: water,
    sleepHours: sleep,
    stressLevel: stress,
    stepsCount: steps,
    heartRateBpm: 72,
    oxygenSaturation: 98,
    dailyScore: score,
    mood: mood,
  );
}
