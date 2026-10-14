class RegisterCommand {
  final String phone;
  final String password;
  final String confirmPassword;
  final String? fullName;
  final bool acceptedTerms;
  final String? referralCode;

  const RegisterCommand({
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.acceptedTerms,
    this.fullName,
    this.referralCode,
  });
}

class LoginCommand {
  final String phone;
  final String password;

  const LoginCommand({required this.phone, required this.password});
}

class UpdatePasswordCommand {
  final String newPassword;
  final String confirmPassword;

  const UpdatePasswordCommand({
    required this.newPassword,
    required this.confirmPassword,
  });
}

enum RegistrationResult { sessionReady }
