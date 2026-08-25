enum HealthProjectionTarget {
  healthContext,
  dashboard,
  bodyMetrics,
  nutrition,
  schedule,
  weeklySummary,
  nabiCare,
  notifications,
}

class HealthEventImpact {
  final Set<HealthProjectionTarget> targets;
  final bool evaluateNabi;
  final bool reconcileNotifications;

  const HealthEventImpact({
    this.targets = const <HealthProjectionTarget>{},
    this.evaluateNabi = false,
    this.reconcileNotifications = false,
  });

  bool affects(HealthProjectionTarget target) => targets.contains(target);
}
