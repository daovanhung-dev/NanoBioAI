enum AuthSyncReason {
  signIn,
  signUpSessionReady,
  authCallback,
  authGateRefresh,
}

class CloudSyncResult {
  final String? userId;
  final AuthSyncReason reason;
  final bool pushedLocalGuestData;
  final List<String> pulledTables;
  final List<String> warnings;

  const CloudSyncResult({
    required this.userId,
    required this.reason,
    required this.pushedLocalGuestData,
    required this.pulledTables,
    this.warnings = const [],
  });

  bool get pulledAnyData => pulledTables.isNotEmpty;

  factory CloudSyncResult.noSession(AuthSyncReason reason) {
    return CloudSyncResult(
      userId: null,
      reason: reason,
      pushedLocalGuestData: false,
      pulledTables: const [],
      warnings: const ['No authenticated session; cloud sync skipped.'],
    );
  }
}
