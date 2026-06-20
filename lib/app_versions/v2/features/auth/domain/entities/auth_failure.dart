enum AuthFailureCode {
  validation,
  invalidCredentials,
  emailUnverified,
  profileMissing,
  sessionMissing,
  emailAlreadyRegistered,
  rateLimited,
  network,
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
