class WellnessRewardSummary {
  final int pendingPoints;
  final int availablePoints;
  final int expiringSoonPoints;
  final DateTime? nextExpiryAt;
  final DateTime? syncedAt;

  const WellnessRewardSummary({
    required this.pendingPoints,
    required this.availablePoints,
    required this.expiringSoonPoints,
    this.nextExpiryAt,
    this.syncedAt,
  });

  static const empty = WellnessRewardSummary(
    pendingPoints: 0,
    availablePoints: 0,
    expiringSoonPoints: 0,
  );

  factory WellnessRewardSummary.fromMap(Map<String, Object?> map) {
    return WellnessRewardSummary(
      pendingPoints: _readInt(map['pending_points']),
      availablePoints: _readInt(map['available_points']),
      expiringSoonPoints: _readInt(map['expiring_soon_points']),
      nextExpiryAt: _readDate(map['next_expiry_at']),
      syncedAt: _readDate(map['synced_at']) ?? DateTime.now(),
    );
  }
}

class WellnessRewardOffer {
  final String id;
  final String title;
  final String description;
  final String providerName;
  final int costPoints;
  final int availableCodes;
  final List<String> eligiblePlanCodes;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? voucherExpiresAt;
  final bool isActive;

  const WellnessRewardOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.providerName,
    required this.costPoints,
    required this.availableCodes,
    required this.eligiblePlanCodes,
    required this.isActive,
    this.availableFrom,
    this.availableUntil,
    this.voucherExpiresAt,
  });

  bool get isInStock => availableCodes > 0;

  factory WellnessRewardOffer.fromMap(Map<String, Object?> map) {
    return WellnessRewardOffer(
      id: _readString(map['id'] ?? map['offer_id']),
      title: _readString(map['title'], fallback: 'Ưu đãi NanoBio'),
      description: _readString(
        map['description'],
        fallback: 'Thông tin ưu đãi đang được cập nhật.',
      ),
      providerName: _readString(map['provider_name'], fallback: 'NanoBio'),
      costPoints: _readInt(map['cost_points']),
      availableCodes: _readInt(map['available_codes'] ?? map['stock_count']),
      eligiblePlanCodes: _readStringList(map['eligible_plan_codes']),
      availableFrom: _readDate(map['available_from']),
      availableUntil: _readDate(map['available_until']),
      voucherExpiresAt: _readDate(map['voucher_expires_at']),
      isActive: _readBool(map['is_active'], fallback: true),
    );
  }
}

class WellnessPointHistoryEntry {
  final String id;
  final int pointsDelta;
  final String eventType;
  final String status;
  final String title;
  final bool isRedeemable;
  final DateTime? availableAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const WellnessPointHistoryEntry({
    required this.id,
    required this.pointsDelta,
    required this.eventType,
    required this.status,
    required this.title,
    required this.isRedeemable,
    this.availableAt,
    this.expiresAt,
    this.createdAt,
  });

  factory WellnessPointHistoryEntry.fromMap(Map<String, Object?> map) {
    return WellnessPointHistoryEntry(
      id: _readString(map['id']),
      pointsDelta: _readInt(map['points_delta']),
      eventType: _readString(map['event_type'], fallback: 'award'),
      status: _readString(map['status'], fallback: 'available'),
      title: _readString(map['title'], fallback: 'Điểm chăm sóc'),
      isRedeemable: _readBool(map['is_redeemable'], fallback: true),
      availableAt: _readDate(map['available_at']),
      expiresAt: _readDate(map['expires_at']),
      createdAt: _readDate(map['created_at']),
    );
  }
}

class WellnessRewardRedemption {
  final String id;
  final String offerId;
  final String title;
  final String providerName;
  final int pointsSpent;
  final String status;
  final String? voucherCode;
  final DateTime? voucherExpiresAt;
  final DateTime? createdAt;
  final DateTime? cancelledAt;

  const WellnessRewardRedemption({
    required this.id,
    required this.offerId,
    required this.title,
    required this.providerName,
    required this.pointsSpent,
    required this.status,
    this.voucherCode,
    this.voucherExpiresAt,
    this.createdAt,
    this.cancelledAt,
  });

  bool get isCancelled => status.trim().toLowerCase() == 'cancelled';

  factory WellnessRewardRedemption.fromMap(Map<String, Object?> map) {
    final code = _readNullableString(
      map['voucher_code'] ?? map['code'] ?? map['assigned_code'],
    );
    return WellnessRewardRedemption(
      id: _readString(map['id'] ?? map['redemption_id']),
      offerId: _readString(map['offer_id']),
      title: _readString(map['title'], fallback: 'Voucher NanoBio'),
      providerName: _readString(map['provider_name'], fallback: 'NanoBio'),
      pointsSpent: _readInt(map['points_spent'] ?? map['cost_points']),
      status: _readString(map['status'], fallback: 'issued'),
      voucherCode: code,
      voucherExpiresAt: _readDate(map['voucher_expires_at']),
      createdAt: _readDate(map['created_at']),
      cancelledAt: _readDate(map['cancelled_at']),
    );
  }
}

class WellnessRewardsDashboard {
  final WellnessRewardSummary summary;
  final List<WellnessRewardOffer> offers;
  final List<WellnessPointHistoryEntry> pointHistory;
  final List<WellnessRewardRedemption> redemptions;

  const WellnessRewardsDashboard({
    required this.summary,
    required this.offers,
    required this.pointHistory,
    required this.redemptions,
  });
}

class WellnessRewardException implements Exception {
  final String code;
  final String safeMessage;

  const WellnessRewardException(this.code, this.safeMessage);

  factory WellnessRewardException.fromCode(Object? value) {
    final code = value?.toString().trim().toLowerCase() ?? '';
    return switch (code) {
      'auth_required' => const WellnessRewardException(
        'auth_required',
        'Bạn cần đăng nhập để xem và đổi Điểm chăm sóc.',
      ),
      'member_account_required' => const WellnessRewardException(
        'auth_required',
        'Bạn cần đăng nhập tài khoản thành viên để dùng Điểm chăm sóc.',
      ),
      'insufficient_points' => const WellnessRewardException(
        'insufficient_points',
        'Bạn chưa có đủ Điểm chăm sóc cho ưu đãi này.',
      ),
      'offer_out_of_stock' || 'out_of_stock' => const WellnessRewardException(
        'offer_out_of_stock',
        'Ưu đãi này vừa hết mã. Bạn vui lòng chọn ưu đãi khác.',
      ),
      'offer_ineligible' => const WellnessRewardException(
        'offer_ineligible',
        'Gói thành viên hiện tại chưa áp dụng ưu đãi này.',
      ),
      'offer_unavailable' ||
      'offer_expired' ||
      'offer_not_found' ||
      'offer_required' ||
      'offer_window_invalid' => const WellnessRewardException(
        'offer_unavailable',
        'Ưu đãi hiện không còn khả dụng.',
      ),
      'redemption_not_found' ||
      'redemption_required' => const WellnessRewardException(
        'redemption_unavailable',
        'Voucher này không còn khả dụng trên tài khoản.',
      ),
      'wellness_rewards_disabled' ||
      'reward_program_invalid' ||
      'reward_program_not_configured' => const WellnessRewardException(
        'program_unavailable',
        'Chương trình Điểm chăm sóc hiện chưa khả dụng.',
      ),
      'duplicate_request' ||
      'idempotency_conflict' => const WellnessRewardException(
        'duplicate_request',
        'Yêu cầu này đã được xử lý. Danh sách voucher sẽ được làm mới.',
      ),
      'secure_storage_unavailable' => const WellnessRewardException(
        'secure_storage_unavailable',
        'Nabi chưa thể bảo vệ yêu cầu đổi ưu đãi trên thiết bị. Bạn thử lại sau nhé.',
      ),
      _ => const WellnessRewardException(
        'unknown',
        'Nabi chưa xử lý được yêu cầu. Bạn vui lòng thử lại sau.',
      ),
    };
  }

  @override
  String toString() => code;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _readDate(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : DateTime.tryParse(text);
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}
