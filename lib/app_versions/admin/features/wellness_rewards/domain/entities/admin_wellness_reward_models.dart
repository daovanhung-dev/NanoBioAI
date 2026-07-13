class AdminWellnessRewardOffer {
  final String id;
  final String title;
  final String description;
  final String providerName;
  final int costPoints;
  final int availableCodes;
  final int issuedCodes;
  final List<String> eligiblePlanCodes;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? voucherExpiresAt;
  final bool isActive;

  const AdminWellnessRewardOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.providerName,
    required this.costPoints,
    required this.availableCodes,
    required this.issuedCodes,
    required this.eligiblePlanCodes,
    required this.isActive,
    this.availableFrom,
    this.availableUntil,
    this.voucherExpiresAt,
  });

  factory AdminWellnessRewardOffer.fromMap(Map<String, Object?> map) {
    return AdminWellnessRewardOffer(
      id: _string(map['id'] ?? map['offer_id']),
      title: _string(map['title'], fallback: 'Ưu đãi chưa đặt tên'),
      description: _string(map['description']),
      providerName: _string(map['provider_name'], fallback: 'NanoBio'),
      costPoints: _integer(map['cost_points']),
      availableCodes: _integer(map['available_codes'] ?? map['stock_count']),
      issuedCodes: _integer(map['issued_codes']),
      eligiblePlanCodes: _stringList(map['eligible_plan_codes']),
      availableFrom: _date(map['available_from']),
      availableUntil: _date(map['available_until']),
      voucherExpiresAt: _date(map['voucher_expires_at']),
      isActive: _boolean(map['is_active'], fallback: true),
    );
  }
}

class AdminWellnessRewardRedemption {
  final String id;
  final String title;
  final String providerName;
  final String userLabel;
  final int pointsSpent;
  final String status;
  final String maskedCode;
  final DateTime? createdAt;
  final DateTime? cancelledAt;

  const AdminWellnessRewardRedemption({
    required this.id,
    required this.title,
    required this.providerName,
    required this.userLabel,
    required this.pointsSpent,
    required this.status,
    required this.maskedCode,
    this.createdAt,
    this.cancelledAt,
  });

  bool get canCancel => status.trim().toLowerCase() == 'issued';

  factory AdminWellnessRewardRedemption.fromMap(Map<String, Object?> map) {
    return AdminWellnessRewardRedemption(
      id: _string(map['id'] ?? map['redemption_id']),
      title: _string(map['title'], fallback: 'Voucher NanoBio'),
      providerName: _string(map['provider_name'], fallback: 'NanoBio'),
      userLabel: _string(
        map['user_label'] ?? map['user_email_masked'],
        fallback: 'Tài khoản NanoBio',
      ),
      pointsSpent: _integer(map['points_spent'] ?? map['cost_points']),
      status: _string(map['status'], fallback: 'issued'),
      maskedCode: _string(map['masked_code'], fallback: '••••••'),
      createdAt: _date(map['created_at']),
      cancelledAt: _date(map['cancelled_at']),
    );
  }
}

class AdminWellnessRewardsSnapshot {
  final List<AdminWellnessRewardOffer> offers;
  final List<AdminWellnessRewardRedemption> redemptions;

  const AdminWellnessRewardsSnapshot({
    required this.offers,
    required this.redemptions,
  });
}

class AdminRewardMutationResult {
  final bool success;
  final String message;
  final int acceptedCount;
  final int duplicateCount;
  final int rejectedCount;

  const AdminRewardMutationResult({
    required this.success,
    required this.message,
    this.acceptedCount = 0,
    this.duplicateCount = 0,
    this.rejectedCount = 0,
  });

  factory AdminRewardMutationResult.fromMap(Map<String, Object?> map) {
    return AdminRewardMutationResult(
      success: _boolean(map['success'], fallback: false),
      message: _string(map['message'], fallback: 'Đã cập nhật dữ liệu ưu đãi.'),
      acceptedCount: _integer(map['accepted_count']),
      duplicateCount: _integer(map['duplicate_count']),
      rejectedCount: _integer(map['rejected_count']),
    );
  }
}

class AdminRewardOfferCommand {
  final String? offerId;
  final String title;
  final String description;
  final String providerName;
  final int costPoints;
  final List<String> eligiblePlanCodes;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? voucherExpiresAt;
  final bool isActive;
  final String reason;
  final String idempotencyKey;

  const AdminRewardOfferCommand({
    required this.title,
    required this.description,
    required this.providerName,
    required this.costPoints,
    required this.eligiblePlanCodes,
    required this.isActive,
    required this.reason,
    this.idempotencyKey = '',
    this.offerId,
    this.availableFrom,
    this.availableUntil,
    this.voucherExpiresAt,
  });

  AdminRewardOfferCommand withIdempotencyKey(String value) {
    return AdminRewardOfferCommand(
      offerId: offerId,
      title: title,
      description: description,
      providerName: providerName,
      costPoints: costPoints,
      eligiblePlanCodes: eligiblePlanCodes,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      voucherExpiresAt: voucherExpiresAt,
      isActive: isActive,
      reason: reason,
      idempotencyKey: value,
    );
  }
}

class AdminRewardCodeImportCommand {
  final String offerId;
  final List<String> codes;
  final DateTime? voucherExpiresAt;
  final String reason;
  final String idempotencyKey;

  const AdminRewardCodeImportCommand({
    required this.offerId,
    required this.codes,
    required this.reason,
    this.idempotencyKey = '',
    this.voucherExpiresAt,
  });

  AdminRewardCodeImportCommand withIdempotencyKey(String value) {
    return AdminRewardCodeImportCommand(
      offerId: offerId,
      codes: codes,
      voucherExpiresAt: voucherExpiresAt,
      reason: reason,
      idempotencyKey: value,
    );
  }
}

class AdminWellnessRewardException implements Exception {
  final String safeMessage;

  const AdminWellnessRewardException(this.safeMessage);

  @override
  String toString() => 'admin_wellness_reward_error';
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _boolean(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : DateTime.tryParse(text);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}
