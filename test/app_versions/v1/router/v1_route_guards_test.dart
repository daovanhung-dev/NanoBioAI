import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_guards.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
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
        V1RoutePaths.lifestyleSchedule,
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
        V1RoutePaths.nutrition,
        V1RoutePaths.profile,
        V1RoutePaths.community,
        V2RoutePaths.home,
      ]) {
        expect(
          V1RouteGuards.isGuestAllowedPath(path),
          isFalse,
          reason: '$path should require auth/access before opening',
        );
      }
    });
  });
}
