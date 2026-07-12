import 'package:nano_app/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_validators.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/services/supabase/auth/supabase_auth_error_translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  static const _tag = 'AUTH_REPO';

  final SupabaseAuthRemoteDatasource datasource;
  final bool requiresEmailConfirmation;
  final AuthRouteStateResolver resolver;

  SupabaseAuthRepository({
    required this.datasource,
    required this.requiresEmailConfirmation,
    this.resolver = const AuthRouteStateResolver(),
  });

  @override
  Stream<void> watchAuthChanges() => datasource.watchAuthChanges();

  @override
  Future<AuthRouteState> resolveAuthRouteState() async {
    try {
      final session = datasource.currentSessionSnapshot();
      if (session == null) {
        return const AuthRouteState.unauthenticated();
      }

      final profile = await datasource.getCurrentProfile();
      return resolver.resolve(
        session: session,
        profile: profile,
        requiresEmailConfirmation: requiresEmailConfirmation,
      );
    } catch (error, stackTrace) {
      AppLogger.error(_tag, 'Resolve auth route failed', error, stackTrace);
      final session = datasource.currentSessionSnapshot();
      return resolver.resolve(
        session: session,
        profile: null,
        requiresEmailConfirmation: requiresEmailConfirmation,
        profileLoadFailed: session != null,
      );
    }
  }

  @override
  Future<RegistrationResult> signUpWithEmail(RegisterCommand command) async {
    _validateRegister(command);

    try {
      final response = await datasource.signUp(command);
      if (response.session != null) {
        return RegistrationResult.sessionReady;
      }
      return RegistrationResult.verificationRequired;
    } on AuthException catch (error) {
      throw _mapSignUpException(error, command);
    } catch (_) {
      throw _genericFailure();
    }
  }

  @override
  Future<void> signInWithEmail(LoginCommand command) async {
    _validateLogin(command);

    try {
      await datasource.signIn(command);
      try {
        await datasource.touchLastLogin();
      } catch (error, stackTrace) {
        AppLogger.warning(_tag, 'last_login_at update skipped: $error');
        AppLogger.error(_tag, 'last_login_at update failed', error, stackTrace);
      }
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw _genericFailure();
    }
  }

  @override
  Future<void> resendEmailConfirmation(String email) async {
    final error = AuthValidators.email(email);
    if (error != null) {
      throw AuthFailure(code: AuthFailureCode.validation, userMessage: error);
    }

    try {
      await datasource.resendEmailConfirmation(email);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw _genericFailure();
    }
  }

  @override
  Future<void> sendPasswordRecovery(String email) async {
    final error = AuthValidators.email(email);
    if (error != null) {
      throw AuthFailure(code: AuthFailureCode.validation, userMessage: error);
    }

    try {
      await datasource.sendPasswordRecovery(email);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
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
    } on AuthException catch (error) {
      throw _mapAuthException(error);
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
        userMessage: 'Liên kết xác thực không hợp lệ. Bạn hãy mở lại liên kết mới nhất trong email.',
      );
    }

    try {
      return await datasource.recoverSessionFromUri(uri);
    } on AuthException catch (_) {
      throw const AuthFailure(
        code: AuthFailureCode.deepLinkInvalid,
        userMessage: 'Liên kết đã hết hạn hoặc không còn hợp lệ. Bạn hãy yêu cầu một liên kết mới rồi thử lại.',
      );
    } catch (_) {
      throw _genericFailure(
        'Nabi chưa thể hoàn tất xác thực lúc này. Bạn có thể thử lại bằng liên kết trong email.',
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
    try {
      await datasource.requestAccountDeletion();
      await AppPrefs.setOnboardingCompleted(false);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw _genericFailure(
        'Nabi chưa thể gửi yêu cầu xóa tài khoản lúc này. Mình thử lại sau một chút nhé.',
      );
    }
  }

  void _validateLogin(LoginCommand command) {
    final emailError = AuthValidators.email(command.email);
    if (emailError != null) {
      throw AuthFailure(
        code: AuthFailureCode.validation,
        userMessage: emailError,
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
      LoginCommand(email: command.email, password: command.password),
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

  AuthFailure _mapSignUpException(
    AuthException error,
    RegisterCommand command,
  ) {
    final mapped = _mapAuthException(error);
    if (mapped.code == AuthFailureCode.invalidReferralCode) return mapped;

    final hasReferral = command.referralCode?.trim().isNotEmpty ?? false;
    final normalized = error.message.toLowerCase();
    final couldBeAtomicReferralRejection =
        normalized.contains('database error saving new user') ||
        normalized.contains('unexpected_failure');
    if (hasReferral && couldBeAtomicReferralRejection) {
      return _invalidReferralFailure();
    }
    return mapped;
  }

  AuthFailure _mapAuthException(AuthException error) {
    final normalized = error.message.toLowerCase();
    if (normalized.contains('invalid_referral_code') ||
        normalized.contains('referral_not_active') ||
        normalized.contains('referral_collision') ||
        normalized.contains('referral_already_used') ||
        normalized.contains('referral_device_missing')) {
      return _invalidReferralFailure();
    }

    final details = SupabaseAuthErrorTranslator.fromAuthException(error);
    return AuthFailure(
      code: _failureCodeFor(details.kind),
      userMessage: _safeUserMessageFor(details.kind),
    );
  }

  AuthFailure _invalidReferralFailure() {
    return const AuthFailure(
      code: AuthFailureCode.invalidReferralCode,
      userMessage:
          'Mã giới thiệu không hợp lệ hoặc không thể dùng cho tài khoản này. '
          'Bạn hãy sửa hoặc xóa mã rồi đăng ký lại.',
    );
  }

  String _safeUserMessageFor(SupabaseAuthErrorKind kind) {
    return switch (kind) {
      SupabaseAuthErrorKind.invalidCredentials =>
        'Email hoặc mật khẩu không đúng. Bạn hãy kiểm tra lại rồi thử lại.',
      SupabaseAuthErrorKind.emailUnverified =>
        'Tài khoản cần xác thực email trước khi đăng nhập.',
      SupabaseAuthErrorKind.emailAlreadyRegistered =>
        'Email này đã có tài khoản. Bạn hãy đăng nhập hoặc đặt lại mật khẩu.',
      SupabaseAuthErrorKind.weakPassword =>
        'Mật khẩu chưa đủ an toàn. Bạn hãy chọn mật khẩu khác.',
      SupabaseAuthErrorKind.rateLimited =>
        'Bạn đã thử quá nhiều lần. Vui lòng chờ một lúc rồi thử lại.',
      SupabaseAuthErrorKind.accountDisabled =>
        'Tài khoản đang tạm khóa hoặc chưa được phép đăng nhập.',
      SupabaseAuthErrorKind.network =>
        'Chưa kết nối được dịch vụ đăng nhập. Bạn hãy kiểm tra mạng rồi thử lại.',
      SupabaseAuthErrorKind.configuration ||
      SupabaseAuthErrorKind.authServer ||
      SupabaseAuthErrorKind.unknown =>
        'Dịch vụ đăng nhập chưa sẵn sàng. Bạn hãy thử lại sau một chút.',
    };
  }

  AuthFailureCode _failureCodeFor(SupabaseAuthErrorKind kind) {
    return switch (kind) {
      SupabaseAuthErrorKind.invalidCredentials =>
        AuthFailureCode.invalidCredentials,
      SupabaseAuthErrorKind.emailUnverified => AuthFailureCode.emailUnverified,
      SupabaseAuthErrorKind.emailAlreadyRegistered =>
        AuthFailureCode.emailAlreadyRegistered,
      SupabaseAuthErrorKind.weakPassword => AuthFailureCode.weakPassword,
      SupabaseAuthErrorKind.rateLimited => AuthFailureCode.rateLimited,
      SupabaseAuthErrorKind.accountDisabled => AuthFailureCode.accountDisabled,
      SupabaseAuthErrorKind.network => AuthFailureCode.network,
      SupabaseAuthErrorKind.configuration => AuthFailureCode.configuration,
      SupabaseAuthErrorKind.authServer => AuthFailureCode.authServer,
      SupabaseAuthErrorKind.unknown => AuthFailureCode.unknown,
    };
  }

  AuthFailure _genericFailure([
    String message =
        'Nabi chưa thể xử lý yêu cầu lúc này. Mình thử lại sau một chút nhé.',
  ]) {
    return AuthFailure(code: AuthFailureCode.unknown, userMessage: message);
  }
}
