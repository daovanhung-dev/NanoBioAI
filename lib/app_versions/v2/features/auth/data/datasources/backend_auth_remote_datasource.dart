import 'package:nano_app/app_versions/v2/features/auth/data/services/device_fingerprint_provider.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/vietnam_phone_number.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

class BackendAuthRemoteDatasource {
  const BackendAuthRemoteDatasource({
    required this.client,
    this.deviceFingerprintProvider = const DeviceFingerprintProvider(),
  });

  final BackendApiClient client;
  final DeviceFingerprintProvider deviceFingerprintProvider;

  Stream<String?> watchAuthChanges() => client.authChanges;

  AuthSessionSnapshot? cachedSessionSnapshot() {
    final session = client.session;
    if (session == null || session.expiresAt.isBefore(DateTime.now().toUtc())) {
      return null;
    }
    return AuthSessionSnapshot(
      userId: session.userId,
      email: session.email,
      mustChangePassword: session.mustChangePassword,
    );
  }

  Future<AuthSessionSnapshot?> currentSessionSnapshot() async {
    final session = await client.restoreSession();
    if (session == null) return null;
    return AuthSessionSnapshot(
      userId: session.userId,
      email: session.email,
      mustChangePassword: session.mustChangePassword,
    );
  }

  Future<AuthProfile?> getCurrentProfile() async {
    if (client.session == null) return null;
    final response = await client.requestMap('GET', '/api/v1/profile/me');
    return AuthProfile.fromMap(response);
  }

  Future<void> signUp(RegisterCommand command) async {
    final phone = VietnamPhoneNumber.normalize(command.phone);
    if (phone == null) {
      throw const BackendApiException(
        statusCode: 422,
        businessCode: 'INVALID_PHONE',
        message: 'Số điện thoại chưa đúng.',
      );
    }
    final fingerprint = await deviceFingerprintProvider.getOrCreate();
    final response = await client.requestMap(
      'POST',
      '/api/v1/auth/phone-signup',
      authenticated: false,
      body: {
        'phone': phone,
        'password': command.password,
        'full_name': command.fullName?.trim(),
        if (command.referralCode?.trim().isNotEmpty == true)
          'referral_code': command.referralCode!.trim().toUpperCase(),
        'device_fingerprint': fingerprint,
      },
    );
    await client.establishSession(response);
  }

  Future<void> signIn(LoginCommand command) async {
    final phone = VietnamPhoneNumber.normalize(command.phone);
    if (phone == null) {
      throw const BackendApiException(
        statusCode: 422,
        businessCode: 'INVALID_PHONE',
        message: 'Số điện thoại chưa đúng.',
      );
    }
    final response = await client.requestMap(
      'POST',
      '/api/v1/auth/login',
      authenticated: false,
      body: {'phone': phone, 'password': command.password},
    );
    await client.establishSession(response);
  }

  Future<void> updatePassword(UpdatePasswordCommand command) async {
    await client.changePassword(command.newPassword);
  }

  Future<AuthCallbackResult> recoverSessionFromUri(Uri uri) async {
    final callbackType = authCallbackTypeFromUri(uri);
    if (callbackType != AuthCallbackType.passwordRecovery) {
      return const AuthCallbackResult.unknown();
    }
    throw const BackendApiException(
      statusCode: 501,
      businessCode: 'PASSWORD_RECOVERY_UNAVAILABLE',
      message: 'Khôi phục mật khẩu chưa được bật trên máy chủ.',
    );
  }

  Future<void> signOut() => client.signOut();

  Future<void> requestAccountDeletion() async {
    await client.requestMap(
      'DELETE',
      '/api/v1/account',
      body: {'confirm': true},
    );
  }
}
