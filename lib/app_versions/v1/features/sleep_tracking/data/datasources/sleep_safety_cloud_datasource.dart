import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/safety_contact.dart';
import '../models/sleep_safety_models.dart';

class SleepSafetyRuntimeConfig {
  const SleepSafetyRuntimeConfig({required this.enabled, required this.maxDispatchesPerHour});
  final bool enabled;
  final int maxDispatchesPerHour;
}

class SleepSafetyCloudDatasource {
  const SleepSafetyCloudDatasource({this.clientOverride});
  final SupabaseClient? clientOverride;
  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try { return Supabase.instance.client; } on AssertionError { return null; }
  }
  Future<SleepSafetyRuntimeConfig> fetchRuntimeConfig() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return const SleepSafetyRuntimeConfig(enabled:false,maxDispatchesPerHour:0);
    final row = await client.from('sleep_safety_runtime_config').select('enabled,max_dispatches_per_hour').eq('config_key','default').maybeSingle();
    return SleepSafetyRuntimeConfig(enabled: row?['enabled'] == true, maxDispatchesPerHour: (row?['max_dispatches_per_hour'] as num?)?.toInt() ?? 0);
  }
  Future<List<SafetyContact>> fetchContacts() async {
    final client = _client; final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];
    final rows = await client.from('sleep_safety_contacts').select().eq('user_id', userId).eq('active', true).order('priority');
    return (rows as List).map((row) => SleepSafetyModelMapper.contactFromMap(Map<String,Object?>.from(row as Map))).toList(growable:false);
  }
  Future<SafetyContact> upsertContact({required String? id, required String name, required String relationship, required String phoneE164, required int priority}) async {
    final client = _requireClient();
    final row = await client.rpc('upsert_sleep_safety_contact', params: {'p_contact_id': id, 'p_name': name, 'p_relationship': relationship, 'p_phone_e164': phoneE164, 'p_priority': priority});
    if (row is List && row.isNotEmpty) return SleepSafetyModelMapper.contactFromMap(Map<String,Object?>.from(row.first as Map));
    if (row is Map) return SleepSafetyModelMapper.contactFromMap(Map<String,Object?>.from(row));
    throw StateError('Không thể lưu người liên hệ an toàn.');
  }
  Future<void> deleteContact(String id) async => _requireClient().rpc('delete_sleep_safety_contact', params: {'p_contact_id': id});
  Future<void> requestVerification(String contactId) async {
    final response = await _requireClient().functions.invoke('sleep-safety-contact-verification', body: {'action':'request','contact_id':contactId});
    if (response.status < 200 || response.status >= 300) throw StateError('Chưa thể gửi mã xác minh.');
  }
  Future<void> confirmVerification(String contactId, String code) async {
    final response = await _requireClient().functions.invoke('sleep-safety-contact-verification', body: {'action':'confirm','contact_id':contactId,'code':code});
    if (response.status < 200 || response.status >= 300) throw StateError('Mã xác minh chưa đúng hoặc đã hết hạn.');
  }
  Future<void> syncRow(String table, Map<String,Object?> values) async => _requireClient().from(table).upsert(values);
  Future<Map<String,Object?>> dispatchEvent({required String eventId, required String idempotencyKey}) async {
    final response = await _requireClient().functions.invoke('sleep-safety-dispatch', body: {'event_id':eventId,'idempotency_key':idempotencyKey});
    if (response.status < 200 || response.status >= 300) throw StateError('Chưa thể liên hệ người hỗ trợ.');
    final data = response.data;
    return data is Map ? Map<String,Object?>.from(data) : const <String,Object?>{};
  }
  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null || client.auth.currentUser == null) throw StateError('Bạn cần đăng nhập lại để dùng tính năng này.');
    return client;
  }
}
