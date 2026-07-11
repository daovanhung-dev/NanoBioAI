import 'package:nano_app/core/config/auth_backend_availability.dart';

enum AuthFailureCode {
  validation,
  invalidCredentials,
  emailUnverified,
  profileMissing,
  sessionMissing,
  emailAlreadyRegistered,
  weakPassword,
  rateLimited,
  accountDisabled,
  network,
  configuration,
  authServer,
  deepLinkInvalid,
  unknown,
}

class AuthFailure implements Exception {
  final AuthFailureCode code;
  final String userMessage;

  const AuthFailure({required this.code, required this.userMessage});

  @override
  String toString() => userMessage;
}

AuthFailure authBackendUnavailableFailure(
  AuthBackendAvailability availability,
) {
  final userMessage = switch (availability) {
    AuthBackendAvailability.missingConfiguration =>
      'Phiên bản ứng dụng này chưa sẵn sàng để đăng nhập. '
          'Bạn vẫn có thể tiếp tục cùng Nabi ở chế độ khách nhé.',
    AuthBackendAvailability.initializationFailed =>
      'Nabi chưa thể mở đăng nhập lúc này. '
          'Bạn vẫn có thể tiếp tục ở chế độ khách và thử lại sau nhé.',
    AuthBackendAvailability.ready =>
      'Nabi chưa thể xử lý yêu cầu đăng nhập lúc này. '
          'Mình thử lại sau một chút nhé.',
  };

  return AuthFailure(
    code: AuthFailureCode.configuration,
    userMessage: userMessage,
  );
}
