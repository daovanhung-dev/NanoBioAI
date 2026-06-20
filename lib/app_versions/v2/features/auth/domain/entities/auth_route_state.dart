enum AuthRouteStatus {
  initializing,
  unauthenticated,
  emailVerificationRequired,
  onboardingRequired,
  authenticatedReady,
  profileBootstrapUnavailable,
  failure,
}

class AuthRouteState {
  final AuthRouteStatus status;
  final String? userId;
  final String? email;
  final String? message;

  const AuthRouteState._({
    required this.status,
    this.userId,
    this.email,
    this.message,
  });

  const AuthRouteState.initializing()
    : this._(status: AuthRouteStatus.initializing);

  const AuthRouteState.unauthenticated()
    : this._(status: AuthRouteStatus.unauthenticated);

  const AuthRouteState.emailVerificationRequired({String? email})
    : this._(status: AuthRouteStatus.emailVerificationRequired, email: email);

  const AuthRouteState.onboardingRequired({required String userId})
    : this._(status: AuthRouteStatus.onboardingRequired, userId: userId);

  const AuthRouteState.authenticatedReady({required String userId})
    : this._(status: AuthRouteStatus.authenticatedReady, userId: userId);

  const AuthRouteState.profileBootstrapUnavailable({required String userId})
    : this._(
        status: AuthRouteStatus.profileBootstrapUnavailable,
        userId: userId,
      );

  const AuthRouteState.failure(String message)
    : this._(status: AuthRouteStatus.failure, message: message);
}
