import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';

void main() {
  const resolver = AuthRouteStateResolver();
  const session = AuthSessionSnapshot(
    userId: 'user-1',
    email: 'nami@example.com',
    emailConfirmed: true,
  );

  test('maps missing session to unauthenticated', () {
    final state = resolver.resolve(
      session: null,
      profile: null,
      requiresEmailConfirmation: true,
    );

    expect(state.status, AuthRouteStatus.unauthenticated);
  });

  test('maps unverified email to verification route state', () {
    final state = resolver.resolve(
      session: const AuthSessionSnapshot(
        userId: 'user-1',
        email: 'nami@example.com',
        emailConfirmed: false,
      ),
      profile: const AuthProfile(id: 'user-1', onboardingStatus: 'completed'),
      requiresEmailConfirmation: true,
    );

    expect(state.status, AuthRouteStatus.emailVerificationRequired);
    expect(state.email, 'nami@example.com');
  });

  test('maps missing profile to bootstrap unavailable', () {
    final state = resolver.resolve(
      session: session,
      profile: null,
      requiresEmailConfirmation: true,
    );

    expect(state.status, AuthRouteStatus.profileBootstrapUnavailable);
    expect(state.userId, 'user-1');
  });

  test('maps pending onboarding statuses to onboarding required', () {
    for (final status in ['not_started', 'in_progress']) {
      final state = resolver.resolve(
        session: session,
        profile: AuthProfile(id: 'user-1', onboardingStatus: status),
        requiresEmailConfirmation: true,
      );

      expect(state.status, AuthRouteStatus.onboardingRequired);
    }
  });

  test('maps completed onboarding to authenticated ready', () {
    final state = resolver.resolve(
      session: session,
      profile: const AuthProfile(id: 'user-1', onboardingStatus: 'completed'),
      requiresEmailConfirmation: true,
    );

    expect(state.status, AuthRouteStatus.authenticatedReady);
    expect(state.userId, 'user-1');
  });

  test('maps unknown onboarding status to failure', () {
    final state = resolver.resolve(
      session: session,
      profile: const AuthProfile(id: 'user-1', onboardingStatus: 'paused'),
      requiresEmailConfirmation: true,
    );

    expect(state.status, AuthRouteStatus.failure);
  });
}
