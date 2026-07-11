enum AuthBackendAvailability {
  ready,
  missingConfiguration,
  initializationFailed;

  bool get isReady => this == AuthBackendAvailability.ready;
}

typedef AuthBackendInitializer =
    Future<void> Function(String url, String anonKey);

typedef AuthBackendInitializationErrorHandler =
    void Function(Object error, StackTrace stackTrace);

Future<AuthBackendAvailability> initializeAuthBackendAvailability({
  required ({String url, String anonKey})? config,
  required AuthBackendInitializer initialize,
  AuthBackendInitializationErrorHandler? onInitializationError,
}) async {
  if (config == null) {
    return AuthBackendAvailability.missingConfiguration;
  }

  try {
    await initialize(config.url, config.anonKey);
    return AuthBackendAvailability.ready;
  } catch (error, stackTrace) {
    onInitializationError?.call(error, stackTrace);
    return AuthBackendAvailability.initializationFailed;
  }
}
