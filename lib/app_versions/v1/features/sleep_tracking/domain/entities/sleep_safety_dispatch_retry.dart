class SleepSafetyDispatchRetry {
  const SleepSafetyDispatchRetry({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.idempotencyKey,
    required this.createdAt,
    required this.attemptCount,
    required this.status,
    this.nextRetryAt,
    this.lastErrorCode,
  });

  final String id;
  final String userId;
  final String eventId;
  final String idempotencyKey;
  final DateTime createdAt;
  final int attemptCount;
  final String status;
  final DateTime? nextRetryAt;
  final String? lastErrorCode;
}
