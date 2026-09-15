import '../../domain/entities/safety_contact.dart';
import '../../domain/entities/sleep_night_analysis.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../domain/entities/sleep_safety_preference.dart';
import '../../domain/entities/sleep_safety_session.dart';
import '../../domain/repositories/sleep_safety_repository.dart';
import '../datasources/sleep_safety_cloud_datasource.dart';
import '../datasources/sleep_safety_local_datasource.dart';
import '../gateways/sleep_safety_native_gateway.dart';

class SleepSafetyRepositoryImpl implements SleepSafetyRepository {
  const SleepSafetyRepositoryImpl({
    required this.local,
    required this.cloud,
    required this.native,
  });

  final SleepSafetyLocalDatasource local;
  final SleepSafetyCloudDatasource cloud;
  final SleepSafetyNativeGateway native;

  @override
  Stream<SleepSafetyNativeEvent> get nativeEvents => native.events;
  @override
  Future<bool> ensureMicrophonePermission() =>
      native.ensureMicrophonePermission();
  @override
  Future<void> startNative(Map<String, Object?> config) =>
      native.startMonitoring(config);
  @override
  Future<void> stopNative(String reason) => native.stopMonitoring(reason);
  @override
  Future<void> respondToAlert(String eventId, String response) =>
      native.respondToAlert(eventId: eventId, response: response);
  @override
  Future<void> dismissAlert(String eventId) =>
      native.dismissAlert(eventId: eventId);
  @override
  Future<void> updateNativeConfig(Map<String, Object?> config) =>
      native.updateRuntimeConfig(config);
  @override
  Future<SleepSafetyPreference> loadPreference(String userId) =>
      local.loadPreference(userId);
  @override
  Future<void> savePreference(SleepSafetyPreference value) async {
    await local.savePreference(value);
    try {
      await cloud.syncRow(
        'sleep_safety_preferences',
        _preferenceCloudMap(value),
      );
    } catch (_) {}
  }

  @override
  Future<SleepSafetySession?> getSession(String id) => local.getSession(id);
  @override
  Future<List<SleepSafetySession>> listSessions(
    String userId, {
    int limit = 14,
  }) => local.listSessions(userId, limit: limit);
  @override
  Future<void> saveSession(SleepSafetySession value) async {
    await local.saveSession(value);
    try {
      await cloud.syncRow('sleep_safety_sessions', _sessionCloudMap(value));
    } catch (_) {}
  }

  @override
  Future<void> updateSession(String id, Map<String, Object?> values) =>
      local.updateSession(id, values);
  @override
  Future<SleepSafetyEvent?> getEvent(String id) => local.getEvent(id);
  @override
  Future<void> saveEvent(SleepSafetyEvent value) async {
    await local.saveEvent(value);
    try {
      await cloud.syncRow('sleep_safety_events', _eventCloudMap(value));
    } catch (_) {}
  }

  @override
  Future<void> updateEvent(String id, Map<String, Object?> values) =>
      local.updateEvent(id, values);
  @override
  Future<List<SleepSafetyEvent>> listEvents(String userId) =>
      local.listEvents(userId);
  @override
  Future<List<SleepSafetyEvent>> listEventsForSession(String sessionId) =>
      local.listEventsForSession(sessionId);
  @override
  Future<SleepNightAnalysis?> getNightAnalysis(String sessionId) =>
      local.getNightAnalysis(sessionId);
  @override
  Future<void> saveNightAnalysis(SleepNightAnalysis analysis) =>
      local.saveNightAnalysis(analysis);
  @override
  Future<List<SafetyContact>> loadContacts(
    String userId, {
    bool refreshCloud = true,
  }) async {
    if (refreshCloud) {
      try {
        final contacts = await cloud.fetchContacts();
        await local.cacheContacts(userId, contacts);
        return contacts;
      } catch (_) {}
    }
    return local.listCachedContacts(userId);
  }

  @override
  Future<SafetyContact> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
  }) async {
    final saved = await cloud.upsertContact(
      id: id,
      name: name,
      relationship: relationship,
      phoneE164: phoneE164,
      priority: priority,
    );
    try {
      await local.cacheContact(saved);
    } catch (_) {
      // Supabase is authoritative; the next refresh can rebuild local cache.
    }
    return saved;
  }

  @override
  Future<void> cacheContact(SafetyContact value) => local.cacheContact(value);

  @override
  Future<void> deleteContact(String id) async {
    await cloud.deleteContact(id);
    try {
      await local.deleteCachedContact(id);
    } catch (_) {
      // Supabase is authoritative; a later refresh can rebuild local cache.
    }
  }

  @override
  Future<void> requestContactVerification(String id) =>
      cloud.requestVerification(id);
  @override
  Future<void> confirmContactVerification(String id, String code) =>
      cloud.confirmVerification(id, code);
  @override
  Future<Map<String, Object?>> dispatchEmergency(
    String eventId,
    String idempotencyKey,
  ) async {
    final event = await local.getEvent(eventId);
    if (event == null) {
      throw StateError('sleep_safety_event_missing');
    }
    final session = await local.getSession(event.sessionId);
    if (session == null) {
      throw StateError('sleep_safety_session_missing');
    }

    // The dispatch Edge Function reads these rows from Supabase. Local writes
    // are therefore not enough, even when the native alert is still visible.
    await _syncForDispatch('sleep_safety_sessions', _sessionCloudMap(session));
    await _syncForDispatch('sleep_safety_events', _eventCloudMap(event));
    return cloud.dispatchEvent(
      eventId: eventId,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> _syncForDispatch(
    String table,
    Map<String, Object?> values,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await cloud.syncRow(table, values);
        return;
      } catch (_) {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    // Do not leak provider/PostgREST internals into the presentation layer.
    throw StateError('sleep_safety_dispatch_sync_failed');
  }

  @override
  Future<bool> isRolloutEnabled() async =>
      (await cloud.fetchRuntimeConfig()).enabled;

  Map<String, Object?> _preferenceCloudMap(SleepSafetyPreference value) => {
    'user_id': value.userId,
    'enabled': value.enabled,
    'sensitivity': value.sensitivity.name,
    'schedule_enabled': value.scheduleEnabled,
    'schedule_start_minutes': value.scheduleStartMinutes,
    'schedule_end_minutes': value.scheduleEndMinutes,
    'timezone': value.timezone,
    'selected_weekdays': value.selectedWeekdays.toList()..sort(),
    'calibration_required': value.calibrationRequired,
    'calibration_noise_floor': value.calibrationNoiseFloor,
    'calibration_updated_at': value.calibrationUpdatedAt?.toIso8601String(),
    'cooldown_seconds': value.cooldownSeconds,
    'consent_version': value.consentVersion,
    'updated_at': value.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _sessionCloudMap(SleepSafetySession value) => {
    'id': value.id,
    'user_id': value.userId,
    'started_at': value.startedAt.toIso8601String(),
    'ended_at': value.endedAt?.toIso8601String(),
    'scheduled_window_start': value.scheduledWindowStart?.toIso8601String(),
    'scheduled_window_end': value.scheduledWindowEnd?.toIso8601String(),
    'sensitivity': value.sensitivity.name,
    'calibration_noise_floor': value.calibrationNoiseFloor,
    'status': value.status.name,
    'start_source': value.startSource,
    'stop_reason': value.stopReason,
    'platform': value.platform,
    'app_version': value.appVersion,
    'created_at': value.createdAt.toIso8601String(),
    'updated_at': value.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _eventCloudMap(SleepSafetyEvent value) => {
    'id': value.id,
    'session_id': value.sessionId,
    'user_id': value.userId,
    'detected_at': value.detectedAt.toIso8601String(),
    'event_type': value.eventType.name,
    'severity': value.severity,
    'confidence': value.confidence,
    'relative_energy': value.relativeEnergy,
    'baseline_delta': value.baselineDelta,
    'repetition_count': value.repetitionCount,
    'state': value.state,
    'response': value.response.name,
    'response_at': value.responseAt?.toIso8601String(),
    'escalation_required': value.escalationRequired,
    'escalation_status': value.escalationStatus.name,
    'created_at': value.createdAt.toIso8601String(),
    'updated_at': value.updatedAt.toIso8601String(),
  };
}
