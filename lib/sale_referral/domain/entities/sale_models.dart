enum SaleStatus { none, pending, active, suspended, closed }

class SaleState {
  final SaleStatus status;
  final String? referralCode;
  final String? termsVersion;
  final DateTime? approvedAt;
  final String? note;
  final bool payoutProfileComplete;

  const SaleState({
    required this.status,
    this.referralCode,
    this.termsVersion,
    this.approvedAt,
    this.note,
    this.payoutProfileComplete = false,
  });

  static const none = SaleState(status: SaleStatus.none);

  bool get isActive => status == SaleStatus.active;
  bool get isPending => status == SaleStatus.pending;

  factory SaleState.fromMap(Map<String, Object?> map) {
    return SaleState(
      status: saleStatusFromObject(map['sale_status'] ?? map['status']),
      referralCode: readString(map['referral_code']),
      termsVersion: readString(map['terms_version']),
      approvedAt: readDate(map['approved_at']),
      note: readString(map['note']),
      payoutProfileComplete: readBool(map['payout_profile_complete']),
    );
  }
}

class SalePayoutProfile {
  final String citizenId;
  final String bankBin;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final DateTime? updatedAt;

  const SalePayoutProfile({
    required this.citizenId,
    required this.bankBin,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.updatedAt,
  });

  bool get isComplete {
    return citizenId.isNotEmpty &&
        bankBin.isNotEmpty &&
        bankName.isNotEmpty &&
        bankAccountNumber.isNotEmpty &&
        bankAccountName.isNotEmpty;
  }

  factory SalePayoutProfile.fromMap(Map<String, Object?> map) {
    return SalePayoutProfile(
      citizenId: readString(map['citizen_id']) ?? '',
      bankBin: readString(map['bank_bin']) ?? '',
      bankName: readString(map['bank_name']) ?? '',
      bankAccountNumber: readString(map['bank_account_number']) ?? '',
      bankAccountName: readString(map['bank_account_name']) ?? '',
      updatedAt: readDate(map['updated_at']),
    );
  }
}

class SalePayoutProfileCommand {
  final String citizenId;
  final String bankBin;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;

  const SalePayoutProfileCommand({
    required this.citizenId,
    required this.bankBin,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
  });
}

class SaleDashboard {
  final int directCustomers;
  final int successfulPayments;
  final int pendingPointCents;
  final int approvedPointCents;
  final int paidPointCents;
  final int convertedPointCents;
  final int availablePointCents;
  final String currency;
  final SaleConversionPolicy conversionPolicy;

  const SaleDashboard({
    required this.directCustomers,
    required this.successfulPayments,
    required this.pendingPointCents,
    required this.approvedPointCents,
    required this.paidPointCents,
    required this.convertedPointCents,
    required this.availablePointCents,
    required this.currency,
    required this.conversionPolicy,
  });

  factory SaleDashboard.fromMap(Map<String, Object?> map) {
    return SaleDashboard(
      directCustomers: readInt(
        map['direct_customers'] ?? map['direct_referrals'],
      ),
      successfulPayments: readInt(map['successful_payments']),
      pendingPointCents: readInt(
        map['pending_point_cents'] ?? map['pending_commission_cents'],
      ),
      approvedPointCents: readInt(
        map['approved_point_cents'] ?? map['approved_commission_cents'],
      ),
      paidPointCents: readInt(
        map['paid_point_cents'] ?? map['paid_commission_cents'],
      ),
      convertedPointCents: readInt(map['converted_point_cents']),
      availablePointCents: readInt(map['available_point_cents']),
      currency: readString(map['currency']) ?? 'VND',
      conversionPolicy: SaleConversionPolicy.fromMap(map),
    );
  }
}

class SaleDirectCustomer {
  final String displayName;
  final int? age;
  final String? phone;
  final DateTime? acceptedAt;
  final int successfulPayments;
  final int approvedPointCents;
  final String currency;

  const SaleDirectCustomer({
    required this.displayName,
    this.age,
    this.phone,
    this.acceptedAt,
    required this.successfulPayments,
    required this.approvedPointCents,
    required this.currency,
  });

  factory SaleDirectCustomer.fromMap(Map<String, Object?> map) {
    return SaleDirectCustomer(
      displayName: readString(map['display_name']) ?? 'Nguoi dung NanoBio',
      age: readNullableInt(map['age']),
      phone: readString(map['phone']),
      acceptedAt: readDate(map['accepted_at']),
      successfulPayments: readInt(map['successful_payments']),
      approvedPointCents: readInt(map['approved_point_cents']),
      currency: readString(map['currency']) ?? 'VND',
    );
  }
}

class SalePointLedgerEntry {
  final String id;
  final String customerName;
  final String planCode;
  final int paymentAmountCents;
  final int pointAmountCents;
  final String currency;
  final String status;
  final DateTime? createdAt;

  const SalePointLedgerEntry({
    required this.id,
    required this.customerName,
    required this.planCode,
    required this.paymentAmountCents,
    required this.pointAmountCents,
    required this.currency,
    required this.status,
    this.createdAt,
  });

  factory SalePointLedgerEntry.fromMap(Map<String, Object?> map) {
    return SalePointLedgerEntry(
      id: readString(map['id']) ?? '',
      customerName: readString(map['customer_name']) ?? 'Nguoi dung NanoBio',
      planCode: readString(map['plan_code']) ?? '',
      paymentAmountCents: readInt(map['payment_amount_cents']),
      pointAmountCents: readInt(
        map['point_amount_cents'] ?? map['amount_cents'],
      ),
      currency: readString(map['currency']) ?? 'VND',
      status: readString(map['status']) ?? 'pending',
      createdAt: readDate(map['created_at']),
    );
  }
}

class SaleConversionRequest {
  final String id;
  final int requestedPointCents;
  final int moneyAmountCents;
  final String currency;
  final String status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? note;

  const SaleConversionRequest({
    required this.id,
    required this.requestedPointCents,
    required this.moneyAmountCents,
    required this.currency,
    required this.status,
    this.requestedAt,
    this.reviewedAt,
    this.note,
  });

  factory SaleConversionRequest.fromMap(Map<String, Object?> map) {
    return SaleConversionRequest(
      id: readString(map['id']) ?? '',
      requestedPointCents: readInt(
        map['requested_point_cents'] ?? map['points_requested_cents'],
      ),
      moneyAmountCents: readInt(map['money_amount_cents']),
      currency: readString(map['currency']) ?? 'VND',
      status: readString(map['status']) ?? 'requested',
      requestedAt: readDate(map['requested_at'] ?? map['created_at']),
      reviewedAt: readDate(map['reviewed_at']),
      note: readString(map['note'] ?? map['review_reason']),
    );
  }
}

class SaleConversionPolicy {
  final bool enabled;
  final double pointToMoneyRate;
  final int minimumPointCents;
  final String currency;

  const SaleConversionPolicy({
    required this.enabled,
    required this.pointToMoneyRate,
    required this.minimumPointCents,
    required this.currency,
  });

  const SaleConversionPolicy.disabled()
    : enabled = false,
      pointToMoneyRate = 0,
      minimumPointCents = 0,
      currency = 'VND';

  bool canRequest(int availablePointCents) {
    return enabled &&
        pointToMoneyRate > 0 &&
        minimumPointCents > 0 &&
        availablePointCents >= minimumPointCents;
  }

  int estimateMoneyCents(int pointCents) {
    if (!enabled || pointToMoneyRate <= 0) return 0;
    return (pointCents * pointToMoneyRate).round();
  }

  factory SaleConversionPolicy.fromMap(Map<String, Object?> map) {
    return SaleConversionPolicy(
      enabled: readBool(map['conversion_enabled']),
      pointToMoneyRate: readDouble(map['conversion_rate']),
      minimumPointCents: readInt(map['conversion_minimum_point_cents']),
      currency:
          readString(map['conversion_currency'] ?? map['currency']) ?? 'VND',
    );
  }
}

class SaleReferralAttachment {
  final bool success;
  final String message;
  final String? referrerDisplayName;

  const SaleReferralAttachment({
    required this.success,
    required this.message,
    this.referrerDisplayName,
  });

  factory SaleReferralAttachment.fromMap(Map<String, Object?> map) {
    return SaleReferralAttachment(
      success: readBool(map['success']),
      message: readString(map['message']) ?? '',
      referrerDisplayName: readString(map['referrer_display_name']),
    );
  }
}

class SaleConversionCommand {
  final int pointCents;
  final String idempotencyKey;

  const SaleConversionCommand({
    required this.pointCents,
    required this.idempotencyKey,
  });
}

SaleStatus saleStatusFromObject(Object? value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'pending':
    case 'pending_review':
      return SaleStatus.pending;
    case 'active':
      return SaleStatus.active;
    case 'suspended':
      return SaleStatus.suspended;
    case 'closed':
      return SaleStatus.closed;
    default:
      return SaleStatus.none;
  }
}

String? readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool readBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'enabled';
}

DateTime? readDate(Object? value) {
  final text = readString(value);
  return text == null ? null : DateTime.tryParse(text);
}
