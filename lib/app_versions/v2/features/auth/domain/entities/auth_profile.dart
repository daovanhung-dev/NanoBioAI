class AuthSessionSnapshot {
  final String userId;
  final String? email;
  final bool emailConfirmed;

  const AuthSessionSnapshot({
    required this.userId,
    required this.email,
    required this.emailConfirmed,
  });
}

class AuthProfile {
  final String id;
  final String onboardingStatus;

  const AuthProfile({required this.id, required this.onboardingStatus});

  factory AuthProfile.fromMap(Map<String, Object?> map) {
    return AuthProfile(
      id: map['id']?.toString() ?? '',
      onboardingStatus:
          map['onboarding_status']?.toString().trim().toLowerCase() ??
          'not_started',
    );
  }
}
