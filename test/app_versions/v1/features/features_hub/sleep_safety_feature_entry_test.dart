import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/app_theme.dart';

void main() {
  testWidgets('Sleep Safety is active in FeatureHub and opens its route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const FeaturesHubPage(),
        ),
        GoRoute(
          path: V1RoutePaths.sleepTracking,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('sleep-safety-target')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final activeSleep = find.byKey(
      const Key('feature-tile-sleep-tracking'),
    );
    expect(activeSleep, findsOneWidget);
    expect(find.text('Giám sát giấc ngủ'), findsOneWidget);
    expect(
      find.byKey(const Key('planned-feature-sleep-tracking')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('planned-features-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planned-feature-stress-tracking')), findsOneWidget);
    expect(find.byKey(const Key('planned-feature-community')), findsOneWidget);
    expect(
      find.byKey(const Key('planned-feature-sleep-tracking')),
      findsNothing,
    );

    await tester.ensureVisible(activeSleep);
    await tester.tap(activeSleep);
    await tester.pumpAndSettle();

    expect(find.text('sleep-safety-target'), findsOneWidget);
  });
}
