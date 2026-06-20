import '../entities/auth_profile.dart';
import '../entities/auth_route_state.dart';

class AuthRouteStateResolver {
  const AuthRouteStateResolver();

  AuthRouteState resolve({
    required AuthSessionSnapshot? session,
    required AuthProfile? profile,
    required bool requiresEmailConfirmation,
    bool profileLoadFailed = false,
  }) {
    if (session == null) {
      return const AuthRouteState.unauthenticated();
    }

    if (requiresEmailConfirmation && !session.emailConfirmed) {
      return AuthRouteState.emailVerificationRequired(email: session.email);
    }

    if (profileLoadFailed || profile == null) {
      return AuthRouteState.profileBootstrapUnavailable(userId: session.userId);
    }

    switch (profile.onboardingStatus) {
      case 'completed':
        return AuthRouteState.authenticatedReady(userId: session.userId);
      case 'not_started':
      case 'in_progress':
        return AuthRouteState.onboardingRequired(userId: session.userId);
      default:
        return const AuthRouteState.failure(
          'Nami chưa xác định được trạng thái tài khoản lúc này.',
        );
    }
  }
}
