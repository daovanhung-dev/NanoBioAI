class HealthContextFreshness {
  final Set<String> missingGroups;
  final Set<String> staleGroups;

  const HealthContextFreshness({
    this.missingGroups = const <String>{},
    this.staleGroups = const <String>{},
  });

  bool get isComplete => missingGroups.isEmpty;
  bool get hasStaleData => staleGroups.isNotEmpty;
}
