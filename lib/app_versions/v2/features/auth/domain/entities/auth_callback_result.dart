enum AuthCallbackType { emailConfirmation, passwordRecovery, unknown }

class AuthCallbackResult {
  final AuthCallbackType type;

  const AuthCallbackResult._(this.type);

  const AuthCallbackResult.emailConfirmation()
    : this._(AuthCallbackType.emailConfirmation);

  const AuthCallbackResult.passwordRecovery()
    : this._(AuthCallbackType.passwordRecovery);

  const AuthCallbackResult.unknown() : this._(AuthCallbackType.unknown);

  bool get isPasswordRecovery => type == AuthCallbackType.passwordRecovery;
  bool get isEmailConfirmation => type == AuthCallbackType.emailConfirmation;
}

AuthCallbackType authCallbackTypeFromUri(Uri uri) {
  final fragmentParameters = _safeSplitQuery(uri.fragment);
  final values = <String>[
    uri.queryParameters['type'] ?? '',
    fragmentParameters['type'] ?? '',
  ].map((value) => value.trim().toLowerCase());

  if (values.any((value) => value == 'recovery')) {
    return AuthCallbackType.passwordRecovery;
  }
  if (values.any(
    (value) =>
        value == 'signup' ||
        value == 'email' ||
        value == 'email_change' ||
        value == 'invite',
  )) {
    return AuthCallbackType.emailConfirmation;
  }
  return AuthCallbackType.unknown;
}

Map<String, String> _safeSplitQuery(String value) {
  if (value.trim().isEmpty) return const {};
  try {
    return Uri.splitQueryString(value);
  } on FormatException {
    return const {};
  }
}
