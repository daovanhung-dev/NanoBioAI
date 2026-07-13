class CreateMembershipPaymentRequestCommand {
  final String planCode;
  final String billingCycle;
  final String idempotencyKey;

  const CreateMembershipPaymentRequestCommand({
    required this.planCode,
    required this.billingCycle,
    required this.idempotencyKey,
  });
}

class MembershipPaymentRequest {
  final String id;
  final String planCode;
  final String billingCycle;
  final String status;
  final int amountCents;
  final String currency;
  final DateTime? createdAt;

  const MembershipPaymentRequest({
    required this.id,
    required this.planCode,
    required this.billingCycle,
    required this.status,
    required this.amountCents,
    required this.currency,
    this.createdAt,
  });

  factory MembershipPaymentRequest.fromMap(Map<String, Object?> map) {
    return MembershipPaymentRequest(
      id: _readString(map['payment_event_id'] ?? map['id']) ?? '',
      planCode: _readString(map['plan_code']) ?? '',
      billingCycle: _readString(map['billing_cycle']) ?? '',
      status: _readString(map['status']) ?? 'pending',
      amountCents: _readInt(map['amount_cents']),
      currency: _readString(map['currency']) ?? 'VND',
      createdAt: _readDate(map['created_at']),
    );
  }
}

class MembershipPaymentException implements Exception {
  final String code;
  final String safeMessage;

  const MembershipPaymentException(this.code, this.safeMessage);

  const MembershipPaymentException.invalidCommand()
    : this('INVALID_COMMAND', 'Thông tin tạo yêu cầu thanh toán chưa hợp lệ.');

  const MembershipPaymentException.authRequired()
    : this('AUTH_REQUIRED', 'Cần đăng nhập để tạo yêu cầu thanh toán.');

  @override
  String toString() => '$code: $safeMessage';
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  return text == null ? null : DateTime.tryParse(text);
}
