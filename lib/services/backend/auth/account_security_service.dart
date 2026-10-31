import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountSecurityService {
  final BackendApiClient? clientOverride;

  const AccountSecurityService({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  Future<void> changePassword(String newPassword) async {
    await _requireClient().changePassword(newPassword);
  }

  Future<void> signOut() async {
    await _client.signOut();
    await AppPrefs.setOnboardingCompleted(false);
  }

  Future<void> requestAccountDeletion() async {
    final client = _requireClient();
    final userId = client.currentUserId!;
    await client.requestMap(
      'DELETE',
      '/api/v1/account',
      body: const {'confirm': true},
    );
    try {
      // The server owns deletion of remote rows/storage. Clean every local
      // surface before releasing the session so an offline launch cannot show
      // data belonging to the deleted account.
      try {
        await NotificationBootstrap.clearGeneratedReminders(
          subjectUserId: userId,
        );
      } catch (error, stackTrace) {
        AppLogger.error(
          'ACCOUNT_SECURITY',
          'Failed to clear account notification schedules',
          error,
          stackTrace,
        );
      }
      await DatabaseService.deleteDatabaseFile();
      await AppPrefs.clearAll();
      try {
        await const FlutterSecureStorage().deleteAll();
      } catch (error, stackTrace) {
        // Secure storage is optional on unsupported desktop/test platforms;
        // never retain a stale account session just because it is unavailable.
        AppLogger.error(
          'ACCOUNT_SECURITY',
          'Failed to clear secure account state',
          error,
          stackTrace,
        );
      }
    } finally {
      try {
        await client.signOut();
      } catch (error, stackTrace) {
        // Local session persistence was already cleared; keep the successful
        // server deletion from being reported as a retryable failure when the
        // auth transport is unavailable during sign-out.
        AppLogger.error(
          'ACCOUNT_SECURITY',
          'Sign-out after account deletion failed',
          error,
          stackTrace,
        );
      }
    }
  }

  BackendApiClient _requireClient() {
    final client = _client;
    if (client.session == null) {
      throw const BackendApiException(
        statusCode: 401,
        businessCode: 'AUTHENTICATION_REQUIRED',
        message: 'Bạn cần đăng nhập để tiếp tục.',
      );
    }
    return client;
  }
}
