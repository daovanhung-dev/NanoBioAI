import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

void main() {
  const currentFeatureTitles = [
    'Lịch trình cá nhân',
    'Nhiệm vụ hôm nay',
    'Thực đơn theo tuần',
    'Dinh dưỡng',
    'Chỉ số cơ thể',
    'Giấc ngủ',
    'Cảm xúc & stress',
    'Cộng đồng chăm sóc',
    'Trò chuyện với Nabi',
  ];

  testWidgets('renders 19 tools in current and advanced sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));

    expect(find.text('Chăm sức khỏe theo cách dễ hiểu'), findsOneWidget);
    expect(find.text('19 công cụ'), findsOneWidget);
    expect(find.byKey(const Key('current-features-section')), findsOneWidget);

    for (final title in currentFeatureTitles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    await tester.scrollUntilVisible(
      find.byKey(const Key('advanced-health-features-section')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('advanced-health-features-section')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('advanced-health-feature-M20')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    for (final item in advancedHealthFeatureCatalog) {
      expect(find.text(item.title), findsOneWidget, reason: item.moduleId);
      expect(
        find.byKey(Key('advanced-health-feature-${item.moduleId}')),
        findsOneWidget,
        reason: item.moduleId,
      );
    }

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

  for (final size in [const Size(360, 800), const Size(1200, 900)]) {
    testWidgets('does not overflow at ${size.width.toInt()}px width', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));
      await tester.pump();
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
}
