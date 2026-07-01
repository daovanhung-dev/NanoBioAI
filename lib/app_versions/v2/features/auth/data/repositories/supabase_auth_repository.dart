import 'package:nano_app/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_validators.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
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
      throw _mapAuthException(error);
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
  Future<void> recoverSessionFromUri(Uri uri) async {
    try {
      await datasource.recoverSessionFromUri(uri);
    } on AuthException catch (_) {
      throw const AuthFailure(
        code: AuthFailureCode.deepLinkInvalid,
        userMessage:
            'Liên kết này chưa mở được. Bạn thử mở lại từ email giúp Nabinhé.',
      );
    } catch (_) {
      throw _genericFailure();
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

  AuthFailure _mapAuthException(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('rate') || error.statusCode == '429') {
      return const AuthFailure(
        code: AuthFailureCode.rateLimited,
        userMessage:
            'Nabicần chờ một chút trước khi thử lại. Bạn quay lại sau ít phút nhé.',
      );
    }

    if (message.contains('already') || message.contains('registered')) {
      return const AuthFailure(
        code: AuthFailureCode.emailAlreadyRegistered,
        userMessage:
            'Email này có thể đã được dùng. Bạn thử đăng nhập hoặc đặt lại mật khẩu nhé.',
      );
    }

    if (message.contains('invalid') || message.contains('credentials')) {
      return const AuthFailure(
        code: AuthFailureCode.invalidCredentials,
        userMessage:
            'Email hoặc mật khẩu chưa đúng. Bạn kiểm tra lại giúp Nabinhé.',
      );
    }

    if (message.contains('network') || message.contains('timeout')) {
      return const AuthFailure(
        code: AuthFailureCode.network,
        userMessage:
            'Nabi chưa kết nối được lúc này. Bạn thử lại sau một chút nhé.',
      );
    }

    return _genericFailure();
  }

  AuthFailure _genericFailure([
    String message =
        'Nabi chưa thể xử lý yêu cầu lúc này. Mình thử lại sau một chút nhé.',
  ]) {
    return AuthFailure(code: AuthFailureCode.unknown, userMessage: message);
  }
}
