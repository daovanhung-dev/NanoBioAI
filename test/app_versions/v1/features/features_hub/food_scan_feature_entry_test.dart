import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/core/constants/routes/food_scan_route_paths.dart';
import 'package:nano_app/core/theme/app_theme.dart';

void main() {
  testWidgets('Food Scan is active in FeatureHub and opens its shared route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const FeaturesHubPage(),
        ),
        GoRoute(
          path: FoodScanRoutePaths.scan,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('food-scan-target')),
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

    final foodScanTile = find.byKey(const Key('feature-tile-food-scan'));
    expect(foodScanTile, findsOneWidget);
    expect(find.text('Quét món ăn AI'), findsOneWidget);
    expect(find.byKey(const Key('planned-feature-food-scan')), findsNothing);

    await tester.ensureVisible(foodScanTile);
    await tester.tap(foodScanTile);
    await tester.pumpAndSettle();

    expect(find.text('food-scan-target'), findsOneWidget);
  });
}
