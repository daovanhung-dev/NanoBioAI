enum SafetyContactVerificationStatus { pending, verified, failed, revoked }

class SafetyContact {
  const SafetyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.phoneE164,
    required this.priority,
    required this.verificationStatus,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedAt,
    this.allowPhoneFallback = true,
    this.allowUnverifiedVoiceAlert = false,
  });
  final String id;
  final String userId;
  final String name;
  final String relationship;
  final String phoneE164;
  final int priority;
  final SafetyContactVerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool allowPhoneFallback;
  final bool allowUnverifiedVoiceAlert;
  bool get isVerified =>
      active && verificationStatus == SafetyContactVerificationStatus.verified;
  bool get canReceiveSafetyCall =>
      isVerified || (active && allowUnverifiedVoiceAlert);
}
