import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/app_versions/v2/router/v2_router.dart';

void main() {
  group('shipping router V1 guest policy', () {
    test('preserves V1 guest allowlist in composed router', () {
      for (final path in [
        V1RoutePaths.dashboard,
        V1RoutePaths.mealPlan,
        V1RoutePaths.lifestyleSchedule,
        V1RoutePaths.dailyRoutinePreferences,
      ]) {
        expect(
          V2RouteGuards.redirectForV1Guest(path, isSignedIn: false),
          isNull,
        );
      }
    });

    test('blocks authenticated-only V1 routes for guest', () {
      for (final path in [
        V1RoutePaths.aiChat,
        V1RoutePaths.aiVoice,
        V1RoutePaths.nutrition,
        V1RoutePaths.profile,
        V1RoutePaths.community,
      ]) {
        expect(
          V2RouteGuards.redirectForV1Guest(path, isSignedIn: false),
          V2RoutePaths.login,
        );
      }
    });

    test('signed-in sessions are not redirected by V1 guest policy', () {
      expect(
        V2RouteGuards.redirectForV1Guest(
          V1RoutePaths.community,
          isSignedIn: true,
        ),
        isNull,
      );
    });
  });
}
