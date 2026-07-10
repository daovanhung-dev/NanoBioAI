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
