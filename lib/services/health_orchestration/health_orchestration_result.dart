class HealthOrchestrationResult {
  final bool accepted;
  final bool duplicate;
  final int handlerCount;
  final List<Object> handlerErrors;

  const HealthOrchestrationResult({
    required this.accepted,
    required this.duplicate,
    required this.handlerCount,
    this.handlerErrors = const <Object>[],
  });

  bool get isSuccess => accepted && handlerErrors.isEmpty;

  const HealthOrchestrationResult.duplicate()
      : accepted = false,
        duplicate = true,
        handlerCount = 0,
        handlerErrors = const <Object>[];
}
