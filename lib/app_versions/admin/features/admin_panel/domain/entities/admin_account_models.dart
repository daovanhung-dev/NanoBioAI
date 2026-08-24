class AdminAccountSummary {
  final String id;
  final String displayName;
  final String email;
  final String? phone;
  final String accountStatus;
  final String planCode;
  final String saleStatus;
  final DateTime? createdAt;
  final String? subscriptionStatus;
  final DateTime? subscriptionStartsAt;
  final DateTime? subscriptionEndsAt;

  const AdminAccountSummary({
    required this.id,
    required this.displayName,
    required this.email,
    required this.accountStatus,
    required this.planCode,
    required this.saleStatus,
    this.phone,
    this.createdAt,
    this.subscriptionStatus,
    this.subscriptionStartsAt,
    this.subscriptionEndsAt,
  });

  factory AdminAccountSummary.fromMap(Map<String, Object?> map) {
    return AdminAccountSummary(
      id: _text(map['id']) ?? '',
      displayName: _text(map['display_name']) ?? _text(map['email']) ?? 'Tài khoản',
      email: _text(map['email']) ?? '',
      phone: _text(map['phone']),
      accountStatus: _text(map['account_status']) ?? 'active',
      planCode: _text(map['plan_code']) ?? 'free',
      saleStatus: _text(map['sale_status']) ?? 'none',
      createdAt: _date(map['created_at']),
      subscriptionStatus: _text(map['subscription_status']),
      subscriptionStartsAt: _date(map['subscription_starts_at']),
      subscriptionEndsAt: _date(map['subscription_ends_at']),
    );
  }
}

class AdminCreateAccountRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String reason;
  final String idempotencyKey;

  const AdminCreateAccountRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.reason,
    required this.idempotencyKey,
    this.phone,
  });
}

class AdminCreateAccountResult {
  final bool success;
  final String userId;
  final String email;
  final String message;

  const AdminCreateAccountResult({
    required this.success,
    required this.userId,
    required this.email,
    required this.message,
  });

  factory AdminCreateAccountResult.fromMap(Map<String, Object?> map) {
    return AdminCreateAccountResult(
      success: map['success'] == true,
      userId: _text(map['user_id']) ?? '',
      email: _text(map['email']) ?? '',
      message: _text(map['message']) ?? '',
    );
  }
}

class AdminMembershipGrantRequest {
  final String userId;
  final String planCode;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final String idempotencyKey;

  const AdminMembershipGrantRequest({
    required this.userId,
    required this.planCode,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.idempotencyKey,
  });
}

class AdminMembershipGrantResult {
  final bool success;
  final String message;
  final String planCode;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const AdminMembershipGrantResult({
    required this.success,
    required this.message,
    required this.planCode,
    this.startsAt,
    this.endsAt,
  });

  factory AdminMembershipGrantResult.fromMap(Map<String, Object?> map) {
    return AdminMembershipGrantResult(
      success: map['success'] == true,
      message: _text(map['message']) ?? '',
      planCode: _text(map['plan_code']) ?? '',
      startsAt: _date(map['starts_at']),
      endsAt: _date(map['ends_at']),
    );
  }
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(Object? value) {
  final text = _text(value);
  return text == null ? null : DateTime.tryParse(text);
}
