import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart';
import 'package:nano_app/core/membership/membership_display_info.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  group('Dashboard Blue Wellness UI', () {
    testWidgets('compact metrics remain readable on a narrow screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          width: 288,
          textScale: 1.3,
          child: const DashboardTodayMetrics(
            metrics: DashboardDailyMetrics(
              completedTasks: 3,
              totalTasks: 5,
              completedMeals: 2,
              totalMeals: 3,
              caloriesLogged: 1420,
              caloriesPlanned: 1800,
              waterMl: 1200,
              stepsCount: 4280,
              sleepHours: 7.2,
              stressLevel: 2,
              dailyScore: 78,
              nutritionLogCount: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('4280 bước'), findsOneWidget);
      expect(find.text('1420 kcal'), findsOneWidget);
      expect(find.text('7.2 giờ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick actions wrap and preserve all three actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          width: 288,
          textScale: 1.3,
          child: DashboardQuickActions(
            selectedMood: null,
            waterMl: 1200,
            weightKg: 75,
            onMoodTap: () {},
            onWaterTap: () {},
            onWeightTap: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cảm xúc'), findsOneWidget);
      expect(find.text('Nước'), findsOneWidget);
      expect(find.text('Cân nặng'), findsOneWidget);
      expect(find.text('1200 ml'), findsOneWidget);
      expect(find.text('75.0 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('header uses concise copy and shows membership state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          width: 360,
          child: const DashboardHeader(
            fullName: 'Đào Văn Hùng',
            membershipInfo: MembershipDisplayInfo(
              code: 'free',
              label: 'Gói Miễn phí',
              description: 'Tài khoản miễn phí',
              icon: Icons.verified_user_rounded,
            ),
            unreadNotifications: 2,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chào Hùng'), findsOneWidget);
      expect(find.text('Hôm nay mình chăm sóc bản thân nhé.'), findsOneWidget);
      expect(find.text('Gói Cơ bản'), findsOneWidget);
      expect(find.textContaining('Nabi yêu'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test('dashboard page remains orchestration-only and removes pulse loop', () {
      final page = File(
        'lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart',
      ).readAsStringSync();
      final lineCount = '\n'.allMatches(page).length + 1;

      expect(lineCount, lessThan(400));
      expect(page, contains('DashboardContent('));
      expect(page, isNot(contains('repeat(reverse: true)')));
      expect(page, isNot(contains('Tạo dữ liệu 7 ngày')));
    });
  });
}

Widget _testApp({
  required double width,
  double textScale = 1,
  required Widget child,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 800),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
