import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/splash/domain/services/splash_route_decision.dart';

void main() {
  const decision = SplashRouteDecision();

  test('routes authenticated users to AuthGate', () {
    final target = decision.resolve(
      hasAuthenticatedSession: true,
      onboardingCompleted: false,
    );

    expect(target, SplashRouteTarget.authGate);
  });

  test('routes completed guests to menu', () {
    final target = decision.resolve(
      hasAuthenticatedSession: false,
      onboardingCompleted: true,
    );

    expect(target, SplashRouteTarget.menu);
  });

  test('routes new guests to onboarding entry', () {
    final target = decision.resolve(
      hasAuthenticatedSession: false,
      onboardingCompleted: false,
    );

    expect(target, SplashRouteTarget.onboardingEntry);
  });
}
