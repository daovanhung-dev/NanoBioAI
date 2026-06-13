import 'package:supabase_flutter/supabase_flutter.dart';

/// SettingsRemoteDatasource handles all remote operations for settings
/// including authentication-related operations through Supabase.
///
/// This datasource is responsible for:
/// - Password updates via Supabase auth
/// - User sign out via Supabase auth
class SettingsRemoteDatasource {
  final supabase = Supabase.instance.client;

  /// Updates the user's password in Supabase authentication system
  ///
  /// [newPassword] The new password to set for the authenticated user
  ///
  /// Throws [AuthException] if:
  /// - User is not authenticated
  /// - Password update fails due to Supabase service issues
  /// - Password doesn't meet Supabase password requirements
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (response.user == null) {
        throw AuthException('Failed to update password');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to update password: ${e.toString()}');
    }
  }

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
