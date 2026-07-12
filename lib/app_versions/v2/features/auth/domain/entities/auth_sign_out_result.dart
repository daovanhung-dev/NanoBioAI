class AuthSignOutResult {
  final bool signedOut;
  final bool requiresForce;
  final int pendingCount;
  final String? message;

  const AuthSignOutResult({
    required this.signedOut,
    required this.requiresForce,
    required this.pendingCount,
    this.message,
  });

  const AuthSignOutResult.completed()
    : signedOut = true,
      requiresForce = false,
      pendingCount = 0,
      message = null;

  const AuthSignOutResult.confirmForce({
    required this.pendingCount,
    required this.message,
  }) : signedOut = false,
       requiresForce = true;
}
