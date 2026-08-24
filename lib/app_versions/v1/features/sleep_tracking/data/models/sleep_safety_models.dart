import 'dart:convert';
import '../../domain/entities/safety_contact.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../domain/entities/sleep_safety_preference.dart';
import '../../domain/entities/sleep_safety_session.dart';

class SleepSafetyModelMapper {
  const SleepSafetyModelMapper._();
  static Map<String, Object?> preferenceToMap(SleepSafetyPreference value) => {
    'user_id': value.userId,
    'enabled': value.enabled ? 1 : 0,
    'sensitivity': value.sensitivity.name,
    'schedule_enabled': value.scheduleEnabled ? 1 : 0,
    'schedule_start_minutes': value.scheduleStartMinutes,
    'schedule_end_minutes': value.scheduleEndMinutes,
    'timezone': value.timezone,
    'selected_weekdays_json': jsonEncode(value.selectedWeekdays.toList()..sort()),
    'calibration_required': value.calibrationRequired ? 1 : 0,
    'calibration_noise_floor': value.calibrationNoiseFloor,
    'calibration_updated_at': value.calibrationUpdatedAt?.toIso8601String(),
    'cooldown_seconds': value.cooldownSeconds,
    'consent_version': value.consentVersion,
    'updated_at': value.updatedAt.toIso8601String(),
  };
  static SleepSafetyPreference preferenceFromMap(Map<String, Object?> row) {
    final weekdays = <int>{};
    final raw = row['selected_weekdays_json']?.toString();
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) { if (item is num) weekdays.add(item.toInt()); }
      }
    }
    return SleepSafetyPreference(
      userId: row['user_id'].toString(),
      enabled: row['enabled'] == 1 || row['enabled'] == true,
      sensitivity: _enumByName(SleepSafetySensitivity.values, row['sensitivity']?.toString(), SleepSafetySensitivity.balanced),
      scheduleEnabled: row['schedule_enabled'] == 1 || row['schedule_enabled'] == true,
      scheduleStartMinutes: (row['schedule_start_minutes'] as num?)?.toInt() ?? 1350,
      scheduleEndMinutes: (row['schedule_end_minutes'] as num?)?.toInt() ?? 390,
      timezone: row['timezone']?.toString() ?? 'Asia/Ho_Chi_Minh',
      selectedWeekdays: weekdays.isEmpty ? const {1,2,3,4,5,6,7} : weekdays,
      calibrationRequired: row['calibration_required'] != 0 && row['calibration_required'] != false,
      cooldownSeconds: (row['cooldown_seconds'] as num?)?.toInt() ?? 120,
      consentVersion: row['consent_version']?.toString() ?? 'sleep-safety-v1',
      updatedAt: _date(row['updated_at']) ?? DateTime.now(),
      calibrationNoiseFloor: (row['calibration_noise_floor'] as num?)?.toDouble(),
      calibrationUpdatedAt: _date(row['calibration_updated_at']),
    );
  }
  static Map<String, Object?> sessionToMap(SleepSafetySession value) => {
    'id': value.id, 'user_id': value.userId, 'started_at': value.startedAt.toIso8601String(),
    'ended_at': value.endedAt?.toIso8601String(), 'scheduled_window_start': value.scheduledWindowStart?.toIso8601String(),
    'scheduled_window_end': value.scheduledWindowEnd?.toIso8601String(), 'sensitivity': value.sensitivity.name,
    'calibration_noise_floor': value.calibrationNoiseFloor, 'status': value.status.name, 'start_source': value.startSource,
    'stop_reason': value.stopReason, 'platform': value.platform, 'app_version': value.appVersion,
    'created_at': value.createdAt.toIso8601String(), 'updated_at': value.updatedAt.toIso8601String(),
  };
  static SleepSafetySession sessionFromMap(Map<String, Object?> row) => SleepSafetySession(
    id: row['id'].toString(),
    userId: row['user_id'].toString(),
    startedAt: _date(row['started_at']) ?? DateTime.now(),
    endedAt: _date(row['ended_at']),
    scheduledWindowStart: _date(row['scheduled_window_start']),
    scheduledWindowEnd: _date(row['scheduled_window_end']),
    sensitivity: _enumByName(
      SleepSafetySensitivity.values,
      row['sensitivity']?.toString(),
      SleepSafetySensitivity.balanced,
    ),
    calibrationNoiseFloor: (row['calibration_noise_floor'] as num?)?.toDouble(),
    status: _enumByName(
      SleepSafetySessionStatus.values,
      row['status']?.toString(),
      SleepSafetySessionStatus.stopped,
    ),
    startSource: row['start_source']?.toString() ?? 'manual',
    stopReason: row['stop_reason']?.toString(),
    platform: row['platform']?.toString() ?? 'unknown',
    appVersion: row['app_version']?.toString() ?? 'unknown',
    createdAt: _date(row['created_at']) ?? DateTime.now(),
    updatedAt: _date(row['updated_at']) ?? DateTime.now(),
  );
  static Map<String, Object?> eventToMap(SleepSafetyEvent value) => {
    'id': value.id, 'session_id': value.sessionId, 'user_id': value.userId, 'detected_at': value.detectedAt.toIso8601String(),
    'event_type': value.eventType.name, 'severity': value.severity, 'confidence': value.confidence,
    'relative_energy': value.relativeEnergy, 'baseline_delta': value.baselineDelta, 'repetition_count': value.repetitionCount,
    'state': value.state, 'response': value.response.name, 'response_at': value.responseAt?.toIso8601String(),
    'escalation_required': value.escalationRequired ? 1 : 0, 'escalation_status': value.escalationStatus.name,
    'created_at': value.createdAt.toIso8601String(), 'updated_at': value.updatedAt.toIso8601String(),
  };
  static SleepSafetyEvent eventFromMap(Map<String, Object?> row) => SleepSafetyEvent(
    id: row['id'].toString(), sessionId: row['session_id'].toString(), userId: row['user_id'].toString(),
    detectedAt: _date(row['detected_at']) ?? DateTime.now(),
    eventType: _enumByName(SleepSafetyEventType.values, row['event_type']?.toString(), SleepSafetyEventType.unknownHighEnergyEvent),
    severity: row['severity']?.toString() ?? 'attention', confidence: (row['confidence'] as num?)?.toDouble() ?? 0,
    relativeEnergy: (row['relative_energy'] as num?)?.toDouble() ?? 0, baselineDelta: (row['baseline_delta'] as num?)?.toDouble() ?? 0,
    repetitionCount: (row['repetition_count'] as num?)?.toInt() ?? 1, state: row['state']?.toString() ?? 'detected',
    response: _enumByName(SleepSafetyResponse.values, row['response']?.toString(), SleepSafetyResponse.none), responseAt: _date(row['response_at']),
    escalationRequired: row['escalation_required'] == 1 || row['escalation_required'] == true,
    escalationStatus: _enumByName(SleepSafetyEscalationStatus.values, row['escalation_status']?.toString(), SleepSafetyEscalationStatus.notRequired),
    createdAt: _date(row['created_at']) ?? DateTime.now(), updatedAt: _date(row['updated_at']) ?? DateTime.now(),
  );
  static Map<String, Object?> contactToMap(SafetyContact value) => {
    'id': value.id, 'user_id': value.userId, 'name': value.name, 'relationship': value.relationship,
    'phone_e164': value.phoneE164, 'priority': value.priority, 'verification_status': value.verificationStatus.name,
    'verified_at': value.verifiedAt?.toIso8601String(), 'active': value.active ? 1 : 0,
    'created_at': value.createdAt.toIso8601String(), 'updated_at': value.updatedAt.toIso8601String(),
  };
  static SafetyContact contactFromMap(Map<String, Object?> row) => SafetyContact(
    id: row['id'].toString(), userId: row['user_id'].toString(), name: row['name']?.toString() ?? '',
    relationship: row['relationship']?.toString() ?? '', phoneE164: row['phone_e164']?.toString() ?? '',
    priority: (row['priority'] as num?)?.toInt() ?? 1,
    verificationStatus: _enumByName(SafetyContactVerificationStatus.values, row['verification_status']?.toString(), SafetyContactVerificationStatus.pending),
    verifiedAt: _date(row['verified_at']), active: row['active'] == 1 || row['active'] == true,
    createdAt: _date(row['created_at']) ?? DateTime.now(), updatedAt: _date(row['updated_at']) ?? DateTime.now(),
  );
  static DateTime? _date(Object? raw) { final text=raw?.toString(); return text==null||text.isEmpty?null:DateTime.tryParse(text); }
  static T _enumByName<T extends Enum>(List<T> values, String? raw, T fallback) {
    for (final value in values) { if (value.name == raw) return value; }
    return fallback;
  }
}
