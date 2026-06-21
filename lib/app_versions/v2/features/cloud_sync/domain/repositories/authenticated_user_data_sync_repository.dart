import '../entities/cloud_sync_result.dart';

abstract interface class AuthenticatedUserDataSyncRepository {
  Future<CloudSyncResult> syncAfterAuthenticatedSession(AuthSyncReason reason);
}
