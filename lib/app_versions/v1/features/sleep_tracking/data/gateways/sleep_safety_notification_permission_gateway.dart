import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_notification_scheduler.dart';

/// Notification permission boundary owned by M31.
///
/// This intentionally does not request exact-alarm access. Sleep-safety
/// monitoring only needs user-visible notifications while the microphone
/// foreground service is running; bedtime reminders use inexact scheduling.
abstract interface class SleepSafetyNotificationPermissionGateway {
  Future<bool> requestPermission();
}

class LocalSleepSafetyNotificationPermissionGateway
    implements SleepSafetyNotificationPermissionGateway {
  const LocalSleepSafetyNotificationPermissionGateway();

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    await NotificationBootstrap.initialize();
    final scheduler = NotificationBootstrap.scheduler;
    if (scheduler is! LocalReminderNotificationScheduler) return false;
    final plugin = scheduler.plugin;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidPlugin = plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final result = await androidPlugin?.requestNotificationsPermission();
        // Android <=12 has no runtime POST_NOTIFICATIONS dialog.
        return result ?? true;
      case TargetPlatform.iOS:
        final result = await plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      case TargetPlatform.macOS:
        final result = await plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
    }
  }
}
