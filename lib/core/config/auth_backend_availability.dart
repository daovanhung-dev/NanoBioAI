enum AuthBackendAvailability {
  ready,
  missingConfiguration,
  initializationFailed;

  bool get isReady => this == AuthBackendAvailability.ready;
}

typedef AuthBackendInitializer = Future<void> Function(String baseUrl);

typedef AuthBackendInitializationErrorHandler =
    void Function(Object error, StackTrace stackTrace);

Future<AuthBackendAvailability> initializeAuthBackendAvailability({
  required String? baseUrl,
  required AuthBackendInitializer initialize,
  AuthBackendInitializationErrorHandler? onInitializationError,
}) async {
  final normalizedBaseUrl = baseUrl?.trim();
  if (normalizedBaseUrl == null || normalizedBaseUrl.isEmpty) {
    return AuthBackendAvailability.missingConfiguration;
  }

  try {
    await initialize(normalizedBaseUrl);
    return AuthBackendAvailability.ready;
  } catch (error, stackTrace) {
    onInitializationError?.call(error, stackTrace);
    return AuthBackendAvailability.initializationFailed;
  }
}
