import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/domain/repositories/medication_reminder_repository.dart';
import 'package:nano_app/app_versions/v1/services/notifications/medication_reminder_coordinator.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_notification_scheduler.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';

void main() {
  late _MemoryRepository repository;
  late _FakeDailyScheduler scheduler;
  late MedicationReminderCoordinator coordinator;
  final scheduledAt = DateTime(2026, 10, 15, 7);

  setUp(() {
    repository = _MemoryRepository([
      _reminder('one', 'Sensitive name one', [480, 600]),
      _reminder('two', 'Sensitive name two', [480]),
      _reminder('paused', 'Sensitive name paused', [720], enabled: false),
    ]);
    scheduler = _FakeDailyScheduler();
    coordinator = MedicationReminderCoordinator(
      repository: repository,
      scheduler: scheduler,
      masterEnabled: (_) async => true,
      activeSubjectUserId: () async => 'guest-1',
      now: () => scheduledAt,
    );
    NotificationNavigationCoordinator.resetForTest();
  });

  test('coalesces shared times and schedules generic daily alerts', () async {
    await coordinator.refresh();

    expect(scheduler.cancelCalls, 1);
    expect(scheduler.scheduled, hasLength(2));
    expect(scheduler.scheduled.map((entry) => entry.scheduledAt), [
      DateTime(2026, 10, 15, 8),
      DateTime(2026, 10, 15, 10),
    ]);
    for (final entry in scheduler.scheduled) {
      expect(entry.title, 'Đến giờ uống thuốc');
      expect(entry.body, isNot(contains('Sensitive name')));
      expect(entry.payload, isNot(contains('Sensitive name')));
      expect(jsonDecode(entry.payload)['type'], 'medication_reminder');
    }
  });

  test(
    'refresh cancels old alerts before scheduling the edited times',
    () async {
      await coordinator.refresh();
      repository.reminders = [
        _reminder('one', 'Private name', [540]),
      ];
      await coordinator.refresh();

      expect(scheduler.cancelCalls, 2);
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.scheduledAt, DateTime(2026, 10, 15, 9));
    },
  );

  test(
    'valid tap opens settings only for current owner and active schedule',
    () async {
      await coordinator.refresh();
      final payload = scheduler.scheduled.first.payload;
      final routes = <Uri>[];
      NotificationNavigationCoordinator.register(routes.add);

      await coordinator.handleResponse(payload);
      expect(routes.map((uri) => uri.path), [
        V1RoutePaths.notificationSettings,
      ]);

      routes.clear();
      repository.reminders = [];
      await coordinator.handleResponse(payload);
      expect(routes, isEmpty);
    },
  );

  test(
    'tap from a different active owner does not expose reminder settings',
    () async {
      await coordinator.refresh();
      final payload = scheduler.scheduled.first.payload;
      final routes = <Uri>[];
      NotificationNavigationCoordinator.register(routes.add);
      coordinator = MedicationReminderCoordinator(
        repository: repository,
        scheduler: scheduler,
        masterEnabled: (_) async => true,
        activeSubjectUserId: () async => 'another-user',
        now: () => scheduledAt,
      );

      await coordinator.handleResponse(payload);
      expect(routes, isEmpty);
    },
  );
}

MedicationReminder _reminder(
  String id,
  String name,
  List<int> minutes, {
  bool enabled = true,
}) => MedicationReminder(
  id: id,
  userId: 'guest-1',
  medicineName: name,
  reminderMinutes: minutes,
  enabled: enabled,
  createdAt: DateTime(2026, 10, 15),
  updatedAt: DateTime(2026, 10, 15),
);

class _MemoryRepository implements MedicationReminderRepository {
  List<MedicationReminder> reminders;

  _MemoryRepository(this.reminders);

  @override
  Future<List<MedicationReminder>> listForUser(String userId) async =>
      reminders.where((reminder) => reminder.userId == userId).toList();

  @override
  Future<void> create({
    required String userId,
    required String medicineName,
    required List<int> minutes,
  }) async {
    final timestamp = DateTime.now();
    reminders = [
      ...reminders,
      MedicationReminder(
        id: 'created-${reminders.length}',
        userId: userId,
        medicineName: medicineName,
        reminderMinutes: minutes,
        enabled: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ];
  }

  @override
  Future<void> updateMedicineName({
    required String userId,
    required String reminderId,
    required String medicineName,
  }) async {
    reminders = reminders
        .map(
          (reminder) => reminder.id == reminderId && reminder.userId == userId
              ? reminder.copyWith(medicineName: medicineName)
              : reminder,
        )
        .toList();
  }

  @override
  Future<void> delete({
    required String userId,
    required String reminderId,
  }) async {
    reminders = reminders
        .where(
          (reminder) => reminder.userId != userId || reminder.id != reminderId,
        )
        .toList();
  }

  @override
  Future<void> setEnabled({
    required String userId,
    required String reminderId,
    required bool enabled,
  }) async {}

  @override
  Future<void> updateTimes({
    required String userId,
    required String reminderId,
    required List<int> minutes,
  }) async {}
}

class _FakeDailyScheduler implements MedicationDailyNotificationScheduler {
  final List<_ScheduledAlert> scheduled = [];
  int cancelCalls = 0;

  @override
  Future<void> cancelMedicationReminders({String? ownerId}) async {
    cancelCalls++;
    scheduled.clear();
  }

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    scheduled.add(
      _ScheduledAlert(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        payload: payload,
      ),
    );
  }
}

class _ScheduledAlert {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String payload;

  const _ScheduledAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });
}
