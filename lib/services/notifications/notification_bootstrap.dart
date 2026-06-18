import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_handler.dart';
import 'reminder_notification_scheduler.dart';
import 'reminder_schedule_service.dart';

@pragma('vm:entry-point')
void bioAiNotificationBackgroundResponse(NotificationResponse response) {
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

  static ReminderNotificationScheduler get scheduler => _scheduler;

  static Future<void> initialize() async {
    if (_initialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    await _initializeTimezone();
    await _scheduler.initialize();

    _initialized = true;

    AppLogger.info(_tag, 'Notification bootstrap initialized');
  }

  static Future<void> scheduleGeneratedReminders() async {
    await initialize();

    final service = await ReminderScheduleService.create(scheduler: _scheduler);

    await service.scheduleGeneratedReminders();
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      await initialize();

      final handler = await NotificationActionHandler.create();
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

  static Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;

    tz_data.initializeTimeZones();

    final timezoneName = await _resolveTimezoneName();

    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error, stackTrace) {
      AppLogger.warning(
        _tag,
        'Unknown timezone "$timezoneName". Fallback to $_fallbackTimezone. Error: $error',
      );
      debugPrint(stackTrace.toString());

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
    } catch (error, stackTrace) {
      AppLogger.warning(
        _tag,
        'Cannot resolve device timezone. Fallback to $_fallbackTimezone. Error: $error',
      );
      debugPrint(stackTrace.toString());

      return _fallbackTimezone;
    }
  }
}
