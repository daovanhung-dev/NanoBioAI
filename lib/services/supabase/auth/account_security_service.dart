import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
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
    return dotenv.maybeGet('AUTH_DELETE_ACCOUNT_FUNCTION') ?? 'delete-account';
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
    await client.functions.invoke(deleteAccountFunctionName);
    await AppPrefs.setOnboardingCompleted(false);
    await client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw AuthException('Missing authenticated user.');
    }
    return client;
  }
}
