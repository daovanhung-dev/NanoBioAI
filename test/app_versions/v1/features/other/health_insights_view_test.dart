import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/other/presentation/pages/other_page.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthInsightsView', () {
    testWidgets('renders the optimized ready-state hierarchy', (tester) async {
      await _pumpHealthInsights(tester);

      expect(find.text('Góc sức khỏe'), findsOneWidget);
      expect(find.text('Điều đáng chú ý'), findsOneWidget);
      expect(find.text('Việc nên làm hôm nay'), findsOneWidget);
      expect(find.text('Chỉ số hôm nay'), findsOneWidget);
      expect(find.text('Thông tin thêm'), findsOneWidget);

      final recommendation = tester.widget<Text>(
        find.text(_primaryRecommendationDescription),
      );
      expect(recommendation.maxLines, isNull);
      expect(recommendation.overflow, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow on compact width with large text', (
      tester,
    ) async {
      await _pumpHealthInsights(
        tester,
        size: const Size(320, 900),
        textScale: 1.8,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pump();

      expect(find.text('Nước'), findsOneWidget);
      expect(find.text('Bước chân'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bounds content on expanded layouts', (tester) async {
      await _pumpHealthInsights(tester, size: const Size(1200, 900));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox &&
              widget.constraints.maxWidth == 920,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes useful health semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await _pumpHealthInsights(tester);

      expect(
        find.bySemanticsLabel(
          'Điểm sức khỏe hôm nay: 78 trên 100. Bạn đang đi đúng hướng.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Nước: 1.8 L'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'Việc nên làm hôm nay\. Đi bộ nhẹ sau bữa tối\.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps empty and error states user friendly', (tester) async {
      await _pumpHealthInsights(
        tester,
        dynamicData: DashboardDynamicEntity.empty(),
      );

      expect(find.text('Nabi chưa có nhận xét mới'), findsOneWidget);
      expect(find.text('Nabi chưa có gợi ý mới'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpHealthInsights(tester, dashboardError: true);

      expect(find.text('Chưa thể mở góc sức khỏe'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

const _primaryRecommendationDescription =
    'Sau bữa tối, bạn có thể đi bộ nhẹ khoảng 10 đến 15 phút để thư giãn và duy trì nhịp vận động.';

Future<void> _pumpHealthInsights(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  DashboardDynamicEntity? dynamicData,
  bool dashboardError = false,
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
        dashboardProvider.overrideWith((ref) async {
          if (dashboardError) throw StateError('test dashboard error');
          return _dashboard();
        }),
        dashboardDynamicProvider.overrideWith(
          (ref) async => dynamicData ?? _dynamicDashboard(),
        ),
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

DashboardEntity _dashboard() {
  return const DashboardEntity(
    userId: 'user-1',
    fullName: 'Đào Văn Hùng',
    email: 'user@example.com',
    phone: '',
    gender: 'male',
    birthYear: 2005,
    occupation: 'developer',
    heightCm: 178,
    weightKg: 75,
    bmi: 23.7,
    goals: ['Khỏe hơn'],
    conditions: [],
    habits: [],
    sleepQuality: 'good',
    activityLevel: 'moderate',
    waterPerDay: '2L',
    allergyName: '',
    allergyNote: '',
    treatmentName: '',
    medicationName: '',
    treatmentNote: '',
    concernText: '',
    surveyAnswers: {},
  );
}

DashboardDynamicEntity _dynamicDashboard() {
  return DashboardDynamicEntity(
    userId: 'user-1',
    generatedAt: DateTime(2026, 8, 19),
    metrics: const DashboardDailyMetrics(
      completedTasks: 4,
      totalTasks: 5,
      completedMeals: 2,
      totalMeals: 3,
      caloriesLogged: 1460,
      caloriesPlanned: 1900,
      waterMl: 1800,
      stepsCount: 6840,
      sleepHours: 7.2,
      stressLevel: 42,
      heartRateBpm: 72,
      oxygenSaturation: 98.1,
      dailyScore: 78,
      nutritionLogCount: 2,
    ),
    todayMeals: const [],
    todayTasks: const [],
    timeline: const [],
    insights: const [
      DashboardInsightItem(
        id: 'insight-1',
        type: 'daily',
        title: 'Nhịp chăm sóc đang khá đều',
        content:
            'Bạn đã duy trì phần lớn nhiệm vụ hôm nay, nhưng lượng nước vẫn có thể bổ sung thêm một chút.',
        riskLevel: 'medium',
        createdAt: null,
      ),
      DashboardInsightItem(
        id: 'insight-2',
        type: 'sleep',
        title: 'Giấc ngủ đang ổn định',
        content: 'Thời lượng ngủ hôm nay đang ở mức phù hợp với nhịp hiện tại.',
        riskLevel: 'low',
        createdAt: null,
      ),
    ],
    recommendations: const [
      DashboardRecommendationItem(
        id: 'recommendation-1',
        type: 'movement',
        title: 'Đi bộ nhẹ sau bữa tối',
        description: _primaryRecommendationDescription,
        actionText: 'Bắt đầu với 10 phút và giữ nhịp thoải mái.',
        isRead: false,
        createdAt: null,
      ),
      DashboardRecommendationItem(
        id: 'recommendation-2',
        type: 'water',
        title: 'Bổ sung thêm nước',
        description: 'Uống thêm một cốc nước nhỏ trong buổi chiều.',
        actionText: '',
        isRead: true,
        createdAt: null,
      ),
    ],
    goalProgress: const [],
    unreadNotificationCount: 0,
    todayMood: null,
    todayWeightKg: null,
    planStatus: const DashboardPlanStatus.empty(),
    selfCareStreak: const DashboardSelfCareStreak.empty(),
  );
}
