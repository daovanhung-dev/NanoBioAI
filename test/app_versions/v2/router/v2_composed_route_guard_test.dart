import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
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

  group('membership payment access policy', () {
    test('keeps membership payment protected from guests', () {
      expect(V2RouteGuards.isProtectedPath(V2RoutePaths.payments), isTrue);
      expect(
        V2RouteGuards.canAccessMembershipPayment(
          V2RoutePaths.payments,
          isSignedIn: false,
          authStatus: AuthRouteStatus.unauthenticated,
        ),
        isFalse,
      );
    });

    test('allows a signed-in user whose onboarding is still pending', () {
      expect(
        V2RouteGuards.canAccessMembershipPayment(
          V2RoutePaths.payments,
          isSignedIn: true,
          authStatus: AuthRouteStatus.onboardingRequired,
        ),
        isTrue,
      );
    });

    test('allows an authenticated-ready user', () {
      expect(
        V2RouteGuards.canAccessMembershipPayment(
          V2RoutePaths.payments,
          isSignedIn: true,
          authStatus: AuthRouteStatus.authenticatedReady,
        ),
        isTrue,
      );
    });

    test('does not bypass unresolved or unverified auth states', () {
      for (final status in [
        AuthRouteStatus.initializing,
        AuthRouteStatus.emailVerificationRequired,
        AuthRouteStatus.profileBootstrapUnavailable,
        AuthRouteStatus.failure,
      ]) {
        expect(
          V2RouteGuards.canAccessMembershipPayment(
            V2RoutePaths.payments,
            isSignedIn: true,
            authStatus: status,
          ),
          isFalse,
          reason: status.name,
        );
      }
    });

    test('does not apply the payment exception to other protected routes', () {
      expect(
        V2RouteGuards.canAccessMembershipPayment(
          V2RoutePaths.healthScore,
          isSignedIn: true,
          authStatus: AuthRouteStatus.onboardingRequired,
        ),
        isFalse,
      );
    });
  });
}
