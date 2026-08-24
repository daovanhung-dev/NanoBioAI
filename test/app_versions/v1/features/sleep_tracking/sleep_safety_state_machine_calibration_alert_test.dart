import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart';

void main() {
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
}
