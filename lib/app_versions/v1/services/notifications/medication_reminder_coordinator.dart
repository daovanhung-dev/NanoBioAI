import 'dart:convert';

import 'package:nano_app/app_versions/v1/features/medication_reminders/data/repositories/sqlite_medication_reminder_repository.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/domain/repositories/medication_reminder_repository.dart';
import 'package:nano_app/app_versions/v1/services/notifications/active_notification_subject.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_id_generator.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_notification_scheduler.dart';

typedef MedicationReminderMasterEnabledReader =
    Future<bool> Function(String ownerId);
typedef MedicationReminderActiveSubjectReader = Future<String?> Function();

class MedicationReminderCoordinator {
  final MedicationReminderRepository repository;
  final MedicationDailyNotificationScheduler scheduler;
  final MedicationReminderMasterEnabledReader masterEnabled;
  final MedicationReminderActiveSubjectReader activeSubjectUserId;
  final DateTime Function() now;

  MedicationReminderCoordinator({
    required this.repository,
    required this.scheduler,
    required this.masterEnabled,
    MedicationReminderActiveSubjectReader? activeSubjectUserId,
    DateTime Function()? now,
  }) : activeSubjectUserId =
           activeSubjectUserId ?? resolveActiveNotificationSubject,
       now = now ?? DateTime.now;

  Future<void> refresh({String? subjectUserId}) async {
    final ownerId = subjectUserId?.trim().isNotEmpty == true
        ? subjectUserId!.trim()
        : await activeSubjectUserId();
    // Remove the old owner too. The device has one active notification subject;
    // the next sign-in/sign-out refresh will schedule that owner's saved rows.
    await scheduler.cancelMedicationReminders();
    if (ownerId == null || !await masterEnabled(ownerId)) return;

    final reminders = await repository.listForUser(ownerId);
    final minutes =
        reminders
            .where((reminder) => reminder.enabled)
            .expand((reminder) => reminder.reminderMinutes)
            .where((minute) => minute >= 0 && minute < 1440)
            .toSet()
            .toList()
          ..sort();

    for (final minute in minutes) {
      final reminderTime = _nextOccurrence(minute, now());
      final payload = jsonEncode({
        'type': 'medication_reminder',
        'owner_id': ownerId,
        'minute_of_day': minute,
        'route': 'notification_settings',
      });
      await scheduler.scheduleDailyReminder(
        id: deterministicNotificationId('medication:$ownerId:$minute'),
        title: 'Đến giờ uống thuốc',
        body: 'Đến giờ uống thuốc. Mở ứng dụng để xem lịch nhắc.',
        scheduledAt: reminderTime,
        payload: payload,
      );
    }
  }

  Future<void> handleResponse(String? rawPayload) async {
    final payload = _parsePayload(rawPayload);
    if (payload == null) return;
    final ownerId = payload['owner_id']?.toString();
    final minute = payload['minute_of_day'];
    if (ownerId == null || ownerId.isEmpty || minute is! int) return;

    final activeOwner = await activeSubjectUserId();
    if (activeOwner != ownerId) return;
    final reminders = await repository.listForUser(ownerId);
    final isStillScheduled = reminders.any(
      (reminder) =>
          reminder.enabled && reminder.reminderMinutes.contains(minute),
    );
    if (isStillScheduled) {
      NotificationNavigationCoordinator.openNotificationSettings();
    }
  }

  static bool isMedicationPayload(String? rawPayload) =>
      _parsePayload(rawPayload) != null;

  static Map<String, Object?>? _parsePayload(String? rawPayload) {
    final raw = rawPayload?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['type'] != 'medication_reminder') {
        return null;
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }

  static DateTime _nextOccurrence(int minute, DateTime current) {
    final today = DateTime(
      current.year,
      current.month,
      current.day,
      minute ~/ 60,
      minute % 60,
    );
    return today.isAfter(current) ? today : today.add(const Duration(days: 1));
  }
}

MedicationReminderRepository defaultMedicationReminderRepository() =>
    const SqliteMedicationReminderRepository();
