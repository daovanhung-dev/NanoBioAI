import '../entities/sleep_safety_event.dart';
import '../entities/sleep_safety_session.dart';

class SleepSafetyCandidate {
  const SleepSafetyCandidate({required this.id, required this.type, required this.relativeEnergy, required this.baselineDelta, required this.confidence, required this.repetitionCount, required this.detectedAt});
  final String id;
  final SleepSafetyEventType type;
  final double relativeEnergy;
  final double baselineDelta;
  final double confidence;
  final int repetitionCount;
  final DateTime detectedAt;
}

class SleepSafetyDetectionDecision {
  const SleepSafetyDetectionDecision({required this.confirmed, required this.severity});
  final bool confirmed;
  final String severity;
}

/// Experimental non-medical fusion policy. Rollout remains disabled until
/// these numeric bands are benchmarked on Android/iOS devices.
class SleepSafetyDetectionPolicy {
  const SleepSafetyDetectionPolicy();
  SleepSafetyDetectionDecision evaluate(SleepSafetyCandidate candidate, SleepSafetySensitivity sensitivity) {
    final energyFloor = switch (sensitivity) {
      SleepSafetySensitivity.low => 4.4,
      SleepSafetySensitivity.balanced => 3.2,
      SleepSafetySensitivity.high => 2.5,
    };
    final confidenceFloor = switch (sensitivity) {
      SleepSafetySensitivity.low => 0.78,
      SleepSafetySensitivity.balanced => 0.66,
      SleepSafetySensitivity.high => 0.58,
    };
    final repetitionBoost = candidate.repetitionCount >= 3 ? 0.1 : 0.0;
    final confirmed = candidate.relativeEnergy >= energyFloor && candidate.confidence + repetitionBoost >= confidenceFloor;
    final severity = candidate.relativeEnergy >= energyFloor * 1.8 ? 'high' : 'attention';
    return SleepSafetyDetectionDecision(confirmed: confirmed, severity: severity);
  }
}
