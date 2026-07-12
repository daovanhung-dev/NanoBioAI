import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';

import '../../domain/entities/cloud_sync_result.dart';
import '../../providers/cloud_sync_providers.dart';

class UserDataSyncController extends Notifier<UserDataSyncState> {
  @override
  UserDataSyncState build() => const UserDataSyncState.idle();

  Future<UserDataSyncOutcome> sync(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  }) async {
    state = state.copyWith(
      status: UserDataSyncStatus.syncing,
      clearError: true,
      lastReason: reason,
    );

    try {
      final outcome = await ref
          .read(authenticatedUserDataSyncRepositoryProvider)
          .syncAfterAuthenticatedSession(reason, guestAction: guestAction);
      state = UserDataSyncState.fromOutcome(outcome);
      return outcome;
    } catch (error, stackTrace) {
      AppLogger.error(
        'USER_DATA_SYNC',
        'Sync controller failed',
        error,
        stackTrace,
      );
      final pending = await _safePendingCount();
      final outcome = UserDataSyncOutcome(
        userId: null,
        reason: reason,
        status: UserDataSyncStatus.error,
        pushedLocalGuestData: false,
        cloudHasMeaningfulData: state.cloudHasMeaningfulData,
        pulledTables: const [],
        pendingCount: pending,
        safeError:
            'Chưa thể đồng bộ lúc này. Dữ liệu trên thiết bị vẫn được giữ và sẽ tự thử lại.',
      );
      state = UserDataSyncState.fromOutcome(outcome);
      return outcome;
    }
  }

  Future<UserDataSyncOutcome> retry() {
    return sync(AuthSyncReason.manualRetry);
  }

  Future<int> _safePendingCount() async {
    try {
      return await UserDataSyncOutbox.shared.pendingCountForCurrentUser();
    } catch (_) {
      return 0;
    }
  }

  Future<void> refreshLocalStatus() async {
    final pending = await UserDataSyncOutbox.shared.pendingCountForCurrentUser();
    final lastSuccess = await AppPrefs.lastCloudSyncAt();
    final pullRetryPending = await AppPrefs.isCloudPullRetryPending();
    state = UserDataSyncState(
      status: pending > 0
          ? UserDataSyncStatus.pendingUpload
          : pullRetryPending
          ? UserDataSyncStatus.error
          : UserDataSyncStatus.idle,
      pendingCount: pending,
      lastSuccessAt: lastSuccess,
      safeError: pullRetryPending
          ? 'Chưa thể tải dữ liệu mới nhất. Dữ liệu trên thiết bị vẫn được giữ.'
          : null,
    );
  }
}
