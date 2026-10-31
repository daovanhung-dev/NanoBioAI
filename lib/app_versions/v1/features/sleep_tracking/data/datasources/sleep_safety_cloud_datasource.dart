import 'dart:async';

import '../../../../../../core/network/backend_api_client.dart';
import '../../domain/entities/safety_contact.dart';
import '../../domain/entities/sleep_safety_runtime_config.dart';
import '../../domain/entities/sleep_safety_dispatch_exception.dart';
import '../../domain/entities/sleep_safety_dispatch_result.dart';
import '../models/sleep_safety_models.dart';

class SleepSafetyCloudException extends SleepSafetyDispatchException {
  const SleepSafetyCloudException(super.code);

  factory SleepSafetyCloudException.from(
    Object error, {
    required String fallbackCode,
  }) {
    if (error is BackendApiException) {
      final code = switch (error.businessCode) {
        'CONTACT_NOT_FOUND' => 'sleep_safety_contact_not_found',
        'PAID_ACCESS_REQUIRED' => 'paid_access_required',
        'SLEEP_SAFETY_DISABLED' => 'sleep_safety_rollout_disabled',
        'EVENT_NOT_ELIGIBLE' => 'event_not_eligible_for_escalation',
        'DISPATCH_RATE_LIMITED' => 'dispatch_rate_limited',
        'ALL_CONTACTS_FAILED' => 'all_contacts_failed',
        'PROVIDER_UNAVAILABLE' => 'provider_unavailable',
        'NETWORK_UNAVAILABLE' => 'network_unavailable',
        _ => error.businessCode.toLowerCase(),
      };
      return SleepSafetyCloudException(code);
    }
    final raw = error.toString().toLowerCase();
    const knownCodes = [
      'sleep_safety_contact_limit',
      'sleep_safety_priority_invalid',
      'sleep_safety_phone_invalid',
      'sleep_safety_contact_not_found',
      'verified_contact_required',
      'eligible_contact_required',
      'paid_access_required',
      'sleep_safety_rollout_disabled',
      'event_not_eligible_for_escalation',
      'all_contacts_failed',
      'provider_unavailable',
      'authentication_required',
      'dispatch_rate_limited',
      'verification_provider_failed',
      'network_unavailable',
      'dispatch_sync_failed',
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

  static bool isTransportError(Object error) {
    if (error is SleepSafetyDispatchException) {
      return error.isTransportFailure;
    }
    final raw = error.toString().toLowerCase();
    return error is TimeoutException ||
        raw.contains('socketexception') ||
        raw.contains('clientexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection reset') ||
        raw.contains('connection refused') ||
        raw.contains('timed out') ||
        raw.contains('network request failed');
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
      'Chưa có liên hệ đủ điều kiện nhận cuộc gọi cảnh báo.',
    'eligible_contact_required' =>
      'Hãy thêm liên hệ hoặc bật quyền nhận cuộc gọi cảnh báo cho số chưa xác minh.',
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
    'network_unavailable' =>
      'Chưa có kết nối mạng. Cảnh báo đã được xếp hàng để thử lại trong thời gian cho phép.',
    'dispatch_sync_failed' =>
      'Chưa thể đồng bộ cảnh báo. Bạn vẫn có thể gọi người liên hệ trực tiếp.',
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

class SleepSafetyCloudDatasource {
  const SleepSafetyCloudDatasource({this.clientOverride});
  final BackendApiClient? clientOverride;
  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  Future<SleepSafetyRuntimeConfig> fetchRuntimeConfig() async {
    if (_client.session == null) {
      return const SleepSafetyRuntimeConfig(
        enabled: false,
        maxDispatchesPerHour: 0,
      );
    }
    final row = await _client.requestMap(
      'GET',
      '/api/v1/sleep-safety/runtime-config',
    );
    return SleepSafetyRuntimeConfig(
      enabled: row['enabled'] == true,
      maxDispatchesPerHour:
          (row['max_dispatches_per_hour'] as num?)?.toInt() ?? 0,
      eventFreshnessSeconds:
          (row['event_freshness_seconds'] as num?)?.toInt() ?? 600,
    );
  }

  Future<List<SafetyContact>> fetchContacts() async {
    if (_client.currentUserId == null) return const [];
    final rows = await _client.request('GET', '/api/v1/sleep-safety/contacts');
    if (rows is! List) {
      throw const FormatException('Backend contacts response must be a list.');
    }
    return rows
        .map((row) {
          if (row is! Map) {
            throw const FormatException(
              'Backend contact row must be an object.',
            );
          }
          return SleepSafetyModelMapper.contactFromMap(
            Map<String, Object?>.from(row),
          );
        })
        .toList(growable: false);
  }

  Future<SafetyContact> upsertContact({
    required String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
    bool allowPhoneFallback = true,
    bool allowUnverifiedVoiceAlert = false,
  }) async {
    try {
      final client = _requireClient();
      final path = id == null
          ? '/api/v1/sleep-safety/contacts'
          : '/api/v1/sleep-safety/contacts/${Uri.encodeComponent(id)}';
      final row = await client.requestMap(
        id == null ? 'POST' : 'PUT',
        path,
        body: {
          'name': name,
          'relationship': relationship,
          'phone_e164': phoneE164,
          'priority': priority,
          'allow_phone_fallback': allowPhoneFallback,
          'allow_unverified_voice_alert': allowUnverifiedVoiceAlert,
        },
      );
      return SleepSafetyModelMapper.contactFromMap(row);
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
      await _requireClient().requestMap(
        'DELETE',
        '/api/v1/sleep-safety/contacts/${Uri.encodeComponent(id)}',
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
      await _requireClient().requestMap(
        'POST',
        '/api/v1/sleep-safety/contacts/verification',
        body: {'action': 'request', 'contact_id': contactId},
      );
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
      await _requireClient().requestMap(
        'POST',
        '/api/v1/sleep-safety/contacts/verification',
        body: {'action': 'confirm', 'contact_id': contactId, 'code': code},
      );
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: 'verification_confirm_failed',
      );
    }
  }

  Future<void> syncRow(String table, Map<String, Object?> values) async {
    try {
      final client = _requireClient();
      final recordId = values['id']?.toString();
      final path = switch (table) {
        'sleep_safety_preferences' => '/api/v1/sleep-safety/preferences',
        'sleep_safety_sessions' when recordId?.isNotEmpty == true =>
          '/api/v1/sleep-safety/sessions/${Uri.encodeComponent(recordId!)}',
        'sleep_safety_events' when recordId?.isNotEmpty == true =>
          '/api/v1/sleep-safety/events/${Uri.encodeComponent(recordId!)}',
        _ => throw ArgumentError.value(
          table,
          'table',
          'Unsupported sync record.',
        ),
      };
      await client.requestMap('PUT', path, body: values);
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: SleepSafetyCloudException.isTransportError(error)
            ? 'network_unavailable'
            : 'dispatch_sync_failed',
      );
    }
  }

  Future<SleepSafetyDispatchResult> dispatchEvent({
    required String eventId,
    required String idempotencyKey,
  }) async {
    try {
      final data = await _requireClient().requestMap(
        'POST',
        '/api/v1/sleep-safety/dispatch',
        body: {'event_id': eventId, 'idempotency_key': idempotencyKey},
      );
      final accepted = data['accepted'] == true;
      final route = accepted
          ? SleepSafetyDispatchRoute.cloudAccepted
          : SleepSafetyDispatchRoute.cloudFailed;
      return SleepSafetyDispatchResult(
        route: route,
        idempotencyKey: idempotencyKey,
        errorCode: accepted
            ? null
            : data['error']?.toString() ?? 'dispatch_failed',
      );
    } catch (error) {
      if (error is SleepSafetyCloudException) rethrow;
      throw SleepSafetyCloudException.from(
        error,
        fallbackCode: SleepSafetyCloudException.isTransportError(error)
            ? 'network_unavailable'
            : 'dispatch_failed',
      );
    }
  }

  BackendApiClient _requireClient() {
    final client = _client;
    if (client.session == null) {
      throw const SleepSafetyCloudException('authentication_required');
    }
    return client;
  }
}
