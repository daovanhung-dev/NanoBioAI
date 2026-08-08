import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/auth.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';
import 'package:nano_app/app_versions/v3/router/v3_route_paths.dart';
import 'package:nano_app/app_versions/v3/router/v3_router.dart';

void main() {
  test('standalone V3 router includes the V1 lifestyle schedule deep link', () {
    final standalonePaths = v3StandaloneRoutes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();
    final embeddedV3Paths = v3Routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();

    expect(standalonePaths, contains(V1RoutePaths.lifestyleSchedule));
    expect(embeddedV3Paths, isNot(contains(V1RoutePaths.lifestyleSchedule)));
    expect(standalonePaths, contains(V2RoutePaths.login));
    expect(embeddedV3Paths, isNot(contains(V2RoutePaths.login)));
    expect(standalonePaths, contains(V3RoutePaths.familyPlus));
    expect(embeddedV3Paths, contains(V3RoutePaths.familyPlus));
  });

  testWidgets('FamilyPlus login action resolves in the standalone router', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: V3RoutePaths.familyPlus,
      routes: v3StandaloneRoutes,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyPlusContextProvider.overrideWith(
            (ref) async => const FamilyPlusViewModel.authRequired(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final authRequiredState = find.byKey(
      const ValueKey<String>('familyplus-auth-required'),
    );
    final loginAction = find.descendant(
      of: authRequiredState,
      matching: find.byType(FilledButton),
    );
    expect(loginAction, findsOneWidget);

    await tester.tap(loginAction);
    await tester.pumpAndSettle();

    expect(find.byType(V2LoginPage), findsOneWidget);
  });
}
