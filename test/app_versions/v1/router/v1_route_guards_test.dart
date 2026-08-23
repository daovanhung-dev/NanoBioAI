import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_guards.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';

void main() {
  group('V1RouteGuards guest allowlist', () {
    test('allows guest V1 baseline and auth routes', () {
      for (final path in [
        V1RoutePaths.splash,
        V1RoutePaths.onboardingEntry,
        V1RoutePaths.onboarding,
        V1RoutePaths.dashboard,
        V1RoutePaths.menu,
        V1RoutePaths.mealPlan,
        V1RoutePaths.healthTracking,
        V1RoutePaths.todayTasks,
        V1RoutePaths.waterTracking,
        V1RoutePaths.weeklySummary,
        V1RoutePaths.personalGoals,
        V1RoutePaths.quickCare,
        V1RoutePaths.gentleCare,
        V1RoutePaths.namiCare,
        V1RoutePaths.bodyMetrics,
        V1RoutePaths.lifestyleSchedule,
        V1RoutePaths.dailyRoutinePreferences,
        V1RoutePaths.sleepTracking,
        V1RoutePaths.stressTracking,
        AuthRoutePaths.login,
        AuthRoutePaths.register,
      ]) {
        expect(
          V1RouteGuards.isGuestAllowedPath(path),
          isTrue,
          reason: '$path should stay available to guest/auth flow',
        );
      }
    });

    test('blocks guest routes outside V1 baseline', () {
      for (final path in [
        V1RoutePaths.aiChat,
        V1RoutePaths.aiVoice,
        V1RoutePaths.nutrition,
        V1RoutePaths.nutritionProfile,
        V1RoutePaths.profile,
        V1RoutePaths.community,
        V2RoutePaths.home,
        V2RoutePaths.healthScore,
      ]) {
        expect(
          V1RouteGuards.isGuestAllowedPath(path),
          isFalse,
          reason: '$path should require auth/access before opening',
        );
      }

      expect(
        V1RouteGuards.guestRedirectForPath(V1RoutePaths.aiVoice),
        AuthRoutePaths.login,
      );
    });

    test('registered V1 route contract contains only live route paths', () {
      expect(V1RouteGuards.registeredV1Paths, contains(V1RoutePaths.dashboard));
      expect(V1RouteGuards.registeredV1Paths, contains(V1RoutePaths.aiChat));
      expect(V1RouteGuards.registeredV1Paths, contains(V1RoutePaths.aiVoice));
      expect(V1RouteGuards.registeredV1Paths, contains(V1RoutePaths.community));
      expect(V1RouteGuards.registeredV1Paths, isNot(contains('/settings')));
      expect(V1RouteGuards.registeredV1Paths, isNot(contains('/admin')));
      expect(V1RouteGuards.registeredV1Paths, isNot(contains('/food-scanner')));
    });

    test('voice route declares the authenticated redirect', () {
      final route = v1Routes.whereType<GoRoute>().singleWhere(
        (route) => route.path == V1RoutePaths.aiVoice,
      );

      expect(route.redirect, same(V1RouteGuards.authGuard));
    });
  });
}
