enum AdminRoleCode {
  superAdmin('super_admin'),
  financeAdmin('finance_admin'),
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
  plans('plans'),
  reports('reports'),
  audit('audit'),
  config('config');

  final String value;

  const AdminPanelSection(this.value);
}

abstract class AdminPermissions {
  static const wildcard = '*';
  static const dashboardRead = 'dashboard.read';
  static const usersWrite = 'users.write';
  static const paymentsWrite = 'payments.write';
  static const salesWrite = 'sales.write';
  static const plansWrite = 'plans.write';
  static const reportsWrite = 'reports.write';
  static const auditRead = 'audit.read';
  static const configWrite = 'config.write';
}

String adminPermissionForSection(AdminPanelSection section) {
  return switch (section) {
    AdminPanelSection.dashboard => AdminPermissions.dashboardRead,
    AdminPanelSection.users => AdminPermissions.usersWrite,
    AdminPanelSection.payments => AdminPermissions.paymentsWrite,
    AdminPanelSection.sales => AdminPermissions.salesWrite,
    AdminPanelSection.saleConversions => AdminPermissions.salesWrite,
    AdminPanelSection.plans => AdminPermissions.configWrite,
    AdminPanelSection.reports => AdminPermissions.reportsWrite,
    AdminPanelSection.audit => AdminPermissions.auditRead,
    AdminPanelSection.config => AdminPermissions.configWrite,
  };
}

String adminPermissionForMutation(AdminMutationCommand command) {
  return adminPermissionForSection(command.section);
}

class AdminSession {
  final String userId;
  final List<AdminRoleCode> roles;
  final Set<String> permissions;
  final bool active;

  const AdminSession({
    required this.userId,
    required this.roles,
    required this.permissions,
    required this.active,
  });

  static const anonymous = AdminSession(
    userId: '',
    roles: [],
    permissions: {},
    active: false,
  );

  bool get isAdmin => active && roles.isNotEmpty;

  bool get hasWildcardPermission {
    return permissions.contains(AdminPermissions.wildcard);
  }

  bool hasPermission(String permission) {
    return hasWildcardPermission || permissions.contains(permission);
  }

  bool canAccessSection(AdminPanelSection section) {
    return isAdmin && hasPermission(adminPermissionForSection(section));
  }

  bool canRunMutation(AdminMutationCommand command) {
    return isAdmin && hasPermission(adminPermissionForMutation(command));
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
    );
  }
}

class AdminDashboardMetric {
  final String key;
  final String label;
  final int value;
  final String status;

  const AdminDashboardMetric({
    required this.key,
    required this.label,
    required this.value,
    required this.status,
  });

  factory AdminDashboardMetric.fromMap(Map<String, Object?> map) {
    return AdminDashboardMetric(
      key: _readString(map['metric_key']) ?? 'unknown',
      label: _readString(map['label']) ?? 'Metric',
      value: _readInt(map['metric_value']),
      status: _readString(map['status']) ?? 'ready',
    );
  }
}

class AdminWorkItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String section;
  final DateTime? createdAt;

  const AdminWorkItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.section,
    this.createdAt,
  });

  factory AdminWorkItem.fromMap(Map<String, Object?> map) {
    return AdminWorkItem(
      id: _readString(map['id']) ?? '',
      title: _readString(map['title']) ?? 'Ban ghi',
      subtitle: _readString(map['subtitle']) ?? '',
      status: _readString(map['status']) ?? 'ready',
      section: _readString(map['section']) ?? '',
      createdAt: _readDate(map['created_at']),
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

  const AdminMutationCommand({
    required this.section,
    required this.action,
    required this.targetId,
    required this.reason,
    required this.idempotencyKey,
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

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  return text == null ? null : DateTime.tryParse(text);
}

List<Object?> _readList(Object? value) {
  if (value is List) return value.cast<Object?>();
  return const [];
}
