import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/app_theme.dart';

void main() {
  testWidgets('M32 is an active FeatureHub tile and opens its route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const FeaturesHubPage()),
        GoRoute(
          path: V1RoutePaths.fitnessTraining,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('fitness-training-target')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const Key('feature-tile-fitness-training'));
    expect(tile, findsOneWidget);
    expect(find.text('Chế độ luyện tập'), findsOneWidget);
    expect(
      find.byKey(const Key('planned-feature-fitness-training')),
      findsNothing,
    );
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('fitness-training-target'), findsOneWidget);
  });
}
