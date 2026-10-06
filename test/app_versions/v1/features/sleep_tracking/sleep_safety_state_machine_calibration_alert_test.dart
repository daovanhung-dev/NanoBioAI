import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart';

void main() {
  test(
    'automatic escalation becomes due after 15 seconds without response',
    () {
      const machine = SleepSafetyStateMachine();
      final now = DateTime(2026, 10, 6, 4);
      final alert = machine.onConfirmedEvent(
        machine.monitor(),
        eventId: 'event-15-second-timeout',
        now: now,
      );

      expect(alert.remainingSeconds(now), 15);
      expect(
        machine.tick(alert, now: now.add(const Duration(seconds: 14))).phase,
        SleepSafetyPhase.awaitingResponse,
      );
      final due = machine.tick(
        alert,
        now: now.add(const Duration(seconds: 15)),
      );

      expect(due.phase, SleepSafetyPhase.escalating);
      expect(due.remainingSeconds(now.add(const Duration(seconds: 15))), 0);
    },
  );

  test('confirmed acoustic event can interrupt calibration safely', () {
    const machine = SleepSafetyStateMachine();
    final now = DateTime(2026, 8, 24, 4);

    final next = machine.onConfirmedEvent(
      machine.calibrate(),
      eventId: 'event-calibration-bypass',
      now: now,
    );

    expect(next.phase, SleepSafetyPhase.awaitingResponse);
    expect(next.eventId, 'event-calibration-bypass');
    expect(next.alertStartedAt, now);
  });

  test(
    'manual help is separate from automatic escalation and stays actionable',
    () {
      const machine = SleepSafetyStateMachine();
      final now = DateTime(2026, 8, 24, 4);
      final alert = machine.onConfirmedEvent(
        machine.monitor(),
        eventId: 'event-manual-help',
        now: now,
      );

      final help = machine.respondNeedHelp(alert);
      final afterTimeout = machine.tick(
        help,
        now: now.add(const Duration(minutes: 2)),
      );

      expect(help.phase, SleepSafetyPhase.manualHelp);
      expect(afterTimeout.phase, SleepSafetyPhase.manualHelp);
      expect(afterTimeout.eventId, 'event-manual-help');
    },
  );
}
