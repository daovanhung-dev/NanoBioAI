part of 'admin_workspace_page.dart';

class AdminActionPresentation {
  final String key;
  final String label;
  final String confirmLabel;
  final IconData icon;
  final bool danger;

  const AdminActionPresentation({
    required this.key,
    required this.label,
    required this.confirmLabel,
    required this.icon,
    this.danger = false,
  });
}

class _NavigationGroup {
  final String label;
  final List<AdminPanelSection> sections;

  const _NavigationGroup(this.label, this.sections);
}

class _StatusTone {
  final Color color;
  final Color background;

  const _StatusTone(this.color, this.background);
}

List<_NavigationGroup> _navigationGroups(List<AdminPanelSection> available) {
  List<AdminPanelSection> pick(List<AdminPanelSection> values) {
    return values.where(available.contains).toList(growable: false);
  }

  return [
    _NavigationGroup('TỔNG QUAN', pick(const [AdminPanelSection.dashboard])),
    _NavigationGroup(
      'KHÁCH HÀNG',
      pick(const [AdminPanelSection.users, AdminPanelSection.payments]),
    ),
    _NavigationGroup(
      'CỘNG TÁC VIÊN',
      pick(const [AdminPanelSection.sales, AdminPanelSection.saleConversions]),
    ),
    _NavigationGroup(
      'VẬN HÀNH',
      pick(const [
        AdminPanelSection.wellnessRewards,
        AdminPanelSection.reconciliation,
        AdminPanelSection.plans,
        AdminPanelSection.reports,
      ]),
    ),
    _NavigationGroup(
      'HỆ THỐNG',
      pick(const [AdminPanelSection.audit, AdminPanelSection.config]),
    ),
  ].where((group) => group.sections.isNotEmpty).toList(growable: false);
}

List<AdminActionPresentation> _actionsFor(
  AdminPanelSection section,
  String status,
) {
  final all = switch (section) {
    AdminPanelSection.users => const [
      AdminActionPresentation(
        key: 'active',
        label: 'Mở lại',
        confirmLabel: 'Mở lại tài khoản',
        icon: Icons.lock_open_rounded,
      ),
      AdminActionPresentation(
        key: 'suspended',
        label: 'Tạm khóa',
        confirmLabel: 'Tạm khóa tài khoản',
        icon: Icons.lock_rounded,
        danger: true,
      ),
    ],
    AdminPanelSection.payments => const [
      AdminActionPresentation(
        key: 'approve',
        label: 'Duyệt',
        confirmLabel: 'Duyệt thanh toán',
        icon: Icons.check_circle_rounded,
      ),
      AdminActionPresentation(
        key: 'reject',
        label: 'Từ chối',
        confirmLabel: 'Từ chối thanh toán',
        icon: Icons.block_rounded,
        danger: true,
      ),
    ],
    AdminPanelSection.sales => const [
      AdminActionPresentation(
        key: 'approve',
        label: 'Duyệt',
        confirmLabel: 'Duyệt hồ sơ',
        icon: Icons.verified_user_rounded,
      ),
      AdminActionPresentation(
        key: 'reject',
        label: 'Từ chối',
        confirmLabel: 'Từ chối hồ sơ',
        icon: Icons.block_rounded,
        danger: true,
      ),
      AdminActionPresentation(
        key: 'suspend',
        label: 'Tạm dừng',
        confirmLabel: 'Tạm dừng hoạt động',
        icon: Icons.pause_circle_rounded,
        danger: true,
      ),
      AdminActionPresentation(
        key: 'close',
        label: 'Đóng',
        confirmLabel: 'Đóng cộng tác viên',
        icon: Icons.cancel_rounded,
        danger: true,
      ),
    ],
    AdminPanelSection.saleConversions => const [
      AdminActionPresentation(
        key: 'approve',
        label: 'Duyệt',
        confirmLabel: 'Duyệt yêu cầu',
        icon: Icons.check_circle_rounded,
      ),
      AdminActionPresentation(
        key: 'reject',
        label: 'Từ chối',
        confirmLabel: 'Từ chối yêu cầu',
        icon: Icons.block_rounded,
        danger: true,
      ),
      AdminActionPresentation(
        key: 'mark_paid',
        label: 'Xác nhận chi trả',
        confirmLabel: 'Chọn ảnh và xác nhận',
        icon: Icons.payments_rounded,
      ),
    ],
    AdminPanelSection.reconciliation => const [
      AdminActionPresentation(
        key: 'resolved',
        label: 'Đã đối soát',
        confirmLabel: 'Xác nhận đã đối soát',
        icon: Icons.task_alt_rounded,
      ),
      AdminActionPresentation(
        key: 'needs_follow_up',
        label: 'Cần theo dõi',
        confirmLabel: 'Đánh dấu cần theo dõi',
        icon: Icons.manage_search_rounded,
      ),
      AdminActionPresentation(
        key: 'adjusted',
        label: 'Đã điều chỉnh',
        confirmLabel: 'Xác nhận điều chỉnh',
        icon: Icons.tune_rounded,
      ),
      AdminActionPresentation(
        key: 'dismissed',
        label: 'Bỏ qua',
        confirmLabel: 'Bỏ qua mục này',
        icon: Icons.close_rounded,
        danger: true,
      ),
    ],
    AdminPanelSection.plans => const [
      AdminActionPresentation(
        key: 'upsert',
        label: 'Cập nhật',
        confirmLabel: 'Lưu cập nhật',
        icon: Icons.save_rounded,
      ),
    ],
    AdminPanelSection.reports => const [
      AdminActionPresentation(
        key: 'export',
        label: 'Xuất báo cáo',
        confirmLabel: 'Tạo yêu cầu xuất',
        icon: Icons.download_rounded,
      ),
    ],
    AdminPanelSection.config => const [
      AdminActionPresentation(
        key: 'upsert',
        label: 'Lưu thiết lập',
        confirmLabel: 'Lưu thiết lập',
        icon: Icons.save_as_rounded,
      ),
    ],
    _ => const <AdminActionPresentation>[],
  };

  final normalized = status.toLowerCase();
  return switch (section) {
    AdminPanelSection.users when normalized.contains('closed') => const [],
    AdminPanelSection.users when normalized.contains('active') =>
      all.where((action) => action.key == 'suspended').toList(growable: false),
    AdminPanelSection.users when normalized.contains('suspended') =>
      all.where((action) => action.key == 'active').toList(growable: false),
    AdminPanelSection.payments
        when !adminPaymentStatusCanBeReviewed(normalized) =>
      const [],
    AdminPanelSection.sales when normalized.contains('closed') => const [],
    AdminPanelSection.sales when normalized.contains('pending') =>
      all
          .where((action) => action.key == 'approve' || action.key == 'reject')
          .toList(growable: false),
    AdminPanelSection.sales when normalized.contains('active') =>
      all
          .where((action) => action.key == 'suspend' || action.key == 'close')
          .toList(growable: false),
    AdminPanelSection.sales when normalized.contains('suspended') =>
      all
          .where((action) => action.key == 'approve' || action.key == 'close')
          .toList(growable: false),
    AdminPanelSection.saleConversions when normalized.contains('approved') =>
      all.where((action) => action.key == 'mark_paid').toList(growable: false),
    AdminPanelSection.saleConversions
        when normalized.contains('paid') || normalized.contains('rejected') =>
      const [],
    AdminPanelSection.reconciliation
        when normalized.contains('resolved') ||
            normalized.contains('dismissed') ||
            normalized.contains('adjusted') =>
      const [],
    _ => all,
  };
}

String _routeForSection(AdminPanelSection section) {
  return switch (section) {
    AdminPanelSection.dashboard => AdminRoutePaths.dashboard,
    AdminPanelSection.users => AdminRoutePaths.users,
    AdminPanelSection.payments => AdminRoutePaths.payments,
    AdminPanelSection.sales => AdminRoutePaths.sales,
    AdminPanelSection.saleConversions => AdminRoutePaths.saleConversions,
    AdminPanelSection.wellnessRewards => AdminRoutePaths.wellnessRewards,
    AdminPanelSection.reconciliation => AdminRoutePaths.reconciliation,
    AdminPanelSection.plans => AdminRoutePaths.plans,
    AdminPanelSection.reports => AdminRoutePaths.reports,
    AdminPanelSection.audit => AdminRoutePaths.audit,
    AdminPanelSection.config => AdminRoutePaths.config,
  };
}

IconData _iconForSection(AdminPanelSection section, bool selected) {
  return switch ((section, selected)) {
    (AdminPanelSection.dashboard, true) => Icons.space_dashboard_rounded,
    (AdminPanelSection.dashboard, false) => Icons.space_dashboard_outlined,
    (AdminPanelSection.users, true) => Icons.people_rounded,
    (AdminPanelSection.users, false) => Icons.people_outline_rounded,
    (AdminPanelSection.payments, true) => Icons.payments_rounded,
    (AdminPanelSection.payments, false) => Icons.payments_outlined,
    (AdminPanelSection.sales, true) => Icons.badge_rounded,
    (AdminPanelSection.sales, false) => Icons.badge_outlined,
    (AdminPanelSection.saleConversions, true) =>
      Icons.published_with_changes_rounded,
    (AdminPanelSection.saleConversions, false) =>
      Icons.published_with_changes_outlined,
    (AdminPanelSection.wellnessRewards, true) => Icons.redeem_rounded,
    (AdminPanelSection.wellnessRewards, false) => Icons.redeem_outlined,
    (AdminPanelSection.reconciliation, true) => Icons.fact_check_rounded,
    (AdminPanelSection.reconciliation, false) => Icons.fact_check_outlined,
    (AdminPanelSection.plans, true) => Icons.workspace_premium_rounded,
    (AdminPanelSection.plans, false) => Icons.workspace_premium_outlined,
    (AdminPanelSection.reports, true) => Icons.summarize_rounded,
    (AdminPanelSection.reports, false) => Icons.summarize_outlined,
    (AdminPanelSection.audit, true) => Icons.history_rounded,
    (AdminPanelSection.audit, false) => Icons.history_outlined,
    (AdminPanelSection.config, true) => Icons.tune_rounded,
    (AdminPanelSection.config, false) => Icons.tune_outlined,
  };
}

_StatusTone _statusTone(String status, AdminWorkspaceColors colors) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') ||
      normalized.contains('reject') ||
      normalized.contains('suspend') ||
      normalized.contains('chargeback')) {
    return _StatusTone(colors.danger, colors.dangerContainer);
  }
  if (normalized.contains('pending') ||
      normalized.contains('review') ||
      normalized.contains('requested') ||
      normalized.contains('open') ||
      normalized.contains('follow')) {
    return _StatusTone(colors.warning, colors.warningContainer);
  }
  if (normalized.contains('active') ||
      normalized.contains('approved') ||
      normalized.contains('ready') ||
      normalized.contains('succeeded') ||
      normalized.contains('resolved') ||
      normalized.contains('paid')) {
    return _StatusTone(colors.mint, colors.successContainer);
  }
  if (normalized.contains('closed') ||
      normalized.contains('cancel') ||
      normalized.contains('archived') ||
      normalized.contains('dismissed')) {
    return _StatusTone(colors.textMuted, colors.neutralContainer);
  }
  return _StatusTone(colors.cyan, colors.infoContainer);
}

IconData _statusIcon(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') || normalized.contains('reject')) {
    return Icons.error_outline_rounded;
  }
  if (normalized.contains('pending') || normalized.contains('requested')) {
    return Icons.pending_actions_rounded;
  }
  if (normalized.contains('paid') || normalized.contains('succeeded')) {
    return Icons.task_alt_rounded;
  }
  return Icons.insights_rounded;
}

String? _metadataString(Map<String, Object?> metadata, String key) {
  final value = metadata[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int _metadataInt(Map<String, Object?> metadata, String key) {
  final value = metadata[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatMoney(int amount, String currency) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '$sign$buffer $currency';
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final local = VietnamTime.wallClock(dateTime);
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
