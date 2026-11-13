import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'package:nano_app/core/network/backend_api_client.dart';

import 'web_push_notification_scheduler.dart';

const _subscriptionIdKey = 'web_push_subscription_id_v1';
const _capabilityKey = 'web_push_capability_v1';
const _remindersKey = 'web_push_reminders_v1';
const _workerPath = '/push/push_service_worker.js';
const _workerScope = '/push/';

class BrowserWebPushNotificationScheduler
    implements WebPushNotificationScheduler {
  BrowserWebPushNotificationScheduler({BackendApiClient? api})
    : _api = api ?? BackendApiClient.shared;

  final BackendApiClient _api;
  final Map<int, _WebPushReminder> _reminders = {};
  String? _subscriptionId;
  String? _capability;
  String? _vapidPublicKey;
  String? _availabilityMessage;
  bool _initialized = false;
  Future<void>? _initializing;

  @override
  String? get availabilityMessage => _availabilityMessage;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    return _initializing ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _subscriptionId = prefs.getString(_subscriptionIdKey);
      _capability = prefs.getString(_capabilityKey);
      final rawReminders = prefs.getString(_remindersKey);
      if (rawReminders != null) {
        final decoded = jsonDecode(rawReminders);
        if (decoded is List) {
          for (final value in decoded) {
            if (value is Map) {
              final reminder = _WebPushReminder.tryParse(
                Map<String, Object?>.from(value),
              );
              if (reminder != null) _reminders[reminder.id] = reminder;
            }
          }
        }
      }
      final config = await _api.requestMap(
        'GET',
        '/api/v1/web-push/config',
        authenticated: false,
      );
      if (config['enabled'] == true) {
        _vapidPublicKey = config['public_key']?.toString();
      }
      if (_vapidPublicKey == null || _vapidPublicKey!.isEmpty) {
        _availabilityMessage = 'Thông báo web chưa được cấu hình trên máy chủ.';
      }
      _initialized = true;
    } catch (_) {
      _availabilityMessage = 'Chưa kết nối được dịch vụ thông báo web.';
      _initialized = false;
    } finally {
      _initializing = null;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    // Call requestPermission before the first await so browsers can associate
    // the permission prompt with the user's tap on the settings switch.
    if (!web.window.isSecureContext) {
      _availabilityMessage =
          'Thông báo web cần kết nối an toàn. Hãy mở NanoBio qua HTTPS rồi thử lại.';
      return false;
    }

    try {
      final permission = web.Notification.permission;
      final result = permission == 'granted'
          ? 'granted'
          : (await web.Notification.requestPermission().toDart).toDart;
      if (result != 'granted') {
        _availabilityMessage = 'Bạn chưa cho phép thông báo trên trình duyệt.';
        return false;
      }
      await initialize();
      if (_vapidPublicKey == null || _vapidPublicKey!.isEmpty) {
        _availabilityMessage = 'Thông báo web chưa được cấu hình trên máy chủ.';
        return false;
      }
      await _ensureSubscription();
      await synchronize();
      _availabilityMessage = null;
      return true;
    } catch (_) {
      _availabilityMessage =
          'Không thể bật thông báo web trên trình duyệt này. Hãy kiểm tra quyền thông báo và kết nối rồi thử lại.';
      return false;
    }
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    final category = _categoryFromPayload(payload);
    await _putReminder(
      _WebPushReminder(
        id: id,
        category: category,
        scheduledAt: scheduledAt.toUtc(),
      ),
    );
  }

  @override
  Future<void> scheduleNabiCompanionReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
    required bool voiceEnabled,
  }) async {
    await _putReminder(
      _WebPushReminder(
        id: id,
        category: _categoryFromPayload(payload),
        scheduledAt: scheduledAt.toUtc(),
      ),
    );
  }

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    await _putReminder(
      _WebPushReminder(
        id: id,
        category: 'medication',
        dailyMinute: scheduledAt.hour * 60 + scheduledAt.minute,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (_reminders.remove(id) != null) await _persistReminders();
  }

  @override
  Future<void> cancelMedicationReminders({String? ownerId}) async {
    _reminders.removeWhere((_, reminder) => reminder.category == 'medication');
    await _persistReminders();
  }

  @override
  Future<void> synchronize() async {
    await initialize();
    if (_subscriptionId == null || _capability == null) return;
    if (web.Notification.permission != 'granted') return;
    final timezone = await _localTimezone();
    await _api.requestMap(
      'PUT',
      '/api/v1/web-push/subscriptions/$_subscriptionId/reminders',
      authenticated: false,
      headers: {'X-Guest-Capability': _capability!},
      body: {
        'timezone': timezone,
        'reminders': _reminders.values
            .map((reminder) => reminder.toJson())
            .toList(growable: false),
      },
    );
  }

  @override
  Future<void> unsubscribe() async {
    await initialize();
    final id = _subscriptionId;
    final capability = _capability;
    if (id != null && capability != null) {
      try {
        await _api.requestMap(
          'DELETE',
          '/api/v1/web-push/subscriptions/$id',
          authenticated: false,
          headers: {'X-Guest-Capability': capability},
        );
      } finally {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_subscriptionIdKey);
        await prefs.remove(_capabilityKey);
        _subscriptionId = null;
        _capability = null;
      }
    }
    final registration = await _registerServiceWorker();
    final subscription = await registration.pushManager
        .getSubscription()
        .toDart;
    if (subscription != null) await subscription.unsubscribe().toDart;
  }

  Future<void> _ensureSubscription() async {
    final publicKey = _vapidPublicKey;
    if (publicKey == null || publicKey.isEmpty) {
      throw StateError('Web Push is not configured.');
    }
    final registration = await _registerServiceWorker();
    final applicationKey = _decodeBase64Url(publicKey).toJS;
    var subscription = await registration.pushManager.getSubscription().toDart;
    subscription ??= await registration.pushManager
        .subscribe(
          web.PushSubscriptionOptionsInit(
            userVisibleOnly: true,
            applicationServerKey: applicationKey,
          ),
        )
        .toDart;
    final serialized = subscription.toJSON();
    final keys = serialized.keys.dartify();
    if (keys is! Map) throw const FormatException('Invalid browser push keys.');
    final keyMap = keys.map((key, value) => MapEntry(key.toString(), value));
    final timezone = await _localTimezone();
    final response = await _api.requestMap(
      'POST',
      '/api/v1/web-push/subscriptions',
      authenticated: false,
      body: {
        'endpoint': serialized.endpoint,
        'keys': {
          'p256dh': keyMap['p256dh']?.toString(),
          'auth': keyMap['auth']?.toString(),
        },
        'timezone': timezone,
      },
    );
    final id = response['subscription_id']?.toString();
    final capability = response['capability']?.toString();
    if (id == null || capability == null || id.isEmpty || capability.isEmpty) {
      throw const FormatException('Invalid browser push response.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionIdKey, id);
    await prefs.setString(_capabilityKey, capability);
    _subscriptionId = id;
    _capability = capability;
  }

  Future<web.ServiceWorkerRegistration> _registerServiceWorker() async {
    if (!web.window.isSecureContext) {
      throw StateError('Web Push requires a secure connection.');
    }
    final registration = await web.window.navigator.serviceWorker
        .register(
          _workerPath.toJS,
          web.RegistrationOptions(scope: _workerScope),
        )
        .toDart;
    for (
      var attempt = 0;
      attempt < 50 && registration.active == null;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (registration.active == null) {
      throw StateError('Web Push worker did not activate.');
    }
    return registration;
  }

  Future<void> _putReminder(_WebPushReminder reminder) async {
    _reminders[reminder.id] = reminder;
    await _persistReminders();
  }

  Future<void> _persistReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _remindersKey,
      jsonEncode(_reminders.values.map((value) => value.toJson()).toList()),
    );
  }

  String _categoryFromPayload(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map) {
        final category = (decoded['category'] ?? decoded['type'])?.toString();
        return switch (category) {
          'health_check_in' || 'health_checkin' => 'health_checkin',
          'goal_review' => 'goal_review',
          'profile_review' => 'profile_review',
          'water' => 'water',
          'sleep_safety' => 'sleep_safety',
          _ => 'schedule',
        };
      }
    } catch (_) {
      // Native payloads are not copied to the server.
    }
    return 'schedule';
  }

  Future<String> _localTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      if (timezone.identifier.trim().isNotEmpty) return timezone.identifier;
    } catch (_) {
      // Keep the configured Vietnam default if browser timezone lookup fails.
    }
    return 'Asia/Ho_Chi_Minh';
  }

  static Uint8List _decodeBase64Url(String value) =>
      Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));
}

class _WebPushReminder {
  const _WebPushReminder({
    required this.id,
    required this.category,
    this.scheduledAt,
    this.dailyMinute,
  });

  final int id;
  final String category;
  final DateTime? scheduledAt;
  final int? dailyMinute;

  Map<String, Object?> toJson() => {
    'reminder_id': id.toString(),
    'category': category,
    if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
    if (dailyMinute != null) 'daily_minute': dailyMinute,
  };

  static _WebPushReminder? tryParse(Map<String, Object?> value) {
    final id = int.tryParse(value['reminder_id']?.toString() ?? '');
    final category = value['category']?.toString();
    final scheduledAt = DateTime.tryParse(
      value['scheduled_at']?.toString() ?? '',
    );
    final dailyMinute = int.tryParse(value['daily_minute']?.toString() ?? '');
    if (id == null || category == null) return null;
    if ((scheduledAt == null) == (dailyMinute == null)) return null;
    return _WebPushReminder(
      id: id,
      category: category,
      scheduledAt: scheduledAt,
      dailyMinute: dailyMinute,
    );
  }
}

WebPushNotificationScheduler createWebPushNotificationScheduler() =>
    BrowserWebPushNotificationScheduler();
