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
  final String subscriptionTier;
  final String? message;

  const AuthRouteState._({
    required this.status,
    this.userId,
    this.email,
    this.subscriptionTier = 'free',
    this.message,
  });

  const AuthRouteState.initializing()
    : this._(status: AuthRouteStatus.initializing);

  const AuthRouteState.unauthenticated()
    : this._(status: AuthRouteStatus.unauthenticated);

  const AuthRouteState.emailVerificationRequired({
    String? email,
    String subscriptionTier = 'free',
  }) : this._(
         status: AuthRouteStatus.emailVerificationRequired,
         email: email,
         subscriptionTier: subscriptionTier,
       );

  const AuthRouteState.onboardingRequired({
    required String userId,
    String? email,
    String subscriptionTier = 'free',
  }) : this._(
         status: AuthRouteStatus.onboardingRequired,
         userId: userId,
         email: email,
         subscriptionTier: subscriptionTier,
       );

  const AuthRouteState.authenticatedReady({
    required String userId,
    String? email,
    String subscriptionTier = 'free',
  }) : this._(
         status: AuthRouteStatus.authenticatedReady,
         userId: userId,
         email: email,
         subscriptionTier: subscriptionTier,
       );

  const AuthRouteState.profileBootstrapUnavailable({
    required String userId,
    String? email,
    String subscriptionTier = 'free',
  }) : this._(
         status: AuthRouteStatus.profileBootstrapUnavailable,
         userId: userId,
         email: email,
         subscriptionTier: subscriptionTier,
       );

  const AuthRouteState.failure(String message)
    : this._(status: AuthRouteStatus.failure, message: message);
}
