import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v3/features/advanced_tracking/advanced_tracking.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';

void main() {
  testWidgets('renders loading state safely', (tester) async {
    final completer = Completer<AdvancedTrackingViewModel>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          advancedTrackingSummaryProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: const MaterialApp(home: AdvancedTrackingPage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(
      AdvancedTrackingViewModel.empty(_result(hasGoal: false)),
    );
  });

  testWidgets('renders locked state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          advancedTrackingSummaryProvider.overrideWith(
            (ref) async => const AdvancedTrackingViewModel.locked(),
          ),
        ],
        child: const MaterialApp(home: AdvancedTrackingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa mở cho tài khoản này'), findsOneWidget);
  });

  testWidgets('locked state opens Plus payment route', (tester) async {
    final router = GoRouter(
      initialLocation: '/advanced',
      routes: [
        GoRoute(
          path: '/advanced',
          builder: (context, state) => const AdvancedTrackingPage(),
        ),
        GoRoute(
          path: membershipPaymentRoutePath,
          builder: (context, state) => Scaffold(
            body: Text(
              'PAYMENT_DESTINATION:${state.uri.queryParameters['plan']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          advancedTrackingSummaryProvider.overrideWith(
            (ref) async => const AdvancedTrackingViewModel.locked(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nâng cấp Plus'));
    await tester.pumpAndSettle();

    expect(find.text('PAYMENT_DESTINATION:plus'), findsOneWidget);
  });

  testWidgets('renders empty setup state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          advancedTrackingSummaryProvider.overrideWith(
            (ref) async =>
                AdvancedTrackingViewModel.empty(_result(hasGoal: false)),
          ),
        ],
        child: const MaterialApp(home: AdvancedTrackingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bắt đầu mục tiêu nước'), findsOneWidget);
  });

  testWidgets('renders ready roadmap state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          advancedTrackingSummaryProvider.overrideWith(
            (ref) async => AdvancedTrackingViewModel.ready(_result()),
          ),
        ],
        child: const MaterialApp(home: AdvancedTrackingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tiến độ tuần này'), findsOneWidget);
    expect(find.textContaining('1/2 ngày'), findsOneWidget);
    expect(find.text('Từng ngày một'), findsOneWidget);
  });

  testWidgets('renders failure state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          advancedTrackingSummaryProvider.overrideWith(
            (ref) async => const AdvancedTrackingViewModel.failure(
              'Nabi chưa thể tải lộ trình lúc này.',
            ),
          ),
        ],
        child: const MaterialApp(home: AdvancedTrackingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nabi chưa tải được lộ trình'), findsOneWidget);
  });
}

AdvancedTrackingRoadmapResult _result({bool hasGoal = true}) {
  return AdvancedTrackingRoadmapResult(
    subjectUserId: 'u1',
    goal: hasGoal
        ? const AdvancedTrackingGoal(
            id: 'goal-u1',
            subjectUserId: 'u1',
            goalCode: advancedTrackingHydrationGoalCode,
            goalName: advancedTrackingHydrationGoalName,
            isActive: true,
            createdAt: '2026-06-30T08:00:00',
          )
        : null,
    period: const AdvancedTrackingPeriod(
      startDate: '2026-06-29',
      endDate: '2026-06-30',
    ),
    steps: const [
      AdvancedTrackingRoadmapStep(date: '2026-06-29', waterMl: 2100),
      AdvancedTrackingRoadmapStep(date: '2026-06-30', waterMl: 1000),
    ],
  );
}
