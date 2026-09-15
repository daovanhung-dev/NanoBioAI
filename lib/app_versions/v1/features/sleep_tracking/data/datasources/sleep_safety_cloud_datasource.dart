import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/safety_contact.dart';
import '../models/sleep_safety_models.dart';

class SleepSafetyCloudException implements Exception {
  const SleepSafetyCloudException(this.code);

  final String code;

  factory SleepSafetyCloudException.from(
    Object error, {
    required String fallbackCode,
  }) {
    final raw = error.toString().toLowerCase();
    const knownCodes = [
      'sleep_safety_contact_limit',
      'sleep_safety_priority_invalid',
      'sleep_safety_phone_invalid',
      'sleep_safety_contact_not_found',
      'verified_contact_required',
      'paid_access_required',
      'sleep_safety_rollout_disabled',
      'event_not_eligible_for_escalation',
      'all_contacts_failed',
      'provider_unavailable',
      'authentication_required',
      'dispatch_rate_limited',
      'verification_provider_failed',
    ];
    for (final code in knownCodes) {
      if (raw.contains(code)) return SleepSafetyCloudException(code);
    }
    if (raw.contains('23505') ||
        raw.contains('duplicate') ||
        raw.contains('unique')) {
      return const SleepSafetyCloudException('contact_duplicate');
    }
    return SleepSafetyCloudException(fallbackCode);
  }

  String get userMessage => switch (code) {
    'sleep_safety_contact_limit' => 'Bạn đã có tối đa 3 người liên hệ an toàn.',
    'sleep_safety_priority_invalid' =>
      'Mức ưu tiên cần nằm trong khoảng từ 1 đến 3.',
    'sleep_safety_phone_invalid' =>
      'Số điện thoại chưa đúng định dạng. Hãy nhập số Việt Nam hoặc số quốc tế hợp lệ.',
    'sleep_safety_contact_not_found' =>
      'Người liên hệ không còn tồn tại. Bạn tải lại danh sách rồi thử lại nhé.',
    'contact_duplicate' =>
      'Số điện thoại hoặc mức ưu tiên này đã được dùng cho người liên hệ khác.',
    'verified_contact_required' =>
      'Hãy xác minh ít nhất một người liên hệ trước khi gửi yêu cầu hỗ trợ.',
    'paid_access_required' =>
      'Tính năng liên hệ khẩn cấp dành cho gói Plus hoặc FamilyPlus.',
    'sleep_safety_rollout_disabled' =>
      'Tính năng liên hệ hỗ trợ đang tạm dừng từ hệ thống.',
    'event_not_eligible_for_escalation' =>
      'Sự kiện này chưa đủ điều kiện để gửi yêu cầu hỗ trợ.',
    'all_contacts_failed' || 'provider_unavailable' =>
      'Nhà cung cấp liên hệ chưa phản hồi. Bạn có thể thử gửi lại.',
    'authentication_required' =>
      'Phiên đăng nhập đã hết hạn. Bạn đăng nhập lại rồi thử lại nhé.',
    'dispatch_rate_limited' =>
      'Bạn đã dùng hết lượt liên hệ trong thời gian ngắn. Hãy thử lại sau.',
    'verification_provider_failed' =>
      'Nhà cung cấp SMS chưa phản hồi. Bạn thử gửi lại mã sau nhé.',
    'contact_save_failed' => 'Chưa thể lưu người liên hệ. Bạn thử lại nhé.',
    'verification_request_failed' =>
      'Chưa thể gửi mã xác minh. Bạn kiểm tra số điện thoại rồi thử lại nhé.',
    'verification_confirm_failed' => 'Mã xác minh chưa đúng hoặc đã hết hạn.',
    'dispatch_failed' =>
      'Chưa thể liên hệ người hỗ trợ. Bạn có thể thử gửi lại.',
    _ => 'Dịch vụ liên hệ chưa sẵn sàng. Bạn thử lại nhé.',
  };

  @override
  String toString() => userMessage;
}

class SleepSafetyRuntimeConfig {
  const SleepSafetyRuntimeConfig({
    required this.enabled,
    required this.maxDispatchesPerHour,
  });
  final bool enabled;
  final int maxDispatchesPerHour;
}

class SleepSafetyCloudDatasource {
  const SleepSafetyCloudDatasource({this.clientOverride});
  final SupabaseClient? clientOverride;
  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  Future<SleepSafetyRuntimeConfig> fetchRuntimeConfig() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return const SleepSafetyRuntimeConfig(
        enabled: false,
        maxDispatchesPerHour: 0,
      );
    }
    final row = await client
        .from('sleep_safety_runtime_config')
        .select('enabled,max_dispatches_per_hour')
        .eq('config_key', 'default')
        .maybeSingle();
    return SleepSafetyRuntimeConfig(
      enabled: row?['enabled'] == true,
      maxDispatchesPerHour:
          (row?['max_dispatches_per_hour'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<SafetyContact>> fetchContacts() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];
    final rows = await client
        .from('sleep_safety_contacts')
        .select()
        .eq('user_id', userId)
        .eq('active', true)
        .order('priority');
    return (rows as List)
        .map(
          (row) => SleepSafetyModelMapper.contactFromMap(
            Map<String, Object?>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<SafetyContact> upsertContact({
    required String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
  }) async {
    final client = _requireClient();
    try {
      final row = await client.rpc(
        'upsert_sleep_safety_contact',
        params: {
          'p_contact_id': id,
          'p_name': name,
          'p_relationship': relationship,
          'p_phone_e164': phoneE164,
          'p_priority': priority,
        },
      );
      if (row is List && row.isNotEmpty) {
        return SleepSafetyModelMapper.contactFromMap(
          Map<String, Object?>.from(row.first as Map),
        );
      }
      if (row is Map) {
        return SleepSafetyModelMapper.contactFromMap(
          Map<String, Object?>.from(row),
        );
      }
      throw const SleepSafetyCloudException('contact_save_failed');
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: 'contact_save_failed',
      );
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await _requireClient().rpc(
        'delete_sleep_safety_contact',
        params: {'p_contact_id': id},
      );
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: 'contact_save_failed',
      );
    }
  }

  Future<void> requestVerification(String contactId) async {
    try {
      final response = await _requireClient().functions.invoke(
        'sleep-safety-contact-verification',
        body: {'action': 'request', 'contact_id': contactId},
      );
      if (response.status < 200 || response.status >= 300) {
        throw SleepSafetyCloudException.from(
          response.data,
          fallbackCode: 'verification_request_failed',
        );
      }
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: 'verification_request_failed',
      );
    }
  }

  Future<void> confirmVerification(String contactId, String code) async {
    try {
      final response = await _requireClient().functions.invoke(
        'sleep-safety-contact-verification',
        body: {'action': 'confirm', 'contact_id': contactId, 'code': code},
      );
      if (response.status < 200 || response.status >= 300) {
        throw SleepSafetyCloudException.from(
          response.data,
          fallbackCode: 'verification_confirm_failed',
        );
      }
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: 'verification_confirm_failed',
      );
    }
  }

  Future<void> syncRow(String table, Map<String, Object?> values) async =>
      _requireClient().from(table).upsert(values);
  Future<Map<String, Object?>> dispatchEvent({
    required String eventId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _requireClient().functions.invoke(
        'sleep-safety-dispatch',
        body: {'event_id': eventId, 'idempotency_key': idempotencyKey},
      );
      if (response.status < 200 || response.status >= 300) {
        throw SleepSafetyCloudException.from(
          response.data,
          fallbackCode: 'dispatch_failed',
        );
      }
      final data = response.data;
      return data is Map
          ? Map<String, Object?>.from(data)
          : const <String, Object?>{};
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: 'dispatch_failed',
      );
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const SleepSafetyCloudException('authentication_required');
    }
    return client;
  }
}
