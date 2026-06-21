import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRemoteDatasource {
  final SupabaseClient client;
  final String? emailRedirectUrl;
  final String deleteAccountFunctionName;

  SupabaseAuthRemoteDatasource({
    SupabaseClient? client,
    String? emailRedirectUrl,
    String? deleteAccountFunctionName,
  }) : client = client ?? Supabase.instance.client,
       emailRedirectUrl = emailRedirectUrl ?? _env('AUTH_EMAIL_REDIRECT_URL'),
       deleteAccountFunctionName =
           deleteAccountFunctionName ??
           _env('AUTH_DELETE_ACCOUNT_FUNCTION') ??
           'delete-account';

  Stream<void> watchAuthChanges() {
    return client.auth.onAuthStateChange.map<void>((_) {});
  }

  AuthSessionSnapshot? currentSessionSnapshot() {
    final user = client.auth.currentUser;
    if (user == null) return null;

    return AuthSessionSnapshot(
      userId: user.id,
      email: user.email,
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  Future<AuthProfile?> getCurrentProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await client
        .from('users')
        .select('id,onboarding_status,subscription_tier')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return AuthProfile.fromMap(Map<String, Object?>.from(row));
  }

  Future<AuthResponse> signUp(RegisterCommand command) {
    final fullName = command.fullName?.trim();
    final phone = command.phone?.trim();

    return client.auth.signUp(
      email: command.email.trim(),
      password: command.password,
      emailRedirectTo: emailRedirectUrl,
      data: {
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<void> signIn(LoginCommand command) async {
    await client.auth.signInWithPassword(
      email: command.email.trim(),
      password: command.password,
    );
  }

  Future<void> resendEmailConfirmation(String email) async {
    await client.auth.resend(
      email: email.trim(),
      type: OtpType.signup,
      emailRedirectTo: emailRedirectUrl,
    );
  }

  Future<void> sendPasswordRecovery(String email) async {
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: emailRedirectUrl,
    );
  }

  Future<void> updatePassword(UpdatePasswordCommand command) async {
    await client.auth.updateUser(UserAttributes(password: command.newPassword));
  }

  Future<void> recoverSessionFromUri(Uri uri) async {
    await client.auth.getSessionFromUrl(uri);
  }

  Future<void> touchLastLogin() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client
        .from('users')
        .update({'last_login_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }

  Future<void> signOut() {
    return client.auth.signOut();
  }

  Future<void> requestAccountDeletion() async {
    await client.functions.invoke(
      deleteAccountFunctionName,
      body: {'confirm': true},
    );
  }

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
