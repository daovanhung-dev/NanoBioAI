import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'active_notification_subject.dart';
import 'nabi_companion_notification_payload.dart';
import 'nabi_health_reminder_coordinator.dart';
import 'notification_action_handler.dart';
import 'notification_navigation_coordinator.dart';
import 'reminder_notification_scheduler.dart';
import 'reminder_schedule_service.dart';

@pragma('vm:entry-point')
void bioAiNotificationBackgroundResponse(NotificationResponse response) {
  DartPluginRegistrant.ensureInitialized();
  unawaited(NotificationBootstrap.handleNotificationResponse(response));
}

class NotificationBootstrap {
  NotificationBootstrap._();

  static const _tag = 'NOTIFICATION_BOOTSTRAP';
  static const _fallbackTimezone = 'Asia/Ho_Chi_Minh';

  static final LocalReminderNotificationScheduler _scheduler =
      LocalReminderNotificationScheduler(
        onForegroundResponse: handleNotificationResponse,
        onBackgroundResponse: bioAiNotificationBackgroundResponse,
      );

  static bool _timezoneInitialized = false;
  static bool _initialized = false;
  static Future<void>? _initializing;
  static bool _launchResponseHandled = false;

  static ReminderNotificationScheduler get scheduler => _scheduler;

  static NabiHealthReminderCoordinator _careCoordinator() =>
      NabiHealthReminderCoordinator(scheduler: _scheduler);

  static Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initializeOnce();
  }

  static Future<void> _initializeOnce() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeTimezone();
      await _scheduler.initialize();
      _initialized = true;
      await _handleLaunchResponseOnce();
      AppLogger.info(_tag, 'Notification bootstrap initialized');
    } finally {
      _initializing = null;
    }
  }

  static Future<void> _handleLaunchResponseOnce() async {
    if (_launchResponseHandled) return;
    _launchResponseHandled = true;
    try {
      final details = await _scheduler.plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response != null) {
        await handleNotificationResponse(response);
      }
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Cannot restore notification navigation; errorType=${error.runtimeType}',
      );
    }
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    return _scheduler.requestPermissions();
  }

  static Future<void> scheduleGeneratedReminders({
    String? subjectUserId,
  }) async {
    await initialize();
    final subject = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    final service = await ReminderScheduleService.create(
      scheduler: _scheduler,
      activeSubjectUserId: () async => subject,
    );
    final coordinator = _careCoordinator();
    final preferences = await coordinator.loadPreferences(
      subjectUserId: subject,
    );

    if (preferences?.masterEnabled == true &&
        preferences?.scheduleEnabled == true) {
      await service.scheduleGeneratedReminders();
    } else {
      await service.clearPendingReminders(subjectUserId: subject);
    }
    await coordinator.refresh(subjectUserId: subject);
  }

  static Future<void> refreshHealthCareReminders({
    String? subjectUserId,
  }) async {
    await initialize();
    await _careCoordinator().refresh(subjectUserId: subjectUserId);
  }

  static Future<void> clearGeneratedReminders({String? subjectUserId}) async {
    await initialize();
    final subject = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    final service = await ReminderScheduleService.create(scheduler: _scheduler);
    await service.clearPendingReminders(subjectUserId: subject);
    await _careCoordinator().clear(subjectUserId: subject);
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      await initialize();
      final companion = NabiCompanionNotificationPayload.tryParse(
        response.payload,
      );
      if (companion != null) {
        await _careCoordinator().handleResponse(response, companion);
        return;
      }
      if (_isSleepSafetyArmPayload(response.payload)) {
        NotificationNavigationCoordinator.openSleepSafety();
        return;
      }
      final handler = await NotificationActionHandler.create(
        scheduler: _scheduler,
      );
      await handler.handleResponse(response);
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to handle notification response',
        error,
        stackTrace,
      );
    }
  }

  static bool _isSleepSafetyArmPayload(String? payload) {
    final raw = payload?.trim();
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      return decoded['type'] == 'sleep_safety' && decoded['action'] == 'arm';
    } catch (_) {
      return false;
    }
  }

  static Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();
    final timezoneName = await _resolveTimezoneName();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Unknown timezone "$timezoneName". Fallback to $_fallbackTimezone. errorType=${error.runtimeType}',
      );
      tz.setLocalLocation(tz.getLocation(_fallbackTimezone));
    }
    _timezoneInitialized = true;
  }

  static Future<String> _resolveTimezoneName() async {
    if (kIsWeb) return _fallbackTimezone;
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final identifier = timezoneInfo.identifier.trim();
      if (identifier.isEmpty) {
        AppLogger.warning(
          _tag,
          'Device timezone identifier is empty. Fallback to $_fallbackTimezone.',
        );
        return _fallbackTimezone;
      }
      return identifier;
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Cannot resolve device timezone. Fallback to $_fallbackTimezone. errorType=${error.runtimeType}',
      );
      return _fallbackTimezone;
    }
  }
}
