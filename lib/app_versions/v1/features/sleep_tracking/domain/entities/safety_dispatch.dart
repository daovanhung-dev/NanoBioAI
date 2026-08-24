enum SafetyDispatchChannel { sms, voice }
enum SafetyDispatchStatus { queued, submitted, delivered, answered, failed, noAnswer, cancelled }

class SafetyDispatch {
  const SafetyDispatch({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.contactId,
    required this.priority,
    required this.channel,
    required this.provider,
    required this.status,
    required this.attempt,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    this.providerExternalId,
    this.failureCode,
  });
  final String id;
  final String eventId;
  final String userId;
  final String contactId;
  final int priority;
  final SafetyDispatchChannel channel;
  final String provider;
  final String? providerExternalId;
  final SafetyDispatchStatus status;
  final int attempt;
  final String idempotencyKey;
  final String? failureCode;
  final DateTime createdAt;
  final DateTime updatedAt;
}
