import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSecurityService {
  final SupabaseClient? clientOverride;
  final String deleteAccountFunctionName;

  AccountSecurityService({
    this.clientOverride,
    String? deleteAccountFunctionName,
  }) : deleteAccountFunctionName =
           deleteAccountFunctionName ?? _defaultDeleteAccountFunctionName;

  static String get _defaultDeleteAccountFunctionName {
    return AppEnv.maybeString('AUTH_DELETE_ACCOUNT_FUNCTION') ??
        'delete-account';
  }

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _requireClient();
    final response = await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    if (response.user == null) {
      throw AuthException('Failed to update password.');
    }
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    await AppPrefs.setOnboardingCompleted(false);
  }

  Future<void> requestAccountDeletion() async {
    final client = _requireClient();
    final userId = client.auth.currentUser!.id;
    await client.functions.invoke(
      deleteAccountFunctionName,
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
        await client.auth.signOut();
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

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw AuthException('Missing authenticated user.');
    }
    return client;
  }
}
