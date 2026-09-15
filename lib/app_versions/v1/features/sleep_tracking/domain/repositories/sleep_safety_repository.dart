import '../../data/gateways/sleep_safety_native_gateway.dart';
import '../entities/safety_contact.dart';
import '../entities/sleep_night_analysis.dart';
import '../entities/sleep_safety_event.dart';
import '../entities/sleep_safety_preference.dart';
import '../entities/sleep_safety_session.dart';

abstract class SleepSafetyRepository {
  Stream<SleepSafetyNativeEvent> get nativeEvents;
  Future<bool> ensureMicrophonePermission();
  Future<void> startNative(Map<String, Object?> config);
  Future<void> stopNative(String reason);
  Future<void> respondToAlert(String eventId, String response);
  Future<void> dismissAlert(String eventId);
  Future<void> updateNativeConfig(Map<String, Object?> config);
  Future<SleepSafetyPreference> loadPreference(String userId);
  Future<void> savePreference(SleepSafetyPreference value);
  Future<void> saveSession(SleepSafetySession value);
  Future<SleepSafetySession?> getSession(String id);
  Future<List<SleepSafetySession>> listSessions(
    String userId, {
    int limit = 14,
  });
  Future<void> updateSession(String id, Map<String, Object?> values);
  Future<void> saveEvent(SleepSafetyEvent value);
  Future<SleepSafetyEvent?> getEvent(String id);
  Future<void> updateEvent(String id, Map<String, Object?> values);
  Future<List<SleepSafetyEvent>> listEvents(String userId);
  Future<List<SleepSafetyEvent>> listEventsForSession(String sessionId);
  Future<SleepNightAnalysis?> getNightAnalysis(String sessionId);
  Future<void> saveNightAnalysis(SleepNightAnalysis analysis);
  Future<List<SafetyContact>> loadContacts(
    String userId, {
    bool refreshCloud = true,
  });
  Future<SafetyContact> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
  });
  Future<void> cacheContact(SafetyContact value);
  Future<void> deleteContact(String id);
  Future<void> requestContactVerification(String id);
  Future<void> confirmContactVerification(String id, String code);
  Future<Map<String, Object?>> dispatchEmergency(
    String eventId,
    String idempotencyKey,
  );
  Future<bool> isRolloutEnabled();
}
