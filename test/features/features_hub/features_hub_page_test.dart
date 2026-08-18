import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

void main() {
  const activeFeatureTitles = [
    'Nabi Care',
    'Lịch trình cá nhân',
    'Nhiệm vụ hôm nay',
    'Thực đơn theo tuần',
    'Dinh dưỡng',
    'Chỉ số cơ thể',
    'Theo dõi sức khỏe',
    'Uống nước',
    'Mục tiêu cá nhân',
    'Tổng kết tuần',
    'Chăm mình 5 phút',
    'Chế độ dịu nhẹ',
    'Thói quen hằng ngày',
    'Trò chuyện với Nabi',
    'Trò chuyện giọng nói',
  ];

  const plannedFeatureTitles = [
    'Giấc ngủ',
    'Cảm xúc & stress',
    'Cộng đồng chăm sóc',
  ];

  testWidgets('renders 15 active tools and keeps future sections collapsed', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));

    expect(find.text('Bảng Theo dõi Hành Trình Sống Khỏe'), findsOneWidget);
    expect(find.text('Chăm sóc hôm nay'), findsOneWidget);
    expect(find.byKey(const Key('active-features-grid')), findsOneWidget);

    for (final title in activeFeatureTitles) {
      if (find.text(title).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text(title),
          240,
          scrollable: find.byType(Scrollable).first,
        );
      }
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.byKey(const Key('planned-features-toggle')), findsOneWidget);
    expect(
      find.byKey(const Key('advanced-health-features-toggle')),
      findsOneWidget,
    );
    for (final title in plannedFeatureTitles) {
      expect(find.text(title), findsNothing, reason: title);
    }
    expect(
      find.byKey(const Key('advanced-health-feature-M20')),
      findsNothing,
    );
  });

  testWidgets('compact layout uses three active feature columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));
    await tester.pump();

    final first = find.byKey(const Key('feature-tile-nabi-care'));
    final second = find.byKey(const Key('feature-tile-lifestyle-schedule'));
    final third = find.byKey(const Key('feature-tile-today-tasks'));
    final fourth = find.byKey(const Key('feature-tile-meal-plan'));

    final firstOffset = tester.getTopLeft(first);
    final secondOffset = tester.getTopLeft(second);
    final thirdOffset = tester.getTopLeft(third);
    final fourthOffset = tester.getTopLeft(fourth);

    expect(secondOffset.dy, moreOrLessEquals(firstOffset.dy, epsilon: .1));
    expect(thirdOffset.dy, moreOrLessEquals(firstOffset.dy, epsilon: .1));
    expect(fourthOffset.dy, greaterThan(firstOffset.dy));
    expect(firstOffset.dx, lessThan(secondOffset.dx));
    expect(secondOffset.dx, lessThan(thirdOffset.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('planned and advanced sections expand on demand', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));

    final plannedToggle = find.byKey(const Key('planned-features-toggle'));
    await tester.scrollUntilVisible(
      plannedToggle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(plannedToggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('planned-features-grid')), findsOneWidget);
    for (final title in plannedFeatureTitles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    final plannedFirst = find.byKey(
      const Key('planned-feature-sleep-tracking'),
    );
    final plannedSecond = find.byKey(
      const Key('planned-feature-stress-tracking'),
    );
    final plannedThird = find.byKey(
      const Key('planned-feature-community'),
    );
    final plannedY = tester.getTopLeft(plannedFirst).dy;
    expect(
      tester.getTopLeft(plannedSecond).dy,
      moreOrLessEquals(plannedY, epsilon: .1),
    );
    expect(
      tester.getTopLeft(plannedThird).dy,
      moreOrLessEquals(plannedY, epsilon: .1),
    );
    expect(tester.getSize(plannedFirst).height, lessThan(140));

    final advancedToggle = find.byKey(
      const Key('advanced-health-features-toggle'),
    );
    await tester.scrollUntilVisible(
      advancedToggle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(advancedToggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('advanced-features-grid')), findsOneWidget);
    for (final item in advancedHealthFeatureCatalog) {
      expect(find.text(item.title), findsOneWidget, reason: item.moduleId);
      expect(
        find.byKey(Key('advanced-health-feature-${item.moduleId}')),
        findsOneWidget,
        reason: item.moduleId,
      );
    }

    final m20 = find.byKey(const Key('advanced-health-feature-M20'));
    final m21 = find.byKey(const Key('advanced-health-feature-M21'));
    final m22 = find.byKey(const Key('advanced-health-feature-M22'));
    final m20Offset = tester.getTopLeft(m20);
    final m21Offset = tester.getTopLeft(m21);
    final m22Offset = tester.getTopLeft(m22);
    expect(m21Offset.dy, moreOrLessEquals(m20Offset.dy, epsilon: .1));
    expect(m22Offset.dy, greaterThan(m20Offset.dy));
    expect(m20Offset.dx, lessThan(m21Offset.dx));
    expect(tester.getSize(m20).height, lessThan(175));

    expect(find.text('Miễn phí'), findsNWidgets(3));
    expect(find.text('Plus'), findsNWidgets(7));
    expect(find.text('Đang phát triển'), findsNWidgets(10));
  });

  testWidgets('advanced feature tile opens the shared dynamic route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/features',
      routes: [
        GoRoute(
          path: '/features',
          builder: (context, state) => const FeaturesHubPage(),
        ),
        GoRoute(
          path: '/v2/health-modules/:moduleId',
          builder: (context, state) => Scaffold(
            body: Text('opened-${state.pathParameters['moduleId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final advancedToggle = find.byKey(
      const Key('advanced-health-features-toggle'),
    );
    await tester.scrollUntilVisible(
      advancedToggle,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(advancedToggle);
    await tester.pumpAndSettle();

    final m20Tile = find.byKey(const Key('advanced-health-feature-M20'));
    await tester.scrollUntilVisible(
      m20Tile,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(m20Tile);
    await tester.pumpAndSettle();
    await tester.tap(m20Tile);
    await tester.pumpAndSettle();

    expect(find.text('opened-M20'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 800),
    const Size(360, 800),
    const Size(390, 844),
    const Size(1200, 900),
  ]) {
    testWidgets('does not overflow at ${size.width.toInt()}px width', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));
      await tester.pump();

      final advancedToggle = find.byKey(
        const Key('advanced-health-features-toggle'),
      );
      await tester.scrollUntilVisible(
        advancedToggle,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(advancedToggle);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('advanced-health-feature-M29')),
        700,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('advanced-health-feature-M29')),
        findsOneWidget,
      );
    });
  }

  testWidgets('compact grid stays usable with increased text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const FeaturesHubPage(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('feature-tile-nabi-care')), findsOneWidget);
    final aiVoice = find.byKey(const Key('feature-tile-ai-voice'));
    if (aiVoice.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        aiVoice,
        240,
        scrollable: find.byType(Scrollable).first,
      );
    }
    expect(aiVoice, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
