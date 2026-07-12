import '../entities/cloud_sync_result.dart';

abstract interface class AuthenticatedUserDataSyncRepository {
  Future<UserDataSyncOutcome> syncAfterAuthenticatedSession(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  });
}
