class EffectiveAccess {
  final String userId;
  final bool isAnonymous;
  final String productAccess;
  final String membershipPlan;
  final String saleStatus;
  final String onboardingStatus;
  final DateTime? updatedAt;

  const EffectiveAccess({
    required this.userId,
    required this.isAnonymous,
    required this.productAccess,
    required this.membershipPlan,
    required this.saleStatus,
    required this.onboardingStatus,
    this.updatedAt,
  });

  factory EffectiveAccess.fromMap(Map<String, Object?> map) {
    return EffectiveAccess(
      userId: map['user_id']?.toString() ?? '',
      isAnonymous: _readBool(map['is_anonymous']),
      productAccess: _readText(map['product_access'], fallback: 'free'),
      membershipPlan: _readText(map['membership_plan'], fallback: 'free'),
      saleStatus: _readText(map['sale_status'], fallback: 'none'),
      onboardingStatus: _readText(
        map['onboarding_status'],
        fallback: 'not_started',
      ),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
    );
  }

  bool get isGuest => productAccess == 'guest';
  bool get isFree => membershipPlan == 'free';
  bool get isPlus => membershipPlan == 'plus';
  bool get isFamilyPlus => membershipPlan == 'family_plus';
  bool get hasPaidAccess => isPlus || isFamilyPlus;

  static String _readText(Object? value, {required String fallback}) {
    final text = value?.toString().trim().toLowerCase();
    return text == null || text.isEmpty ? fallback : text;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }
}
