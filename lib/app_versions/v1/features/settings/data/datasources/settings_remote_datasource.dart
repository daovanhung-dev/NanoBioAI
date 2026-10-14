import 'package:supabase_flutter/supabase_flutter.dart';

/// SettingsRemoteDatasource handles remote sign out for settings.
class SettingsRemoteDatasource {
  final supabase = Supabase.instance.client;

  /// Signs out the current user from Supabase authentication
  ///
  /// This method clears the Supabase session but does NOT clear local data.
  /// Local data clearing should be handled by the repository layer.
  ///
  /// Throws [AuthException] if:
  /// - Sign out fails due to Supabase service issues
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }
}
