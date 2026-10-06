class SleepSafetyDispatchException implements Exception {
  const SleepSafetyDispatchException(this.code);

  final String code;

  bool get isTransportFailure => code == 'network_unavailable';

  @override
  String toString() => code;
}
