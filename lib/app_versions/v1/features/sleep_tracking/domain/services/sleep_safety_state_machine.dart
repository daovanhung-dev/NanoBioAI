enum SleepSafetyPhase { idle, arming, calibrating, monitoring, awaitingResponse, reminder, escalating, cooldown, failed }

class SleepSafetyMachineState {
  const SleepSafetyMachineState({required this.phase, this.eventId, this.alertStartedAt, this.cooldownUntil, this.failureCode});
  const SleepSafetyMachineState.idle() : this(phase: SleepSafetyPhase.idle);
  final SleepSafetyPhase phase;
  final String? eventId;
  final DateTime? alertStartedAt;
  final DateTime? cooldownUntil;
  final String? failureCode;
  int remainingSeconds(DateTime now) {
    final startedAt = alertStartedAt;
    if (startedAt == null) return 0;
    final value = 60 - now.difference(startedAt).inSeconds;
    return value < 0 ? 0 : value;
  }
}

class SleepSafetyStateMachine {
  const SleepSafetyStateMachine({
    this.reminderAfter = const Duration(seconds: 30),
    this.escalateAfter = const Duration(seconds: 60),
    this.defaultCooldown = const Duration(seconds: 120),
  });
  final Duration reminderAfter;
  final Duration escalateAfter;
  final Duration defaultCooldown;
  SleepSafetyMachineState arm() => const SleepSafetyMachineState(phase: SleepSafetyPhase.arming);
  SleepSafetyMachineState calibrate() => const SleepSafetyMachineState(phase: SleepSafetyPhase.calibrating);
  SleepSafetyMachineState monitor() => const SleepSafetyMachineState(phase: SleepSafetyPhase.monitoring);
  SleepSafetyMachineState onConfirmedEvent(SleepSafetyMachineState current, {required String eventId, required DateTime now}) {
    if (current.phase != SleepSafetyPhase.monitoring &&
        current.phase != SleepSafetyPhase.calibrating) {
      return current;
    }
    return SleepSafetyMachineState(phase: SleepSafetyPhase.awaitingResponse, eventId: eventId, alertStartedAt: now);
  }
  SleepSafetyMachineState tick(SleepSafetyMachineState current, {required DateTime now}) {
    final startedAt = current.alertStartedAt;
    if (startedAt == null) return current;
    final elapsed = now.difference(startedAt);
    if (elapsed >= escalateAfter && (current.phase == SleepSafetyPhase.awaitingResponse || current.phase == SleepSafetyPhase.reminder)) {
      return SleepSafetyMachineState(phase: SleepSafetyPhase.escalating, eventId: current.eventId, alertStartedAt: startedAt);
    }
    if (elapsed >= reminderAfter && current.phase == SleepSafetyPhase.awaitingResponse) {
      return SleepSafetyMachineState(phase: SleepSafetyPhase.reminder, eventId: current.eventId, alertStartedAt: startedAt);
    }
    return current;
  }
  SleepSafetyMachineState respondOk(SleepSafetyMachineState current, {required DateTime now, Duration? cooldown}) {
    if (!_isAlertPhase(current.phase)) return current;
    return SleepSafetyMachineState(phase: SleepSafetyPhase.cooldown, eventId: current.eventId, cooldownUntil: now.add(cooldown ?? defaultCooldown));
  }
  SleepSafetyMachineState respondNeedHelp(SleepSafetyMachineState current) {
    if (!_isAlertPhase(current.phase)) return current;
    return SleepSafetyMachineState(phase: SleepSafetyPhase.escalating, eventId: current.eventId, alertStartedAt: current.alertStartedAt);
  }
  SleepSafetyMachineState resolveCooldown(SleepSafetyMachineState current, {required DateTime now}) {
    if (current.phase != SleepSafetyPhase.cooldown) return current;
    final until = current.cooldownUntil;
    if (until != null && now.isBefore(until)) return current;
    return monitor();
  }
  SleepSafetyMachineState fail(String code) => SleepSafetyMachineState(phase: SleepSafetyPhase.failed, failureCode: code);
  bool _isAlertPhase(SleepSafetyPhase phase) => phase == SleepSafetyPhase.awaitingResponse || phase == SleepSafetyPhase.reminder || phase == SleepSafetyPhase.escalating;
}
