import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';

void main() {
  testWidgets('entry page routes to login or guest onboarding', (tester) async {
    final router = GoRouter(
      initialLocation: V1RoutePaths.onboardingEntry,
      routes: [
        GoRoute(
          path: V1RoutePaths.onboardingEntry,
          builder: (context, state) => const OnboardingEntryPage(),
        ),
        GoRoute(
          path: V2RoutePaths.login,
          builder: (context, state) => const Scaffold(body: Text('login')),
        ),
        GoRoute(
          path: V1RoutePaths.onboarding,
          builder: (context, state) => const Scaffold(body: Text('onboarding')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byKey(const Key('onboarding_entry_login_cta')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_entry_guest_cta')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_entry_login_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('login'), findsOneWidget);

    router.go(V1RoutePaths.onboardingEntry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('onboarding_entry_guest_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('onboarding'), findsOneWidget);
  });
}
