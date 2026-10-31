import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/datasources/backend_auth_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_validators.dart';
import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

class BackendAuthRepository implements AuthRepository {
  static const _tag = 'AUTH_REPO';

  const BackendAuthRepository({
    required this.datasource,
    this.resolver = const AuthRouteStateResolver(),
  });

  final BackendAuthRemoteDatasource datasource;
  final AuthRouteStateResolver resolver;

  @override
  Stream<String?> watchAuthChanges() => datasource.watchAuthChanges();

  @override
  Future<AuthRouteState> resolveAuthRouteState() async {
    final session = await datasource.currentSessionSnapshot();
    if (session == null) return const AuthRouteState.unauthenticated();
    if (session.mustChangePassword) {
      return resolver.resolve(session: session, profile: null);
    }

    try {
      final profile = await datasource.getCurrentProfile();
      if (profile?.isAccessBlocked == true) {
        await _signOutSilently();
        return const AuthRouteState.failure(
          'Tài khoản bị khóa. Vui lòng liên hệ quản trị viên nếu bạn cần hỗ trợ.',
        );
      }
      return resolver.resolve(session: session, profile: profile);
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Resolve backend auth route failed',
        error,
        stackTrace,
      );
      return resolver.resolve(
        session: session,
        profile: null,
        profileLoadFailed: true,
      );
    }
  }

  @override
  Future<RegistrationResult> signUpWithPhone(RegisterCommand command) async {
    _validateRegister(command);
    try {
      await datasource.signUp(command);
      return RegistrationResult.sessionReady;
    } on BackendApiException catch (error) {
      throw _mapBackendException(
        error,
        hasReferral: command.referralCode?.trim().isNotEmpty == true,
      );
    } catch (_) {
      throw _genericFailure();
    }
  }

  @override
  Future<void> signInWithPhone(LoginCommand command) async {
    _validateLogin(command);
    try {
      await datasource.signIn(command);
      if (datasource.client.session?.mustChangePassword == true) return;
      final profile = await datasource.getCurrentProfile();
      if (profile?.isAccessBlocked == true) {
        await _signOutSilently();
        throw const AuthFailure(
          code: AuthFailureCode.accountDisabled,
          userMessage:
              'Tài khoản bị khóa. Vui lòng liên hệ quản trị viên nếu bạn cần hỗ trợ.',
        );
      }
    } on AuthFailure {
      rethrow;
    } on BackendApiException catch (error) {
      throw _mapBackendException(error);
    } catch (_) {
      throw _genericFailure();
    }
  }

  @override
  Future<void> updatePassword(UpdatePasswordCommand command) async {
    final passwordError = AuthValidators.confirmPassword(
      command.newPassword,
      command.confirmPassword,
    );
    if (passwordError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: passwordError,
      );
    }
    try {
      await datasource.updatePassword(command);
    } on BackendApiException catch (error) {
      throw _mapBackendException(error);
    } catch (_) {
      throw _genericFailure();
    }
  }

  @override
  Future<AuthCallbackResult> recoverSessionFromUri(Uri uri) async {
    if (uri.scheme.toLowerCase() != 'nanobio' ||
        uri.host.toLowerCase() != 'auth' ||
        uri.path != '/callback') {
      throw const AuthFailure(
        code: AuthFailureCode.deepLinkInvalid,
        userMessage:
            'Liên kết xác thực không hợp lệ. Bạn hãy mở lại liên kết mới nhất.',
      );
    }
    try {
      return await datasource.recoverSessionFromUri(uri);
    } on BackendApiException catch (error) {
      throw AuthFailure(
        code: AuthFailureCode.configuration,
        userMessage: error.message,
      );
    } catch (_) {
      throw _genericFailure(
        'Nabi chưa thể hoàn tất xác thực lúc này. Bạn có thể mở lại liên kết mới nhất rồi thử lại.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await datasource.signOut();
    } finally {
      await AppPrefs.setOnboardingCompleted(false);
    }
  }

  @override
  Future<void> requestAccountDeletion() async {
    var deletionAccepted = false;
    final userId = datasource.client.session?.userId;
    try {
      await datasource.requestAccountDeletion();
      deletionAccepted = true;
      if (userId != null && userId.trim().isNotEmpty) {
        try {
          await NotificationBootstrap.clearGeneratedReminders(
            subjectUserId: userId,
          );
        } catch (error, stackTrace) {
          AppLogger.error(
            'AUTH_REPOSITORY',
            'Failed to clear account notification schedules',
            error,
            stackTrace,
          );
        }
      }
      await DatabaseService.deleteDatabaseFile();
      await AppPrefs.clearAll();
      try {
        await const FlutterSecureStorage().deleteAll();
      } catch (error, stackTrace) {
        AppLogger.error(
          'AUTH_REPOSITORY',
          'Failed to clear secure account state',
          error,
          stackTrace,
        );
      }
    } on BackendApiException catch (error) {
      throw _mapBackendException(error);
    } catch (_) {
      throw _genericFailure(
        'Nabi chưa thể gửi yêu cầu xóa tài khoản lúc này. Mình thử lại sau một chút nhé.',
      );
    } finally {
      if (deletionAccepted) {
        try {
          await datasource.signOut();
        } catch (error, stackTrace) {
          AppLogger.error(
            'AUTH_REPOSITORY',
            'Sign-out after account deletion failed',
            error,
            stackTrace,
          );
        }
      }
    }
  }

  void _validateLogin(LoginCommand command) {
    final phoneError = AuthValidators.phone(command.phone);
    if (phoneError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: phoneError,
      );
    }
    final passwordError = AuthValidators.password(command.password);
    if (passwordError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: passwordError,
      );
    }
  }

  void _validateRegister(RegisterCommand command) {
    _validateLogin(
      LoginCommand(phone: command.phone, password: command.password),
    );
    final confirmError = AuthValidators.confirmPassword(
      command.password,
      command.confirmPassword,
    );
    if (confirmError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: confirmError,
      );
    }
    final nameError = AuthValidators.fullName(command.fullName ?? '');
    if (nameError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: nameError,
      );
    }
    final termsError = AuthValidators.acceptedTerms(command.acceptedTerms);
    if (termsError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: termsError,
      );
    }
  }

  AuthFailure _mapBackendException(
    BackendApiException error, {
    bool hasReferral = false,
  }) {
    final code = error.businessCode.toUpperCase();
    if (code.contains('REFERRAL') ||
        (hasReferral && error.statusCode >= 400 && error.statusCode < 500)) {
      return const AuthFailure(
        code: AuthFailureCode.invalidReferralCode,
        userMessage:
            'Mã giới thiệu không hợp lệ hoặc không thể dùng cho tài khoản này. Bạn hãy sửa hoặc xóa mã rồi đăng ký lại.',
      );
    }
    if (code == 'PHONE_EXISTS') {
      return const AuthFailure(
        code: AuthFailureCode.phoneAlreadyRegistered,
        userMessage:
            'Số điện thoại này đã có tài khoản. Bạn hãy đăng nhập hoặc liên hệ quản trị viên để đặt lại mật khẩu.',
      );
    }
    if (code == 'RATE_LIMITED') {
      return const AuthFailure(
        code: AuthFailureCode.rateLimited,
        userMessage:
            'Bạn đã thử quá nhiều lần. Vui lòng chờ một lúc rồi thử lại.',
      );
    }
    if (code == 'INVALID_CREDENTIALS' || error.statusCode == 401) {
      return const AuthFailure(
        code: AuthFailureCode.invalidCredentials,
        userMessage:
            'Số điện thoại hoặc mật khẩu không đúng. Bạn hãy kiểm tra lại rồi thử lại.',
      );
    }
    if (code == 'WEAK_PASSWORD') {
      return const AuthFailure(
        code: AuthFailureCode.weakPassword,
        userMessage: 'Mật khẩu chưa đủ an toàn. Bạn hãy chọn mật khẩu khác.',
      );
    }
    if (code == 'NETWORK_UNAVAILABLE' || error.statusCode == 0) {
      return const AuthFailure(
        code: AuthFailureCode.network,
        userMessage:
            'Chưa kết nối được máy chủ. Bạn kiểm tra mạng rồi thử lại nhé.',
      );
    }
    if (code == 'ACCESS_DENIED' || code == 'ACCOUNT_DISABLED') {
      return const AuthFailure(
        code: AuthFailureCode.accountDisabled,
        userMessage:
            'Tài khoản bị khóa. Vui lòng liên hệ quản trị viên nếu bạn cần hỗ trợ.',
      );
    }
    return AuthFailure(
      code: AuthFailureCode.authServer,
      userMessage:
          'Dịch vụ đăng nhập chưa sẵn sàng. Bạn hãy thử lại sau một chút.',
    );
  }

  Future<void> _signOutSilently() async {
    try {
      await datasource.signOut();
    } catch (error, stackTrace) {
      AppLogger.warning(_tag, 'Blocked-account sign-out deferred: $error');
      AppLogger.error(
        _tag,
        'Blocked-account sign-out failed',
        error,
        stackTrace,
      );
    }
  }

  AuthFailure _genericFailure([
    String message =
        'Nabi chưa thể xử lý yêu cầu lúc này. Mình thử lại sau một chút nhé.',
  ]) => AuthFailure(code: AuthFailureCode.unknown, userMessage: message);
}
