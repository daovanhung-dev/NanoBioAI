enum SleepSafetySensitivity { low, balanced, high }

enum SleepSafetySessionStatus { idle, arming, calibrating, monitoring, alerting, escalating, stopped, failed }

class SleepSafetySession {
  const SleepSafetySession({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.sensitivity,
    required this.status,
    required this.startSource,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.updatedAt,
    this.endedAt,
    this.scheduledWindowStart,
    this.scheduledWindowEnd,
    this.calibrationNoiseFloor,
    this.stopReason,
  });
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? scheduledWindowStart;
  final DateTime? scheduledWindowEnd;
  final SleepSafetySensitivity sensitivity;
  final double? calibrationNoiseFloor;
  final SleepSafetySessionStatus status;
  final String startSource;
  final String? stopReason;
  final String platform;
  final String appVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
}
