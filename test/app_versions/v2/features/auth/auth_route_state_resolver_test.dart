import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';

void main() {
  const resolver = AuthRouteStateResolver();
  const session = AuthSessionSnapshot(
    userId: 'user-1',
    email: 'legacy-contact@example.com',
  );

  test('maps missing session to unauthenticated', () {
    final state = resolver.resolve(session: null, profile: null);
    expect(state.status, AuthRouteStatus.unauthenticated);
  });

  test('routes accounts requiring an approved password change first', () {
    final state = resolver.resolve(
      session: const AuthSessionSnapshot(
        userId: 'user-1',
        mustChangePassword: true,
      ),
      profile: const AuthProfile(
        id: 'user-1',
        onboardingStatus: 'completed',
        subscriptionTier: 'plus',
      ),
    );

    expect(state.status, AuthRouteStatus.passwordChangeRequired);
    expect(state.userId, 'user-1');
    expect(state.subscriptionTier, 'plus');
  });

  test('maps missing profile to bootstrap unavailable', () {
    final state = resolver.resolve(session: session, profile: null);
    expect(state.status, AuthRouteStatus.profileBootstrapUnavailable);
    expect(state.userId, 'user-1');
    expect(state.email, 'legacy-contact@example.com');
  });

  test('maps pending onboarding statuses to onboarding required', () {
    for (final status in ['not_started', 'in_progress']) {
      final state = resolver.resolve(
        session: session,
        profile: AuthProfile(id: 'user-1', onboardingStatus: status),
      );
      expect(state.status, AuthRouteStatus.onboardingRequired);
    }
  });

  test('maps completed onboarding to authenticated ready', () {
    final state = resolver.resolve(
      session: session,
      profile: const AuthProfile(
        id: 'user-1',
        onboardingStatus: 'completed',
        subscriptionTier: 'familyplus',
      ),
    );

    expect(state.status, AuthRouteStatus.authenticatedReady);
    expect(state.userId, 'user-1');
    expect(state.email, 'legacy-contact@example.com');
    expect(state.subscriptionTier, 'familyplus');
  });

  test('maps unknown onboarding status to failure', () {
    final state = resolver.resolve(
      session: session,
      profile: const AuthProfile(id: 'user-1', onboardingStatus: 'paused'),
    );
    expect(state.status, AuthRouteStatus.failure);
  });

  test('normalizes missing subscription tier to free', () {
    final profile = AuthProfile.fromMap({
      'id': 'user-1',
      'onboarding_status': 'completed',
      'subscription_tier': '',
    });
    expect(profile.subscriptionTier, 'free');
  });
}
