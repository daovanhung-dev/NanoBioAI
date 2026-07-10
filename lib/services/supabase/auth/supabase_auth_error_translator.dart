import 'package:supabase_flutter/supabase_flutter.dart';

enum SupabaseAuthErrorKind {
  invalidCredentials,
  emailUnverified,
  emailAlreadyRegistered,
  weakPassword,
  rateLimited,
  accountDisabled,
  network,
  configuration,
  authServer,
  unknown,
}

class SupabaseAuthErrorDetails {
  final SupabaseAuthErrorKind kind;
  final String title;
  final String message;

  const SupabaseAuthErrorDetails({
    required this.kind,
    required this.title,
    required this.message,
  });

  String get fullMessage => '$title: $message';
}

class SupabaseAuthErrorTranslator {
  const SupabaseAuthErrorTranslator._();

  static SupabaseAuthErrorDetails fromObject(Object error) {
    if (error is AuthException) {
      return fromAuthException(error);
    }

    final message = _normalize(error.toString());
    if (_looksLikeNetwork(message)) {
      return _network;
    }

    return _unknown;
  }

  static SupabaseAuthErrorDetails fromAuthException(AuthException error) {
    final message = _normalize(error.message);
    final statusCode = error.statusCode?.toString();

    if (statusCode == '429' ||
        message.contains('rate') ||
        message.contains('too many')) {
      return _rateLimited;
    }

    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed') ||
        message.contains('not confirmed')) {
      return _emailUnverified;
    }

    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already')) {
      return _emailAlreadyRegistered;
    }

    if (message.contains('weak password') ||
        message.contains('password should') ||
        message.contains('password must')) {
      return _weakPassword;
    }

    if (message.contains('banned') ||
        message.contains('disabled') ||
        message.contains('deactivated') ||
        message.contains('not allowed')) {
      return _accountDisabled;
    }

    if (_looksLikeNetwork(message)) {
      return _network;
    }

    if (message.contains('invalid api key') ||
        message.contains('api key') ||
        message.contains('jwt') ||
        message.contains('redirect') ||
        message.contains('configuration')) {
      return _configuration;
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('invalid_grant') ||
        message.contains('user not found') ||
        (statusCode == '400' && message.contains('invalid'))) {
      return _invalidCredentials;
    }

    if (_isServerStatus(statusCode) ||
        message.contains('database error') ||
        message.contains('querying schema') ||
        message.contains('unexpected_failure') ||
        message.contains('server error')) {
      return _authServer;
    }

    return _unknown;
  }

  static bool _looksLikeNetwork(String message) {
    return message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('socket') ||
        message.contains('failed host lookup');
  }

  static bool _isServerStatus(String? statusCode) {
    return statusCode == '500' ||
        statusCode == '502' ||
        statusCode == '503' ||
        statusCode == '504';
  }

  static String _normalize(String value) => value.toLowerCase().trim();
}

const _invalidCredentials = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.invalidCredentials,
  title: 'Sai thông tin đăng nhập',
  message: 'Email hoặc mật khẩu không đúng. Kiểm tra lại rồi thử lại.',
);

const _emailUnverified = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.emailUnverified,
  title: 'Email chưa xác thực',
  message: 'Tài khoản này cần xác thực email trước khi đăng nhập.',
);

const _emailAlreadyRegistered = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.emailAlreadyRegistered,
  title: 'Email đã tồn tại',
  message: 'Email này đã có tài khoản. Hãy đăng nhập hoặc đặt lại mật khẩu.',
);

const _weakPassword = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.weakPassword,
  title: 'Mật khẩu chưa đủ mạnh',
  message: 'Mật khẩu chưa đạt yêu cầu bảo mật của hệ thống.',
);

const _rateLimited = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.rateLimited,
  title: 'Thử quá nhiều lần',
  message: 'Hệ thống đang giới hạn tạm thời. Chờ vài phút rồi thử lại.',
);

const _accountDisabled = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.accountDisabled,
  title: 'Tài khoản bị khóa',
  message: 'Tài khoản này đang bị khóa hoặc chưa được phép đăng nhập.',
);

const _network = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.network,
  title: 'Lỗi kết nối',
  message:
      'Không kết nối được tới máy chủ đăng nhập. Kiểm tra mạng rồi thử lại.',
);

const _configuration = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.configuration,
  title: 'Cấu hình đăng nhập lỗi',
  message: 'Supabase URL, anon key hoặc redirect URL đang chưa đúng.',
);

const _authServer = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.authServer,
  title: 'Lỗi hệ thống đăng nhập',
  message:
      'Máy chủ Auth hoặc database đang trả lỗi. Đây không phải lỗi mật khẩu; hãy kiểm tra cấu hình và seed Auth.',
);

const _unknown = SupabaseAuthErrorDetails(
  kind: SupabaseAuthErrorKind.unknown,
  title: 'Chưa đăng nhập được',
  message: 'Hệ thống chưa xử lý được yêu cầu lúc này. Thử lại sau ít phút.',
);
