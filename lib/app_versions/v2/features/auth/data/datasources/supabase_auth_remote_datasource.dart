import 'package:nano_app/app_versions/v2/features/auth/data/services/device_fingerprint_provider.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/vietnam_phone_number.dart';
import 'package:nano_app/core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRemoteDatasource {
  final SupabaseClient client;
  final String deleteAccountFunctionName;
  final DeviceFingerprintProvider deviceFingerprintProvider;

  SupabaseAuthRemoteDatasource({
    required this.client,
    String? deleteAccountFunctionName,
    this.deviceFingerprintProvider = const DeviceFingerprintProvider(),
  }) : deleteAccountFunctionName =
           deleteAccountFunctionName ??
           _env('AUTH_DELETE_ACCOUNT_FUNCTION') ??
           'delete-account';

  Stream<String?> watchAuthChanges() {
    return client.auth.onAuthStateChange.map(
      (authState) => authState.session?.user.id,
    );
  }

  AuthSessionSnapshot? cachedSessionSnapshot() {
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;
    if (session == null || user == null || session.isExpired) return null;

    return AuthSessionSnapshot(
      userId: user.id,
      email: user.email,
      mustChangePassword: user.appMetadata['must_change_password'] == true,
    );
  }

  Future<AuthSessionSnapshot?> currentSessionSnapshot() async {
    final cached = cachedSessionSnapshot();
    if (cached == null) return null;
    final response = await client.auth.getUser();
    final user = response.user;
    if (user == null) return null;
    return AuthSessionSnapshot(
      userId: user.id,
      email: user.email,
      mustChangePassword: user.appMetadata['must_change_password'] == true,
    );
  }

  Future<AuthProfile?> getCurrentProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await client
        .from('users')
        .select('id,onboarding_status,subscription_tier,admin_status')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return AuthProfile.fromMap(Map<String, Object?>.from(row));
  }

  Future<AuthResponse> signUp(RegisterCommand command) async {
    final fullName = command.fullName?.trim();
    final phone = VietnamPhoneNumber.normalize(command.phone);
    if (phone == null) throw AuthException('invalid phone number');
    final referralCode = command.referralCode?.trim().toUpperCase();
    final deviceFingerprint = await deviceFingerprintProvider.getOrCreate();

    try {
      await client.functions.invoke(
        'member-phone-signup',
        body: {
          'phone': phone,
          'password': command.password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
          'device_fingerprint': deviceFingerprint,
        },
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['code']?.toString() : null;
      if (error.status == 409 || code == 'phone_exists') {
        throw AuthException('phone_exists');
      }
      if (error.status == 429 || code == 'rate_limited') {
        throw AuthException('rate limit');
      }
      throw AuthException('member signup unavailable');
    }

    return client.auth.signInWithPassword(
      email: VietnamPhoneNumber.authEmail(phone),
      password: command.password,
    );
  }

  Future<void> signIn(LoginCommand command) async {
    final phone = VietnamPhoneNumber.normalize(command.phone);
    if (phone == null) throw AuthException('invalid phone number');
    await client.auth.signInWithPassword(
      email: VietnamPhoneNumber.authEmail(phone),
      password: command.password,
    );
  }

  Future<void> updatePassword(UpdatePasswordCommand command) async {
    await client.functions.invoke(
      'member-change-password',
      body: {'new_password': command.newPassword},
    );
    await client.auth.refreshSession();
  }

  Future<AuthCallbackResult> recoverSessionFromUri(Uri uri) async {
    final callbackType = authCallbackTypeFromUri(uri);
    await client.auth.getSessionFromUrl(uri);
    return switch (callbackType) {
      AuthCallbackType.passwordRecovery =>
        const AuthCallbackResult.passwordRecovery(),
      AuthCallbackType.emailConfirmation => const AuthCallbackResult.unknown(),
      AuthCallbackType.unknown => const AuthCallbackResult.unknown(),
    };
  }

  Future<void> touchLastLogin() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client
        .from('users')
        .update({'last_login_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<void> requestAccountDeletion() async {
    await client.functions.invoke(
      deleteAccountFunctionName,
      body: {'confirm': true},
    );
  }

  static String? _env(String key) => AppEnv.maybeString(key);
}
