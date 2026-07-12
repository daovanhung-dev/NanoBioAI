class RegisterCommand {
  final String email;
  final String password;
  final String confirmPassword;
  final String? fullName;
  final String? phone;
  final bool acceptedTerms;
  final String? referralCode;

  const RegisterCommand({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.acceptedTerms,
    this.fullName,
    this.phone,
    this.referralCode,
  });
}

class LoginCommand {
  final String email;
  final String password;

  const LoginCommand({required this.email, required this.password});
}

class UpdatePasswordCommand {
  final String newPassword;
  final String confirmPassword;

  const UpdatePasswordCommand({
    required this.newPassword,
    required this.confirmPassword,
  });
}

enum RegistrationResult { verificationRequired, sessionReady }
