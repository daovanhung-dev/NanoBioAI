import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/services/notifications/notification_lifecycle_refresher.dart';
import 'package:nano_app/services/notifications/notification_startup_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start refreshes reminders immediately', () async {
    var refreshCalls = 0;
    final refresher = NotificationLifecycleRefresher(
      startupScheduler: NotificationStartupScheduler(
        isOnboardingCompleted: () async => true,
        scheduleGeneratedReminders: () async {
          refreshCalls++;
        },
      ),
    );

    refresher.start();
    await Future<void>.delayed(Duration.zero);
    refresher.dispose();

    expect(refreshCalls, 1);
  });

  test('resumed refresh is throttled until interval passes', () async {
    var refreshCalls = 0;
    var now = DateTime(2026, 6, 18, 9);
    final refresher = NotificationLifecycleRefresher(
      startupScheduler: NotificationStartupScheduler(
        isOnboardingCompleted: () async => true,
        scheduleGeneratedReminders: () async {
          refreshCalls++;
        },
      ),
      now: () => now,
    );

    await refresher.handleLifecycleState(AppLifecycleState.resumed);
    await refresher.handleLifecycleState(AppLifecycleState.resumed);
    now = now.add(const Duration(minutes: 16));
    await refresher.handleLifecycleState(AppLifecycleState.resumed);

    expect(refreshCalls, 2);
  });

  test('ignores non-resumed lifecycle states', () async {
    var refreshCalls = 0;
    final refresher = NotificationLifecycleRefresher(
      startupScheduler: NotificationStartupScheduler(
        isOnboardingCompleted: () async => true,
        scheduleGeneratedReminders: () async {
          refreshCalls++;
        },
      ),
    );

    await refresher.handleLifecycleState(AppLifecycleState.paused);

    expect(refreshCalls, 0);
  });

  test('does not throw when lifecycle refresh fails', () async {
    final refresher = NotificationLifecycleRefresher(
      startupScheduler: NotificationStartupScheduler(
        isOnboardingCompleted: () async => true,
        scheduleGeneratedReminders: () async {
          throw StateError('schedule failed');
        },
      ),
    );

    await expectLater(
      refresher.handleLifecycleState(AppLifecycleState.resumed),
      completes,
    );
  });
}
