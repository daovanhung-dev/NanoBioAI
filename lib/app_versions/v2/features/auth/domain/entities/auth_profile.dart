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
  final String subscriptionTier;
  final String adminStatus;

  const AuthProfile({
    required this.id,
    required this.onboardingStatus,
    this.subscriptionTier = 'free',
    this.adminStatus = 'active',
  });

  factory AuthProfile.fromMap(Map<String, Object?> map) {
    return AuthProfile(
      id: map['id']?.toString() ?? '',
      onboardingStatus:
          map['onboarding_status']?.toString().trim().toLowerCase() ??
          'not_started',
      subscriptionTier: _normalizeSubscriptionTier(map['subscription_tier']),
      adminStatus: _normalizeAdminStatus(map['admin_status']),
    );
  }

  bool get isAccessBlocked => adminStatus == 'suspended' || adminStatus == 'closed';

  static String _normalizeSubscriptionTier(Object? value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text.isEmpty ? 'free' : text;
  }

  static String _normalizeAdminStatus(Object? value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    return switch (text) {
      'suspended' => 'suspended',
      'closed' => 'closed',
      _ => 'active',
    };
  }
}
