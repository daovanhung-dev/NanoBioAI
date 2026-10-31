enum AuthSyncReason {
  signIn,
  signUpSessionReady,
  authCallback,
  authGateRefresh,
  startup,
  resume,
  connectivity,
  manualRetry,
  signOutPreflight,
}

enum GuestMergeAction { mergeNow, defer, useExistingCloud }

enum UserDataSyncStatus {
  idle,
  awaitingConsent,
  syncing,
  pendingUpload,
  success,
  error,
}

abstract interface class AuthenticatedUserDataSyncRepository {
  Future<UserDataSyncOutcome> syncAfterAuthenticatedSession(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  });
}

class UserDataSyncOutcome {
  final String? userId;
  final AuthSyncReason reason;
  final UserDataSyncStatus status;
  final bool pushedLocalGuestData;
  final bool cloudHasMeaningfulData;
  final List<String> pulledTables;
  final int pendingCount;
  final DateTime? completedAt;
  final String? safeError;
  final List<String> warnings;

  const UserDataSyncOutcome({
    required this.userId,
    required this.reason,
    required this.status,
    required this.pushedLocalGuestData,
    required this.cloudHasMeaningfulData,
    required this.pulledTables,
    required this.pendingCount,
    this.completedAt,
    this.safeError,
    this.warnings = const [],
  });

  bool get pulledAnyData => pulledTables.isNotEmpty;
  bool get needsConsent => status == UserDataSyncStatus.awaitingConsent;
  bool get hasPendingUpload => status == UserDataSyncStatus.pendingUpload;
  bool get isSuccess => status == UserDataSyncStatus.success;

  factory UserDataSyncOutcome.noSession(AuthSyncReason reason) {
    return UserDataSyncOutcome(
      userId: null,
      reason: reason,
      status: UserDataSyncStatus.idle,
      pushedLocalGuestData: false,
      cloudHasMeaningfulData: false,
      pulledTables: const [],
      pendingCount: 0,
      warnings: const ['Không có phiên đăng nhập hợp lệ.'],
    );
  }
}

/// Compatibility wrapper for older focused tests and callers.
class CloudSyncResult extends UserDataSyncOutcome {
  const CloudSyncResult({
    required super.userId,
    required super.reason,
    required super.pushedLocalGuestData,
    required super.pulledTables,
    super.warnings,
    super.status = UserDataSyncStatus.success,
    super.cloudHasMeaningfulData = false,
    super.pendingCount = 0,
    super.completedAt,
    super.safeError,
  });

  factory CloudSyncResult.noSession(AuthSyncReason reason) {
    return CloudSyncResult(
      userId: null,
      reason: reason,
      status: UserDataSyncStatus.idle,
      pushedLocalGuestData: false,
      pulledTables: const [],
      warnings: const ['Không có phiên đăng nhập hợp lệ.'],
    );
  }
}

class UserDataSyncState {
  final UserDataSyncStatus status;
  final int pendingCount;
  final DateTime? lastSuccessAt;
  final String? safeError;
  final bool cloudHasMeaningfulData;
  final AuthSyncReason? lastReason;

  const UserDataSyncState({
    required this.status,
    this.pendingCount = 0,
    this.lastSuccessAt,
    this.safeError,
    this.cloudHasMeaningfulData = false,
    this.lastReason,
  });

  const UserDataSyncState.idle()
    : status = UserDataSyncStatus.idle,
      pendingCount = 0,
      lastSuccessAt = null,
      safeError = null,
      cloudHasMeaningfulData = false,
      lastReason = null;

  factory UserDataSyncState.fromOutcome(UserDataSyncOutcome outcome) {
    return UserDataSyncState(
      status: outcome.status,
      pendingCount: outcome.pendingCount,
      lastSuccessAt: outcome.completedAt,
      safeError: outcome.safeError,
      cloudHasMeaningfulData: outcome.cloudHasMeaningfulData,
      lastReason: outcome.reason,
    );
  }

  UserDataSyncState copyWith({
    UserDataSyncStatus? status,
    int? pendingCount,
    DateTime? lastSuccessAt,
    String? safeError,
    bool clearError = false,
    bool? cloudHasMeaningfulData,
    AuthSyncReason? lastReason,
  }) {
    return UserDataSyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      safeError: clearError ? null : safeError ?? this.safeError,
      cloudHasMeaningfulData:
          cloudHasMeaningfulData ?? this.cloudHasMeaningfulData,
      lastReason: lastReason ?? this.lastReason,
    );
  }
}
