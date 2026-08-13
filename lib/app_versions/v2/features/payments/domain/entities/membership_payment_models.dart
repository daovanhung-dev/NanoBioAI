class CreateMembershipPaymentRequestCommand {
  final String planCode;
  final String billingCycle;
  final String idempotencyKey;

  /// Legacy/display-only compatibility field. The M13 v2 remote datasource
  /// does not send this value to Supabase; the backend reads the authenticated
  /// user's profile itself.
  final String payerFullName;

  const CreateMembershipPaymentRequestCommand({
    required this.planCode,
    required this.billingCycle,
    required this.idempotencyKey,
    required this.payerFullName,
  });
}

String normalizeMembershipPaymentPlanCode(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'family_plus' => 'family_plus',
    'plus' => 'plus',
    _ => 'plus',
  };
}

class MembershipPaymentRequest {
  static final RegExp canonicalTransferReferencePattern = RegExp(
    r'^NB[0-9A-F]{12}$',
  );

  final String id;
  final String planCode;
  final String billingCycle;
  final String status;
  final int amountCents;
  final String currency;
  final String? transferReference;
  final String? transferMemo;
  final String? payerFullName;
  final String? bankCode;
  final String? bankName;
  final String? bankBin;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? bankAccountDisplayName;
  final DateTime? transferConfirmedAt;
  final String? reviewReason;
  final DateTime? createdAt;

  const MembershipPaymentRequest({
    required this.id,
    required this.planCode,
    required this.billingCycle,
    required this.status,
    required this.amountCents,
    required this.currency,
    this.transferReference,
    this.transferMemo,
    this.payerFullName,
    this.bankCode,
    this.bankName,
    this.bankBin,
    this.bankAccountNumber,
    this.bankAccountName,
    this.bankAccountDisplayName,
    this.transferConfirmedAt,
    this.reviewReason,
    this.createdAt,
  });

  factory MembershipPaymentRequest.fromMap(Map<String, Object?> map) {
    return MembershipPaymentRequest(
      id: _readString(map['payment_event_id'] ?? map['id']) ?? '',
      planCode: _readString(map['plan_code']) ?? '',
      billingCycle: _readString(map['billing_cycle']) ?? '',
      status: _readString(map['status']) ?? 'pending',
      amountCents: _readInt(map['amount_cents']),
      currency: _readString(map['currency']) ?? '',
      transferReference: _readString(map['transfer_reference']),
      transferMemo: _readString(map['transfer_memo']),
      payerFullName: _readString(map['payer_full_name']),
      bankCode: _readString(map['bank_code']),
      bankName: _readString(map['bank_name']),
      bankBin: _readString(map['bank_bin']),
      bankAccountNumber: _readString(map['bank_account_number']),
      bankAccountName: _readString(map['bank_account_name']),
      bankAccountDisplayName: _readString(map['bank_account_display_name']),
      transferConfirmedAt: _readDate(map['transfer_confirmed_at']),
      reviewReason: _readString(map['review_reason']),
      createdAt: _readDate(map['created_at']),
    );
  }

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isAwaitingTransfer => normalizedStatus == 'awaiting_transfer';

  bool get isPendingReview => normalizedStatus == 'pending_review';

  bool get isLegacyPending => const {
    'pending',
    'requested',
  }.contains(normalizedStatus);

  bool get isSucceeded => normalizedStatus == 'succeeded';

  bool get isTerminal => const {
    'succeeded',
    'failed',
    'rejected',
    'cancelled',
    'canceled',
    'refunded',
    'paid',
  }.contains(normalizedStatus);

  bool get isActive => isAwaitingTransfer || isPendingReview;

  bool get canConfirmTransfer =>
      isAwaitingTransfer && id.trim().isNotEmpty && hasTransferDetails;

  bool get canCancel => isAwaitingTransfer && id.trim().isNotEmpty;

  String? get transferMemoForPayment {
    final reference = transferReference?.trim().toUpperCase();
    if (reference == null ||
        !canonicalTransferReferencePattern.hasMatch(reference)) {
      return null;
    }
    return reference;
  }

  bool get hasTransferDetails {
    final normalizedBin = bankBin?.trim();
    final normalizedAccountNumber = bankAccountNumber?.trim();
    final normalizedAccountName = bankAccountName?.trim();

    return amountCents > 0 &&
        currency.trim().toUpperCase() == 'VND' &&
        normalizedBin != null &&
        RegExp(r'^[0-9]{6}$').hasMatch(normalizedBin) &&
        normalizedAccountNumber != null &&
        RegExp(r'^[0-9]{4,32}$').hasMatch(normalizedAccountNumber) &&
        normalizedAccountName != null &&
        normalizedAccountName.isNotEmpty &&
        transferMemoForPayment != null;
  }

  bool get canRenderVietQr => isAwaitingTransfer && hasTransferDetails;
}

class MembershipPaymentException implements Exception {
  final String code;
  final String safeMessage;

  const MembershipPaymentException(this.code, this.safeMessage);

  const MembershipPaymentException.invalidCommand()
    : this('INVALID_COMMAND', 'Thông tin tạo yêu cầu thanh toán chưa hợp lệ.');

  const MembershipPaymentException.authRequired()
    : this('AUTH_REQUIRED', 'Cần đăng nhập để tạo yêu cầu thanh toán.');

  // Kept for source compatibility with older tests/callers. M13 v2 no longer
  // blocks QR creation on a mobile-side payer-name prerequisite.
  const MembershipPaymentException.missingPayerName()
    : this(
        'MISSING_PAYER_NAME',
        'Bạn cần cập nhật họ và tên trong hồ sơ trước khi tạo mã thanh toán.',
      );

  const MembershipPaymentException.invalidServerPaymentPayload()
    : this(
        'PAYMENT_QR_PAYLOAD_INVALID',
        'Máy chủ chưa trả đủ thông tin để tạo mã thanh toán. Bạn hãy thử lại.',
      );

  const MembershipPaymentException.invalidTransferConfirmation()
    : this(
        'INVALID_TRANSFER_CONFIRMATION',
        'Yêu cầu thanh toán này chưa sẵn sàng để xác nhận chuyển khoản.',
      );

  const MembershipPaymentException.invalidCancellation()
    : this(
        'INVALID_CANCELLATION',
        'Yêu cầu thanh toán này không còn có thể hủy.',
      );

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
