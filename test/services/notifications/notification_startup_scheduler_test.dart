import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_startup_scheduler.dart';

void main() {
  test('does not refresh reminders before onboarding is completed', () async {
    var scheduleCalls = 0;
    final scheduler = NotificationStartupScheduler(
      isOnboardingCompleted: () async => false,
      scheduleGeneratedReminders: () async {
        scheduleCalls++;
      },
    );

    await scheduler.refreshGeneratedReminders();

    expect(scheduleCalls, 0);
  });

  test('refreshes generated reminders after onboarding is completed', () async {
    var scheduleCalls = 0;
    final scheduler = NotificationStartupScheduler(
      isOnboardingCompleted: () async => true,
      scheduleGeneratedReminders: () async {
        scheduleCalls++;
      },
    );

    await scheduler.refreshGeneratedReminders();

    expect(scheduleCalls, 1);
  });

  test('does not throw when reminder refresh fails', () async {
    final scheduler = NotificationStartupScheduler(
      isOnboardingCompleted: () async => true,
      scheduleGeneratedReminders: () async {
        throw StateError('schedule failed');
      },
    );

    await expectLater(scheduler.refreshGeneratedReminders(), completes);
  });
}
