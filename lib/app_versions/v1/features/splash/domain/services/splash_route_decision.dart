enum SplashRouteTarget { authGate, onboardingEntry, onboarding, menu }

class SplashRouteDecision {
  const SplashRouteDecision();

  SplashRouteTarget resolve({
    required bool hasAuthenticatedSession,
    required bool onboardingCompleted,
  }) {
    if (hasAuthenticatedSession) {
      return SplashRouteTarget.authGate;
    }

    return onboardingCompleted
        ? SplashRouteTarget.menu
        : SplashRouteTarget.onboardingEntry;
  }
}
