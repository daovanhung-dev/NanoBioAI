import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers plugins and notification-center delegate for iOS actions', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(appDelegate, contains('import flutter_local_notifications'));
    expect(appDelegate, contains('import UserNotifications'));
    expect(
      appDelegate,
      contains('FlutterLocalNotificationsPlugin.setPluginRegistrantCallback'),
    );
    expect(
      appDelegate,
      contains('GeneratedPluginRegistrant.register(with: registry)'),
    );
    expect(
      appDelegate,
      contains(
        'UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate',
      ),
    );
  });

  test('shows only open-task and skip reminder actions', () {
    final scheduler = File(
      'lib/app_versions/v1/services/notifications/reminder_notification_scheduler.dart',
    ).readAsStringSync();

    expect(scheduler, contains("'Mở nhiệm vụ'"));
    expect(scheduler, contains("'Để sau'"));
    expect(scheduler, contains('NotificationActionIds.openSchedule'));
    expect(scheduler, contains('NotificationActionIds.skipped'));
  });
}
