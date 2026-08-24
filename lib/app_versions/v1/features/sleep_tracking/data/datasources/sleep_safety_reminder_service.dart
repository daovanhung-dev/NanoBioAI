import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_notification_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/sleep_safety_preference.dart';

/// Schedules an *arming reminder* only. It never starts the microphone in the
/// background. The user must open NanoBio and explicitly start monitoring.
class SleepSafetyReminderService {
  const SleepSafetyReminderService();

  static const _baseId = 319100;

  Future<void> apply(SleepSafetyPreference preference) async {
    await NotificationBootstrap.initialize();
    final scheduler = NotificationBootstrap.scheduler;
    for (var index = 0; index < 8; index++) {
      await scheduler.cancel(_baseId + index);
    }
    if (!preference.scheduleEnabled) return;

    final allowed = await scheduler.requestPermissions();
    if (!allowed) return;

    // Reuse the already-initialized M09 plugin so responses keep flowing through
    // the single NotificationBootstrap callback, but use a dedicated M31 copy
    // without the schedule-task action buttons.
    if (scheduler is! LocalReminderNotificationScheduler) return;
    final plugin = scheduler.plugin;

    final now = DateTime.now();
    var created = 0;
    for (var offset = 0; offset < 14 && created < 7; offset++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      if (!preference.selectedWeekdays.contains(day.weekday)) continue;

      final hour = preference.scheduleStartMinutes ~/ 60;
      final minute = preference.scheduleStartMinutes % 60;
      final scheduled = DateTime(day.year, day.month, day.day, hour, minute);
      if (!scheduled.isAfter(now)) continue;

      final payload = jsonEncode(<String, Object?>{
        'type': 'sleep_safety',
        'version': 1,
        'action': 'arm',
        'scheduled_at': scheduled.toIso8601String(),
      });
      await plugin.zonedSchedule(
        _baseId + created,
        'Đã đến giờ bật giám sát giấc ngủ',
        'Mở NanoBio và xác nhận Bắt đầu giám sát trước khi bạn ngủ nhé.',
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bioai_sleep_safety_arm_channel',
            'Nhắc bật giám sát giấc ngủ',
            channelDescription:
                'Nhắc bạn chủ động mở NanoBio và bắt đầu giám sát trước khi ngủ.',
            importance: Importance.high,
            priority: Priority.high,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      created++;
    }
  }
}
