import 'sleep_safety_session.dart';

class SleepSafetyPreference {
  const SleepSafetyPreference({
    required this.userId,
    required this.enabled,
    required this.sensitivity,
    required this.scheduleEnabled,
    required this.scheduleStartMinutes,
    required this.scheduleEndMinutes,
    required this.timezone,
    required this.selectedWeekdays,
    required this.calibrationRequired,
    required this.cooldownSeconds,
    required this.consentVersion,
    required this.updatedAt,
    this.calibrationNoiseFloor,
    this.calibrationUpdatedAt,
  });

  factory SleepSafetyPreference.defaults(String userId) => SleepSafetyPreference(
    userId: userId,
    enabled: true,
    sensitivity: SleepSafetySensitivity.balanced,
    scheduleEnabled: false,
    scheduleStartMinutes: 1350,
    scheduleEndMinutes: 390,
    timezone: 'Asia/Ho_Chi_Minh',
    selectedWeekdays: const <int>{1, 2, 3, 4, 5, 6, 7},
    calibrationRequired: true,
    cooldownSeconds: 120,
    consentVersion: 'sleep-safety-v1',
    updatedAt: DateTime.now(),
  );

  final String userId;
  final bool enabled;
  final SleepSafetySensitivity sensitivity;
  final bool scheduleEnabled;
  final int scheduleStartMinutes;
  final int scheduleEndMinutes;
  final String timezone;
  final Set<int> selectedWeekdays;
  final bool calibrationRequired;
  final int cooldownSeconds;
  final String consentVersion;
  final DateTime updatedAt;
  final double? calibrationNoiseFloor;
  final DateTime? calibrationUpdatedAt;

  SleepSafetyPreference copyWith({
    bool? enabled,
    SleepSafetySensitivity? sensitivity,
    bool? scheduleEnabled,
    int? scheduleStartMinutes,
    int? scheduleEndMinutes,
    String? timezone,
    Set<int>? selectedWeekdays,
    bool? calibrationRequired,
    int? cooldownSeconds,
    String? consentVersion,
    DateTime? updatedAt,
    double? calibrationNoiseFloor,
    DateTime? calibrationUpdatedAt,
  }) => SleepSafetyPreference(
    userId: userId,
    enabled: enabled ?? this.enabled,
    sensitivity: sensitivity ?? this.sensitivity,
    scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
    scheduleStartMinutes: scheduleStartMinutes ?? this.scheduleStartMinutes,
    scheduleEndMinutes: scheduleEndMinutes ?? this.scheduleEndMinutes,
    timezone: timezone ?? this.timezone,
    selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
    calibrationRequired: calibrationRequired ?? this.calibrationRequired,
    cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    consentVersion: consentVersion ?? this.consentVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    calibrationNoiseFloor: calibrationNoiseFloor ?? this.calibrationNoiseFloor,
    calibrationUpdatedAt: calibrationUpdatedAt ?? this.calibrationUpdatedAt,
  );
}
