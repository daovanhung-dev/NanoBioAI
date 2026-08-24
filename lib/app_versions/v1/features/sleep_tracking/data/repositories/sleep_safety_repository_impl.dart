import '../../domain/entities/safety_contact.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../domain/entities/sleep_safety_preference.dart';
import '../../domain/entities/sleep_safety_session.dart';
import '../../domain/repositories/sleep_safety_repository.dart';
import '../datasources/sleep_safety_cloud_datasource.dart';
import '../datasources/sleep_safety_local_datasource.dart';
import '../gateways/sleep_safety_native_gateway.dart';

class SleepSafetyRepositoryImpl implements SleepSafetyRepository {
  const SleepSafetyRepositoryImpl({required this.local, required this.cloud, required this.native});
  final SleepSafetyLocalDatasource local;
  final SleepSafetyCloudDatasource cloud;
  final SleepSafetyNativeGateway native;
  @override Stream<SleepSafetyNativeEvent> get nativeEvents => native.events;
  @override Future<bool> ensureMicrophonePermission() => native.ensureMicrophonePermission();
  @override Future<void> startNative(Map<String,Object?> config) => native.startMonitoring(config);
  @override Future<void> stopNative(String reason) => native.stopMonitoring(reason);
  @override Future<void> respondToAlert(String eventId,String response) => native.respondToAlert(eventId:eventId,response:response);
  @override Future<void> updateNativeConfig(Map<String,Object?> config) => native.updateRuntimeConfig(config);
  @override Future<SleepSafetyPreference> loadPreference(String userId) => local.loadPreference(userId);
  @override Future<void> savePreference(SleepSafetyPreference value) async { await local.savePreference(value); try { await cloud.syncRow('sleep_safety_preferences', _preferenceCloudMap(value)); } catch (_) {} }
  @override Future<SleepSafetySession?> getSession(String id) => local.getSession(id);
  @override Future<void> saveSession(SleepSafetySession value) async { await local.saveSession(value); try { await cloud.syncRow('sleep_safety_sessions', _sessionCloudMap(value)); } catch (_) {} }
  @override Future<void> updateSession(String id,Map<String,Object?> values) => local.updateSession(id, values);
  @override Future<SleepSafetyEvent?> getEvent(String id) => local.getEvent(id);
  @override Future<void> saveEvent(SleepSafetyEvent value) async { await local.saveEvent(value); try { await cloud.syncRow('sleep_safety_events', _eventCloudMap(value)); } catch (_) {} }
  @override Future<void> updateEvent(String id,Map<String,Object?> values) => local.updateEvent(id, values);
  @override Future<List<SleepSafetyEvent>> listEvents(String userId) => local.listEvents(userId);
  @override Future<List<SafetyContact>> loadContacts(String userId,{bool refreshCloud=true}) async {
    if (refreshCloud) { try { final contacts=await cloud.fetchContacts(); await local.cacheContacts(userId, contacts); return contacts; } catch (_) {} }
    return local.listCachedContacts(userId);
  }
  @override Future<SafetyContact> saveContact({String? id,required String name,required String relationship,required String phoneE164,required int priority}) => cloud.upsertContact(id:id,name:name,relationship:relationship,phoneE164:phoneE164,priority:priority);
  @override Future<void> deleteContact(String id) => cloud.deleteContact(id);
  @override Future<void> requestContactVerification(String id) => cloud.requestVerification(id);
  @override Future<void> confirmContactVerification(String id,String code) => cloud.confirmVerification(id,code);
  @override Future<Map<String,Object?>> dispatchEmergency(String eventId,String idempotencyKey) => cloud.dispatchEvent(eventId:eventId,idempotencyKey:idempotencyKey);
  @override Future<bool> isRolloutEnabled() async => (await cloud.fetchRuntimeConfig()).enabled;

  Map<String,Object?> _preferenceCloudMap(SleepSafetyPreference v) => {
    'user_id':v.userId,'enabled':v.enabled,'sensitivity':v.sensitivity.name,'schedule_enabled':v.scheduleEnabled,
    'schedule_start_minutes':v.scheduleStartMinutes,'schedule_end_minutes':v.scheduleEndMinutes,'timezone':v.timezone,
    'selected_weekdays':v.selectedWeekdays.toList()..sort(),'calibration_required':v.calibrationRequired,
    'calibration_noise_floor':v.calibrationNoiseFloor,'calibration_updated_at':v.calibrationUpdatedAt?.toIso8601String(),
    'cooldown_seconds':v.cooldownSeconds,'consent_version':v.consentVersion,'updated_at':v.updatedAt.toIso8601String(),
  };
  Map<String,Object?> _sessionCloudMap(SleepSafetySession v) => {
    'id':v.id,'user_id':v.userId,'started_at':v.startedAt.toIso8601String(),'ended_at':v.endedAt?.toIso8601String(),
    'scheduled_window_start':v.scheduledWindowStart?.toIso8601String(),'scheduled_window_end':v.scheduledWindowEnd?.toIso8601String(),
    'sensitivity':v.sensitivity.name,'calibration_noise_floor':v.calibrationNoiseFloor,'status':v.status.name,
    'start_source':v.startSource,'stop_reason':v.stopReason,'platform':v.platform,'app_version':v.appVersion,
    'created_at':v.createdAt.toIso8601String(),'updated_at':v.updatedAt.toIso8601String(),
  };
  Map<String,Object?> _eventCloudMap(SleepSafetyEvent v) => {
    'id':v.id,'session_id':v.sessionId,'user_id':v.userId,'detected_at':v.detectedAt.toIso8601String(),
    'event_type':v.eventType.name,'severity':v.severity,'confidence':v.confidence,'relative_energy':v.relativeEnergy,
    'baseline_delta':v.baselineDelta,'repetition_count':v.repetitionCount,'state':v.state,'response':v.response.name,
    'response_at':v.responseAt?.toIso8601String(),'escalation_required':v.escalationRequired,'escalation_status':v.escalationStatus.name,
    'created_at':v.createdAt.toIso8601String(),'updated_at':v.updatedAt.toIso8601String(),
  };
}
