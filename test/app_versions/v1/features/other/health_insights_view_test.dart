import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/entities/health_insights_entity.dart';
import 'package:nano_app/app_versions/v1/features/other/domain/services/health_insights_analytics_service.dart';
import 'package:nano_app/app_versions/v1/features/other/presentation/pages/other_page.dart';
import 'package:nano_app/app_versions/v1/features/other/providers/health_insights_provider.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthInsightsView', () {
    testWidgets('renders the health cockpit hierarchy with real metrics', (
      tester,
    ) async {
      await _pumpHealthInsights(tester, insights: _readyInsights());

      expect(find.text('Góc sức khỏe'), findsOneWidget);
      expect(find.text('Điều thay đổi gần đây'), findsOneWidget);
      expect(find.text('Tín hiệu sức khỏe'), findsOneWidget);
      expect(find.text('Chỉ số của bạn'), findsOneWidget);
      expect(find.text('NanoBio cần thêm dữ liệu gì?'), findsOneWidget);
      expect(find.text('Tổng kết 7 ngày'), findsOneWidget);
      expect(find.text('Nhịp tự chăm sóc'), findsOneWidget);
      expect(find.text('Hôm nay nên làm gì?'), findsOneWidget);
      expect(find.text('Nước'), findsWidgets);
      expect(find.text('SpO₂'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows all supported time ranges', (tester) async {
      await _pumpHealthInsights(tester, insights: _readyInsights());

      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('7 ngày'), findsOneWidget);
      expect(find.text('30 ngày'), findsOneWidget);
      expect(find.text('90 ngày'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow on compact width with large text', (
      tester,
    ) async {
      await _pumpHealthInsights(
        tester,
        insights: _readyInsights(),
        size: const Size(320, 900),
        textScale: 1.8,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pump();

      expect(find.text('Chỉ số của bạn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bounds content on expanded layouts', (tester) async {
      await _pumpHealthInsights(
        tester,
        insights: _readyInsights(),
        size: const Size(1200, 900),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxWidth == 920,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes score and range semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await _pumpHealthInsights(tester, insights: _readyInsights());

      expect(
        find.bySemanticsLabel(
          RegExp(r'Điểm chăm sóc hiện tại 84 trên 100\.'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Khoảng thời gian đang xem: 7 ngày'),
        findsOneWidget,
      );
    });

    testWidgets('renders honest empty and error states', (tester) async {
      await _pumpHealthInsights(tester, insights: _emptyInsights());

      expect(find.text('Chưa đủ dữ liệu để tạo góc sức khỏe'), findsOneWidget);
      expect(find.text('Bắt đầu ghi nhận'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpHealthInsights(tester, providerError: true);

      expect(find.text('Chưa thể mở góc sức khỏe'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpHealthInsights(
  WidgetTester tester, {
  HealthInsightsEntity? insights,
  bool providerError = false,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        healthInsightsProvider.overrideWith((ref) async {
          if (providerError) throw StateError('health insights unavailable');
          return insights ?? _readyInsights();
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const HealthInsightsView(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

HealthInsightsEntity _readyInsights() {
  final now = DateTime(2026, 8, 23, 10, 30);
  final logs = List<HealthLogEntry>.generate(14, (index) {
    final date = DateTime(2026, 8, 10).add(Duration(days: index));
    return HealthLogEntry(
      date: date,
      updatedAt: DateTime(date.year, date.month, date.day, 20),
      weightKg: 65 + index * .03,
      calories: 1650 + index * 12,
      waterMl: 1500 + index * 40,
      sleepHours: 6.4 + index * .06,
      stressLevel: 48 - index,
      stepsCount: 5000 + index * 180,
      heartRateBpm: 72,
      oxygenSaturation: 98,
      dailyScore: 65 + index,
      mood: index.isEven ? 'good' : 'okay',
    );
  });

  return HealthInsightsAnalyticsService(now: () => now).build(
    fullName: 'Nguyễn An',
    bmi: 22.5,
    history: HealthInsightsHistoryEntity(
      userId: 'user-1',
      logs: logs,
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
    ),
    context: const HealthInsightsContextData(
      todayHealthScore: 84,
      todayWaterMl: 2100,
      todaySteps: 7600,
      todayCaloriesLogged: 1820,
      todaySleepHours: 7.3,
      todayStressLevel: 32,
      todayHeartRateBpm: 70,
      todayOxygenSaturation: 98.4,
      todayWeightKg: 65.4,
      todayMood: 'good',
      completedTasks: 4,
      totalTasks: 5,
      completedMeals: 2,
      totalMeals: 3,
      selfCareStreak: 5,
      insights: [
        HealthExternalInsight(
          title: 'Nhịp chăm sóc khá đều',
          content: 'Bạn đang duy trì nhiều ghi nhận đều đặn trong tuần này.',
          riskLevel: 'info',
        ),
      ],
      recommendations: [
        HealthExternalRecommendation(
          type: 'water',
          title: 'Tiếp tục ghi nhận nước',
          description: 'Theo dõi thêm lượng nước để giữ dữ liệu liên tục.',
          actionText: 'Mở theo dõi nước',
          isRead: false,
        ),
      ],
      timeline: [
        HealthExternalTimelineEntry(
          id: 'task-1',
          timeLabel: '08:00',
          title: 'Uống nước buổi sáng',
          subtitle: 'Đã hoàn thành',
          category: 'water',
          isCompleted: true,
        ),
      ],
    ),
    range: HealthInsightsRange.days7,
  );
}

HealthInsightsEntity _emptyInsights() {
  return HealthInsightsEntity(
    userId: 'user-1',
    fullName: 'Nguyễn An',
    bmi: 22.5,
    generatedAt: DateTime(2026, 8, 23),
    lastUpdatedAt: null,
    range: HealthInsightsRange.days7,
    overallFreshness: HealthDataFreshness.missing,
    healthScore: null,
    previousHealthScore: null,
    healthScoreDelta: null,
    dataCompleteness: 0,
    coreMetricsAvailable: 0,
    coreMetricsExpected: 8,
    metrics: const [],
    changes: const [],
    signals: const [],
    missingMetrics: const [],
    actions: const [],
    weeklySummary: const HealthWeeklySummary(
      daysWithLogs: 0,
      averageScore: null,
      bestScore: null,
      bestScoreDate: null,
      averageSleepHours: null,
      averageWaterMl: null,
      averageSteps: null,
      averageStress: null,
      taskCompletionRate: null,
      mealCompletionRate: null,
    ),
    habitSummary: const HealthHabitSummary(
      currentStreak: 0,
      careDays7: 0,
      taskCompletionRate7: null,
      mealCompletionRate7: null,
    ),
    timeline: const [],
  );
}
