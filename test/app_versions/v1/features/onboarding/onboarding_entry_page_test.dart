import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';

void main() {
  testWidgets('entry actions slide in from opposite sides', (tester) async {
    final router = GoRouter(
      initialLocation: V1RoutePaths.onboardingEntry,
      routes: [
        GoRoute(
          path: V1RoutePaths.onboardingEntry,
          builder: (context, state) => const OnboardingEntryPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    final guestCenter = tester.getCenter(
      find.byKey(const Key('onboarding_entry_guest_card')),
    );
    final loginCenter = tester.getCenter(
      find.byKey(const Key('onboarding_entry_login_card')),
    );
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final centerX = screenWidth / 2;
    expect(guestCenter.dx, lessThan(0));
    expect(loginCenter.dx, greaterThan(screenWidth));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getCenter(find.byKey(const Key('onboarding_entry_guest_card'))).dx,
      closeTo(centerX, 1),
    );
    expect(
      tester.getCenter(find.byKey(const Key('onboarding_entry_login_card'))).dx,
      closeTo(centerX, 1),
    );

    router.dispose();
  });

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
          builder: (context, state) => const OnboardingPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('onboarding_entry_login_cta')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_entry_guest_cta')), findsOneWidget);

    final loginCta = find.byKey(const Key('onboarding_entry_login_cta'));
    await tester.ensureVisible(loginCta);
    await tester.pump();
    await tester.tap(loginCta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('login'), findsOneWidget);

    router.go(V1RoutePaths.onboardingEntry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final guestCta = find.byKey(const Key('onboarding_entry_guest_cta'));
    await tester.ensureVisible(guestCta);
    await tester.pump();
    await tester.tap(guestCta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chào bạn, mình là Nabi'), findsOneWidget);
    final welcomeMotion = find.byKey(
      const Key('onboarding_welcome_hero_motion'),
    );
    expect(welcomeMotion, findsOneWidget);
    final welcomeFade = find
        .descendant(of: welcomeMotion, matching: find.byType(FadeTransition))
        .first;
    expect(tester.widget<FadeTransition>(welcomeFade).opacity.value, 1);

    final welcomeCta = find.descendant(
      of: find.byType(OnboardingPage),
      matching: find.text('Bắt đầu'),
    );
    await tester.ensureVisible(welcomeCta);
    await tester.tap(welcomeCta);
    await tester.pump();
    expect(find.text('Để Nabi hiểu bạn'), findsOneWidget);
  });
}
