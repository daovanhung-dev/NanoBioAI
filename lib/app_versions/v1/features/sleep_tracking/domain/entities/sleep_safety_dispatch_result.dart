enum SleepSafetyDispatchRoute {
  cloudAccepted,
  cloudFailed,
  phoneFallbackRequired,
  dialerOpened,
  retryQueued,
  retryExpired,
}

class SleepSafetyDispatchResult {
  const SleepSafetyDispatchResult({
    required this.route,
    this.idempotencyKey,
    this.errorCode,
  });

  final SleepSafetyDispatchRoute route;
  final String? idempotencyKey;
  final String? errorCode;
}
