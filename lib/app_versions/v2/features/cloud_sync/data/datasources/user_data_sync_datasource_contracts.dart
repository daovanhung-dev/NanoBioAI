import '../../domain/entities/user_data_snapshot.dart';

abstract interface class UserDataSyncLocalDatasource {
  Future<UserDataSnapshot?> readSnapshot(String userId);

  Future<void> replaceFromCloud({
    required String userId,
    required UserDataSnapshot snapshot,
    String? removeLocalUserId,
  });
}

abstract interface class UserDataSyncRemoteDatasource {
  String? get currentUserId;

  Future<Map<String, Object?>?> currentUserRow();

  Future<UserDataSnapshot?> pullCurrentUserSnapshot();

  Future<void> replaceCloudWithLocalSnapshot(
    UserDataSnapshot localSnapshot,
    String authUserId,
  );
}

class LocalSyncPendingWriteException implements Exception {
  final int pendingCount;

  const LocalSyncPendingWriteException(this.pendingCount);
}
