import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares Android local notification scheduling requirements', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
      ),
    );
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver',
      ),
    );
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    expect(manifest, contains('android.intent.action.QUICKBOOT_POWERON'));
    expect(manifest, contains('com.htc.intent.action.QUICKBOOT_POWERON'));
  });

  test('uses exact alarms when available and falls back safely', () {
    final schedulerSource = File(
      'lib/services/notifications/reminder_notification_scheduler.dart',
    ).readAsStringSync();

    expect(schedulerSource, contains('requestExactAlarmsPermission'));
    expect(schedulerSource, contains('canScheduleExactNotifications'));
    expect(
      schedulerSource,
      contains('AndroidScheduleMode.exactAllowWhileIdle'),
    );
    expect(
      schedulerSource,
      contains('AndroidScheduleMode.inexactAllowWhileIdle'),
    );
  });
}
