enum AdminRoleCode {
  superAdmin('super_admin'),
  financeAdmin('finance_admin'),
  supportAdmin('support_admin'),
  contentAdmin('content_admin'),
  operationsAdmin('operations_admin');

  final String value;

  const AdminRoleCode(this.value);

  static AdminRoleCode? fromValue(Object? value) {
    final text = value?.toString().trim();
    for (final role in values) {
      if (role.value == text) return role;
    }
    return null;
  }
}

enum AdminPanelSection {
  dashboard('dashboard'),
  users('users'),
  payments('payments'),
  sales('sales'),
  saleConversions('sale_conversions'),
  wellnessRewards('wellness_rewards'),
  reconciliation('reconciliation'),
  plans('plans'),
  reports('reports'),
  audit('audit'),
  config('config');

  final String value;

  const AdminPanelSection(this.value);

  static AdminPanelSection? fromValue(Object? value) {
    final text = value?.toString().trim();
    for (final section in values) {
      if (section.value == text) return section;
    }
    return null;
  }
}

abstract class AdminPermissions {
  static const wildcard = '*';
  static const dashboardRead = 'dashboard.read';
  static const usersWrite = 'users.write';
  static const paymentsWrite = 'payments.write';
  static const salesWrite = 'sales.write';
  static const reconciliationWrite = 'reconciliation.write';
  static const pointsWrite = 'points.write';
  static const wellnessRewardsRead = 'wellness_rewards.read';
  static const wellnessRewardsWrite = 'wellness_rewards.write';
  static const plansWrite = 'plans.write';
  static const reportsWrite = 'reports.write';
  static const auditRead = 'audit.read';
  static const configWrite = 'config.write';
}

abstract class AdminTimeDefaults {
  static const vietnamTimeZone = 'Asia/Ho_Chi_Minh';
}

String adminPermissionForSection(AdminPanelSection section) {
  return switch (section) {
    AdminPanelSection.dashboard => AdminPermissions.dashboardRead,
    AdminPanelSection.users => AdminPermissions.usersWrite,
    AdminPanelSection.payments => AdminPermissions.paymentsWrite,
    AdminPanelSection.sales => AdminPermissions.salesWrite,
    AdminPanelSection.saleConversions => AdminPermissions.salesWrite,
    AdminPanelSection.wellnessRewards => AdminPermissions.wellnessRewardsRead,
    AdminPanelSection.reconciliation => AdminPermissions.reconciliationWrite,
    AdminPanelSection.plans => AdminPermissions.plansWrite,
    AdminPanelSection.reports => AdminPermissions.reportsWrite,
    AdminPanelSection.audit => AdminPermissions.auditRead,
    AdminPanelSection.config => AdminPermissions.configWrite,
  };
}

bool adminSectionSupportsMutation(AdminPanelSection section) {
  return switch (section) {
    AdminPanelSection.dashboard || AdminPanelSection.audit => false,
    _ => true,
  };
}

String adminPermissionForMutation(AdminMutationCommand command) {
  if (command.action == 'adjust_points') return AdminPermissions.pointsWrite;
  if (command.section == AdminPanelSection.wellnessRewards) {
    return AdminPermissions.wellnessRewardsWrite;
  }
  return adminPermissionForSection(command.section);
}

class AdminSession {
  final String userId;
  final List<AdminRoleCode> roles;
  final Set<String> permissions;
  final bool active;
  final bool canUseUserApp;

  const AdminSession({
    required this.userId,
    required this.roles,
    required this.permissions,
    required this.active,
    this.canUseUserApp = true,
  });

  static const anonymous = AdminSession(
    userId: '',
    roles: [],
    permissions: {},
    active: false,
    canUseUserApp: false,
  );

  bool get isAdmin => active && roles.isNotEmpty;

  bool get hasWildcardPermission {
    return isAdmin && permissions.contains(AdminPermissions.wildcard);
  }

  bool hasPermission(String permission) {
    return isAdmin &&
        (hasWildcardPermission || permissions.contains(permission));
  }

  bool canAccessSection(AdminPanelSection section) {
    return isAdmin && hasPermission(adminPermissionForSection(section));
  }

  bool canRunMutation(AdminMutationCommand command) {
    return isAdmin &&
        adminSectionSupportsMutation(command.section) &&
        hasPermission(adminPermissionForMutation(command));
  }

  factory AdminSession.fromMap(Map<String, Object?> map) {
    return AdminSession(
      userId: _readString(map['user_id']) ?? '',
      roles: _readList(map['roles'])
          .map(AdminRoleCode.fromValue)
          .whereType<AdminRoleCode>()
          .toList(growable: false),
      permissions: _readList(
        map['permissions'],
      ).map((value) => value.toString()).toSet(),
      active: _readBool(map['is_active']) ?? false,
      canUseUserApp:
          _readBool(map['can_use_user_app']) ??
          (_readString(map['app_access_mode']) != 'admin'),
    );
  }
}

class AdminDashboardMetric {
  final String key;
  final String label;
  final int value;
  final String status;
  final String? targetSection;

  const AdminDashboardMetric({
    required this.key,
    required this.label,
    required this.value,
    required this.status,
    this.targetSection,
  });

  factory AdminDashboardMetric.fromMap(Map<String, Object?> map) {
    return AdminDashboardMetric(
      key: _readString(map['metric_key']) ?? 'unknown',
      label: _readString(map['label']) ?? 'Metric',
      value: _readInt(map['metric_value']),
      status: _readString(map['status']) ?? 'ready',
      targetSection: _readString(map['target_section']),
    );
  }
}

/// The small, permission-scoped summary shown to payment-capable Admins.
///
/// It intentionally counts only customer-confirmed transfers that are ready
/// for review. Legacy `pending` payments remain reviewable in the queue, but
/// do not create a new-payment alert.
class AdminPaymentReviewAlert {
  final int pendingReviewCount;

  const AdminPaymentReviewAlert({required this.pendingReviewCount});

  static const empty = AdminPaymentReviewAlert(pendingReviewCount: 0);

  bool get hasPendingReviews => pendingReviewCount > 0;

  factory AdminPaymentReviewAlert.fromMap(Map<String, Object?> map) {
    final count = _readInt(map['pending_review_count']);
    return AdminPaymentReviewAlert(pendingReviewCount: count < 0 ? 0 : count);
  }
}

/// Server-provided details an Admin uses to reconcile an inbound VietQR
/// transfer in the Vietcombank application before making a decision.
///
/// This is deliberately read-only. The client never generates or amends the
/// transfer reference, memo, amount, or confirmation timestamp.
class AdminPaymentReconciliationDetails {
  final String? transferReference;
  final String? transferMemo;
  final String? payerFullName;
  final int? amountCents;
  final String? currency;
  final DateTime? transferConfirmedAt;

  const AdminPaymentReconciliationDetails({
    this.transferReference,
    this.transferMemo,
    this.payerFullName,
    this.amountCents,
    this.currency,
    this.transferConfirmedAt,
  });

  bool get hasDetails {
    return transferReference != null ||
        transferMemo != null ||
        payerFullName != null ||
        amountCents != null ||
        transferConfirmedAt != null;
  }

  factory AdminPaymentReconciliationDetails.fromMap(Map<String, Object?> map) {
    final rawAmount = map['amount_cents'];
    return AdminPaymentReconciliationDetails(
      transferReference: _readString(map['transfer_reference']),
      transferMemo: _readString(map['transfer_memo']),
      payerFullName: _readString(map['payer_full_name']),
      amountCents: rawAmount == null ? null : _readInt(rawAmount),
      currency: _readString(map['currency']),
      transferConfirmedAt: _readDate(map['transfer_confirmed_at']),
    );
  }
}

bool adminPaymentStatusCanBeReviewed(String status) {
  return switch (status.trim().toLowerCase()) {
    'pending_review' || 'pending' => true,
    _ => false,
  };
}

class AdminWorkItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String section;
  final DateTime? createdAt;
  final Map<String, Object?> metadata;
  final AdminPaymentReconciliationDetails? paymentReconciliation;

  const AdminWorkItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.section,
    this.createdAt,
    this.metadata = const {},
    this.paymentReconciliation,
  });

  factory AdminWorkItem.fromMap(Map<String, Object?> map) {
    final metadata = _readMap(map['metadata']);
    final reconciliation = AdminPaymentReconciliationDetails.fromMap({
      ...metadata,
      ...map,
    });
    return AdminWorkItem(
      id: _readString(map['id']) ?? '',
      title: _readString(map['title']) ?? 'Ban ghi',
      subtitle: _readString(map['subtitle']) ?? '',
      status: _readString(map['status']) ?? 'ready',
      section: _readString(map['section']) ?? '',
      createdAt: _readDate(map['created_at']),
      metadata: metadata,
      paymentReconciliation: reconciliation.hasDetails ? reconciliation : null,
    );
  }
}

class AdminAuditEvent {
  final String id;
  final String action;
  final String actorId;
  final String target;
  final String reason;
  final DateTime? createdAt;

  const AdminAuditEvent({
    required this.id,
    required this.action,
    required this.actorId,
    required this.target,
    required this.reason,
    this.createdAt,
  });

  factory AdminAuditEvent.fromMap(Map<String, Object?> map) {
    return AdminAuditEvent(
      id: _readString(map['id']) ?? '',
      action: _readString(map['action']) ?? '',
      actorId: _readString(map['actor_id']) ?? '',
      target: _readString(map['target']) ?? '',
      reason: _readString(map['reason']) ?? '',
      createdAt: _readDate(map['created_at']),
    );
  }
}

class AdminMutationCommand {
  final AdminPanelSection section;
  final String action;
  final String targetId;
  final String reason;
  final String idempotencyKey;
  final Map<String, Object?> payload;

  const AdminMutationCommand({
    required this.section,
    required this.action,
    required this.targetId,
    required this.reason,
    required this.idempotencyKey,
    this.payload = const {},
  });
}

class AdminMutationResult {
  final bool success;
  final String message;

  const AdminMutationResult({required this.success, required this.message});

  factory AdminMutationResult.fromMap(Map<String, Object?> map) {
    return AdminMutationResult(
      success: _readBool(map['success']) ?? false,
      message: _readString(map['message']) ?? '',
    );
  }
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

bool? _readBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

Map<String, Object?> _readMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  return text == null ? null : DateTime.tryParse(text);
}

List<Object?> _readList(Object? value) {
  if (value is List) return value.cast<Object?>();
  return const [];
}
