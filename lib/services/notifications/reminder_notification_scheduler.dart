import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_constants.dart';

abstract class ReminderNotificationScheduler {
  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  });

  Future<void> cancel(int id);
}

class LocalReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  LocalReminderNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    void Function(NotificationResponse response)? onForegroundResponse,
    void Function(NotificationResponse response)? onBackgroundResponse,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onForegroundResponse = onForegroundResponse,
       _onBackgroundResponse = onBackgroundResponse;

  static const _tag = 'LOCAL_REMINDER_SCHEDULER';

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(NotificationResponse response)? _onForegroundResponse;
  final void Function(NotificationResponse response)? _onBackgroundResponse;

  bool _initialized = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          NotificationActionIds.categoryId,
          actions: [
            DarwinNotificationAction.plain(
              NotificationActionIds.done,
              'Đã làm',
            ),
            DarwinNotificationAction.plain(
              NotificationActionIds.skipped,
              'Chưa làm',
            ),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    _initialized = true;
    AppLogger.info(_tag, 'Local notification plugin initialized');
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();

    if (kIsWeb) return true;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        final result = await androidPlugin?.requestNotificationsPermission();
        if (!(result ?? true)) return false;

        await _requestExactAlarmAccess(androidPlugin);

        return result ?? true;

      case TargetPlatform.iOS:
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? true;

      case TargetPlatform.macOS:
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? true;

      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
    }
  }

  Future<void> _requestExactAlarmAccess(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) {
      AppLogger.warning(
        _tag,
        'Cannot resolve Android notification plugin. Exact reminders may fall back to inexact delivery.',
      );
      return;
    }

    try {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();

      if (canScheduleExact ?? false) return;

      final granted = await androidPlugin.requestExactAlarmsPermission();
      if (granted ?? false) {
        AppLogger.info(_tag, 'Android exact alarm access granted');
        return;
      }

      AppLogger.warning(
        _tag,
        'Android exact alarm access was not granted. Reminders will use inexact delivery.',
      );
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Cannot request exact alarm access. Reminders will use inexact delivery. Error: $error',
      );
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
    await initialize();

    final now = DateTime.now();

    if (!scheduledAt.isAfter(now)) {
      AppLogger.warning(
        _tag,
        'Skip past reminder id=$id scheduledAt=${scheduledAt.toIso8601String()}',
      );
      return;
    }

    final androidScheduleMode = await _resolveAndroidScheduleMode();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.reminderId,
          NotificationChannels.reminderName,
          channelDescription: NotificationChannels.reminderDescription,
          importance: Importance.high,
          priority: Priority.high,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          actions: [
            AndroidNotificationAction(
              NotificationActionIds.done,
              'Đã làm',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              NotificationActionIds.skipped,
              'Chưa làm',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: NotificationActionIds.categoryId,
        ),
        macOS: DarwinNotificationDetails(
          categoryIdentifier: NotificationActionIds.categoryId,
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      payload: payload,
    );

    AppLogger.info(
      _tag,
      'Scheduled reminder id=$id at=${scheduledAt.toIso8601String()}',
    );
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) {
      AppLogger.warning(
        _tag,
        'Cannot resolve Android notification plugin. Falling back to inexact reminders.',
      );
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    try {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();

      if (canScheduleExact ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }

      AppLogger.warning(
        _tag,
        'Exact alarm access is not available. Falling back to inexact reminders.',
      );
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Cannot check exact alarm access. Falling back to inexact reminders. Error: $error',
      );
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }
}
