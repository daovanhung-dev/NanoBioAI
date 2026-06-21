import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

import '../../domain/entities/cloud_sync_result.dart';
import '../../domain/entities/user_data_snapshot.dart';
import '../../domain/repositories/authenticated_user_data_sync_repository.dart';
import '../datasources/user_data_sync_datasource_contracts.dart';

class AuthenticatedUserDataSyncRepositoryImpl
    implements AuthenticatedUserDataSyncRepository {
  static const _tag = 'CLOUD_SYNC';

  final UserDataSyncRemoteDatasource remoteDatasource;
  final UserDataSyncLocalDatasource localDatasource;

  const AuthenticatedUserDataSyncRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<CloudSyncResult> syncAfterAuthenticatedSession(
    AuthSyncReason reason,
  ) async {
    final authUserId = remoteDatasource.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      return CloudSyncResult.noSession(reason);
    }

    final warnings = <String>[];
    var pushedLocalGuestData = false;

    try {
      final pendingGuestUserId = await AppPrefs.pendingGuestUserId();
      final cloudUser = await remoteDatasource.currentUserRow();
      final cloudCompleted =
          cloudUser?['onboarding_status']?.toString() == 'completed';

      if (pendingGuestUserId != null && !cloudCompleted) {
        final guestSnapshot = await localDatasource.readSnapshot(
          pendingGuestUserId,
        );

        if (guestSnapshot != null && guestSnapshot.hasUser) {
          AppLogger.info(
            _tag,
            'Pushing pending guest data to authenticated user $authUserId',
          );
          await remoteDatasource.replaceCloudWithLocalSnapshot(
            guestSnapshot,
            authUserId,
          );
          pushedLocalGuestData = true;
        } else {
          warnings.add('Pending guest data was not found in local SQLite.');
        }
      } else if (pendingGuestUserId != null && cloudCompleted) {
        AppLogger.info(
          _tag,
          'Cloud onboarding already completed; pulling cloud over guest cache.',
        );
      }

      final cloudSnapshot = await remoteDatasource.pullCurrentUserSnapshot();
      if (cloudSnapshot == null || !cloudSnapshot.hasUser) {
        warnings.add('Cloud profile was not available for pull.');
        return CloudSyncResult(
          userId: authUserId,
          reason: reason,
          pushedLocalGuestData: pushedLocalGuestData,
          pulledTables: const [],
          warnings: warnings,
        );
      }

      await localDatasource.replaceFromCloud(
        userId: authUserId,
        snapshot: cloudSnapshot,
        removeLocalUserId: _oldGuestIdForRemoval(
          pendingGuestUserId,
          authUserId,
        ),
      );

      await AppPrefs.clearPendingGuestUserId();
      await AppPrefs.setLastCloudSyncAt(DateTime.now());

      final pulledTables = _pulledTables(cloudSnapshot);
      AppLogger.success(
        _tag,
        'Cloud sync completed for $authUserId (${pulledTables.join(', ')})',
      );

      return CloudSyncResult(
        userId: authUserId,
        reason: reason,
        pushedLocalGuestData: pushedLocalGuestData,
        pulledTables: pulledTables,
        warnings: warnings,
      );
    } catch (error, stackTrace) {
      AppLogger.error(_tag, 'Cloud sync failed', error, stackTrace);
      rethrow;
    }
  }

  String? _oldGuestIdForRemoval(String? pendingGuestUserId, String authUserId) {
    if (pendingGuestUserId == null || pendingGuestUserId == authUserId) {
      return null;
    }

    return pendingGuestUserId;
  }

  List<String> _pulledTables(UserDataSnapshot snapshot) {
    return <String>[if (snapshot.hasUser) 'users', ...snapshot.tablesWithRows];
  }
}
