import 'dart:async';

import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';

import '../../domain/entities/cloud_sync_result.dart';
import '../../domain/entities/user_data_snapshot.dart';
import '../../domain/repositories/authenticated_user_data_sync_repository.dart';
import '../datasources/user_data_sync_datasource_contracts.dart';

class AuthenticatedUserDataSyncRepositoryImpl
    implements AuthenticatedUserDataSyncRepository {
  static const _tag = 'CLOUD_SYNC';
  static const _safeSyncError =
      'Chưa thể đồng bộ lúc này. Dữ liệu trên thiết bị vẫn được giữ và sẽ tự thử lại.';

  final UserDataSyncRemoteDatasource remoteDatasource;
  final UserDataSyncLocalDatasource localDatasource;
  final UserDataSyncOutbox outbox;

  Future<UserDataSyncOutcome>? _inFlight;

  AuthenticatedUserDataSyncRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    UserDataSyncOutbox? outbox,
  }) : outbox = outbox ?? UserDataSyncOutbox.shared;

  @override
  Future<UserDataSyncOutcome> syncAfterAuthenticatedSession(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  }) {
    final current = _inFlight;
    if (current != null) return current;

    final operation = _runSafely(reason, guestAction: guestAction);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<UserDataSyncOutcome> _runSafely(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  }) async {
    try {
      return await _run(reason, guestAction: guestAction);
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Authenticated sync coordinator failed',
        error,
        stackTrace,
      );
      final userId = remoteDatasource.currentUserId;
      if (userId == null || userId.isEmpty) {
        return UserDataSyncOutcome.noSession(reason);
      }
      return _error(
        userId: userId,
        reason: reason,
        pendingCount: await _safePendingCount(),
      );
    }
  }

  Future<UserDataSyncOutcome> _run(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  }) async {
    final authUserId = remoteDatasource.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      return UserDataSyncOutcome.noSession(reason);
    }

    final pendingUpload = await _drainOutboxBeforePull(
      authUserId: authUserId,
      reason: reason,
    );
    if (pendingUpload != null) return pendingUpload;

    final pendingGuestUserId = await AppPrefs.pendingGuestUserId();
    if (pendingGuestUserId != null && pendingGuestUserId != authUserId) {
      return _resolveGuestConsent(
        authUserId: authUserId,
        guestUserId: pendingGuestUserId,
        reason: reason,
        action: guestAction,
      );
    }

    return _pushThenPull(authUserId: authUserId, reason: reason);
  }

  Future<UserDataSyncOutcome> _resolveGuestConsent({
    required String authUserId,
    required String guestUserId,
    required AuthSyncReason reason,
    required GuestMergeAction? action,
  }) async {
    UserDataSnapshot? cloudSnapshot;
    try {
      cloudSnapshot = await remoteDatasource.pullCurrentUserSnapshot();
    } catch (error, stackTrace) {
      await AppPrefs.setCloudPullRetryPending(true);
      AppLogger.error(
        _tag,
        'Guest consent cloud inspection failed',
        error,
        stackTrace,
      );
      return _error(
        userId: authUserId,
        reason: reason,
        pendingCount: await outbox.pendingCountForCurrentUser(),
      );
    }

    final cloudHasData = _hasMeaningfulCloudData(cloudSnapshot);
    final storedAction = await AppPrefs.pendingGuestSyncActionFor(authUserId);
    final effectiveAction = action ?? _guestActionFromStorage(storedAction);
    if (effectiveAction == null || effectiveAction == GuestMergeAction.defer) {
      return UserDataSyncOutcome(
        userId: authUserId,
        reason: reason,
        status: UserDataSyncStatus.awaitingConsent,
        pushedLocalGuestData: false,
        cloudHasMeaningfulData: cloudHasData,
        pulledTables: const [],
        pendingCount: await outbox.pendingCountForCurrentUser(),
      );
    }

    if (cloudHasData &&
        effectiveAction != GuestMergeAction.useExistingCloud) {
      return UserDataSyncOutcome(
        userId: authUserId,
        reason: reason,
        status: UserDataSyncStatus.awaitingConsent,
        pushedLocalGuestData: false,
        cloudHasMeaningfulData: true,
        pulledTables: const [],
        pendingCount: await outbox.pendingCountForCurrentUser(),
        warnings: const [
          'Tài khoản đã có dữ liệu. Cần xác nhận dùng dữ liệu tài khoản.',
        ],
      );
    }

    if (!cloudHasData && effectiveAction != GuestMergeAction.mergeNow) {
      return UserDataSyncOutcome(
        userId: authUserId,
        reason: reason,
        status: UserDataSyncStatus.awaitingConsent,
        pushedLocalGuestData: false,
        cloudHasMeaningfulData: false,
        pulledTables: const [],
        pendingCount: await outbox.pendingCountForCurrentUser(),
        warnings: const [
          'Tài khoản mới cần xác nhận đồng bộ dữ liệu khách.',
        ],
      );
    }

    await AppPrefs.setPendingGuestSyncDecision(
      authUserId: authUserId,
      action: effectiveAction.name,
    );

    var pushedGuest = false;
    if (!cloudHasData && effectiveAction == GuestMergeAction.mergeNow) {
      final guestSnapshot = await localDatasource.readSnapshot(guestUserId);
      if (guestSnapshot == null || !guestSnapshot.hasUser) {
        await AppPrefs.clearPendingGuestSyncDecision();
        return _error(
          userId: authUserId,
          reason: reason,
          pendingCount: await outbox.pendingCountForCurrentUser(),
          message: 'Không tìm thấy dữ liệu khách để đồng bộ. Dữ liệu chưa bị xóa.',
        );
      }

      try {
        await remoteDatasource.replaceCloudWithLocalSnapshot(
          guestSnapshot,
          authUserId,
        );
        pushedGuest = true;
        await AppPrefs.setPendingGuestSyncDecision(
          authUserId: authUserId,
          action: GuestMergeAction.useExistingCloud.name,
        );
        cloudSnapshot = await remoteDatasource.pullCurrentUserSnapshot();
      } catch (error, stackTrace) {
        await AppPrefs.setCloudPullRetryPending(true);
        AppLogger.error(_tag, 'Guest upload failed', error, stackTrace);
        return _error(
          userId: authUserId,
          reason: reason,
          pendingCount: await outbox.pendingCountForCurrentUser(),
        );
      }
    }

    if (cloudSnapshot == null || !cloudSnapshot.hasUser) {
      return _error(
        userId: authUserId,
        reason: reason,
        pendingCount: await outbox.pendingCountForCurrentUser(),
      );
    }

    try {
      await localDatasource.replaceFromCloud(
        userId: authUserId,
        snapshot: cloudSnapshot,
        removeLocalUserId: guestUserId,
      );
      await AppPrefs.clearPendingGuestUserId();
      await AppPrefs.clearPendingGuestSyncDecision();
      return _complete(
        userId: authUserId,
        reason: reason,
        snapshot: cloudSnapshot,
        pushedGuest: pushedGuest,
      );
    } catch (error, stackTrace) {
      await AppPrefs.setCloudPullRetryPending(true);
      AppLogger.error(
        _tag,
        'Guest projection replacement failed',
        error,
        stackTrace,
      );
      return _error(
        userId: authUserId,
        reason: reason,
        pendingCount: await outbox.pendingCountForCurrentUser(),
      );
    }
  }

  Future<UserDataSyncOutcome?> _drainOutboxBeforePull({
    required String authUserId,
    required AuthSyncReason reason,
  }) async {
    await outbox.makeRetriesDueForCurrentUser();
    final pendingBefore = await outbox.pendingCountForCurrentUser();
    if (pendingBefore == 0) return null;

    await outbox.drainPending();
    final pendingAfter = await outbox.pendingCountForCurrentUser();
    if (pendingAfter == 0) return null;

    return UserDataSyncOutcome(
      userId: authUserId,
      reason: reason,
      status: UserDataSyncStatus.pendingUpload,
      pushedLocalGuestData: false,
      cloudHasMeaningfulData: false,
      pulledTables: const [],
      pendingCount: pendingAfter,
      safeError: _safeSyncError,
    );
  }

  Future<UserDataSyncOutcome> _pushThenPull({
    required String authUserId,
    required AuthSyncReason reason,
  }) async {
    UserDataSnapshot? cloudSnapshot;
    try {
      cloudSnapshot = await remoteDatasource.pullCurrentUserSnapshot();
      if (cloudSnapshot == null || !cloudSnapshot.hasUser) {
        return _error(userId: authUserId, reason: reason, pendingCount: 0);
      }

      await localDatasource.replaceFromCloud(
        userId: authUserId,
        snapshot: cloudSnapshot,
      );
      return _complete(
        userId: authUserId,
        reason: reason,
        snapshot: cloudSnapshot,
      );
    } on LocalSyncPendingWriteException catch (error) {
      return UserDataSyncOutcome(
        userId: authUserId,
        reason: reason,
        status: UserDataSyncStatus.pendingUpload,
        pushedLocalGuestData: false,
        cloudHasMeaningfulData: _hasMeaningfulCloudData(cloudSnapshot),
        pulledTables: const [],
        pendingCount: error.pendingCount,
        safeError: _safeSyncError,
      );
    } catch (error, stackTrace) {
      await AppPrefs.setCloudPullRetryPending(true);
      AppLogger.error(
        _tag,
        'Pull after confirmed push failed',
        error,
        stackTrace,
      );
      return _error(userId: authUserId, reason: reason, pendingCount: 0);
    }
  }

  Future<UserDataSyncOutcome> _complete({
    required String userId,
    required AuthSyncReason reason,
    required UserDataSnapshot snapshot,
    bool pushedGuest = false,
  }) async {
    final completedAt = DateTime.now().toUtc();
    await AppPrefs.setCloudPullRetryPending(false);
    await AppPrefs.setLastCloudSyncAt(completedAt);
    await AppPrefs.setOnboardingCompleted(
      snapshot.user?['onboarding_status']?.toString() == 'completed',
    );

    return UserDataSyncOutcome(
      userId: userId,
      reason: reason,
      status: UserDataSyncStatus.success,
      pushedLocalGuestData: pushedGuest,
      cloudHasMeaningfulData: _hasMeaningfulCloudData(snapshot),
      pulledTables: _pulledTables(snapshot),
      pendingCount: 0,
      completedAt: completedAt,
    );
  }

  UserDataSyncOutcome _error({
    required String userId,
    required AuthSyncReason reason,
    required int pendingCount,
    String message = _safeSyncError,
  }) {
    return UserDataSyncOutcome(
      userId: userId,
      reason: reason,
      status: UserDataSyncStatus.error,
      pushedLocalGuestData: false,
      cloudHasMeaningfulData: false,
      pulledTables: const [],
      pendingCount: pendingCount,
      safeError: message,
    );
  }

  Future<int> _safePendingCount() async {
    try {
      return await outbox.pendingCountForCurrentUser();
    } catch (_) {
      return 0;
    }
  }

  GuestMergeAction? _guestActionFromStorage(String? value) {
    if (value == null) return null;
    for (final action in GuestMergeAction.values) {
      if (action.name == value) return action;
    }
    return null;
  }

  bool _hasMeaningfulCloudData(UserDataSnapshot? snapshot) {
    if (snapshot == null || !snapshot.hasUser) return false;
    final onboardingStatus = snapshot.user?['onboarding_status']?.toString();
    return onboardingStatus == 'completed' || snapshot.tablesWithRows.isNotEmpty;
  }

  List<String> _pulledTables(UserDataSnapshot snapshot) {
    return <String>[if (snapshot.hasUser) 'users', ...snapshot.tablesWithRows];
  }
}
