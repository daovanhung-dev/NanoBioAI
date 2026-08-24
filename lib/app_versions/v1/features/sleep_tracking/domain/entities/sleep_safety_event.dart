enum SleepSafetyEventType { suddenLoudSound, strongImpact, abnormalShout, abnormalScream, repeatedSuspiciousPattern, unknownHighEnergyEvent }
enum SleepSafetyResponse { none, ok, needHelp, noResponse }
enum SleepSafetyEscalationStatus { notRequired, pending, dispatching, accepted, failed }

class SleepSafetyEvent {
  const SleepSafetyEvent({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.detectedAt,
    required this.eventType,
    required this.severity,
    required this.confidence,
    required this.relativeEnergy,
    required this.baselineDelta,
    required this.repetitionCount,
    required this.state,
    required this.response,
    required this.escalationRequired,
    required this.escalationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.responseAt,
  });
  final String id;
  final String sessionId;
  final String userId;
  final DateTime detectedAt;
  final SleepSafetyEventType eventType;
  final String severity;
  final double confidence;
  final double relativeEnergy;
  final double baselineDelta;
  final int repetitionCount;
  final String state;
  final SleepSafetyResponse response;
  final DateTime? responseAt;
  final bool escalationRequired;
  final SleepSafetyEscalationStatus escalationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}
