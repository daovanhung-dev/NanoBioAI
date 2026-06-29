import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class AdminShellPage extends ConsumerStatefulWidget {
  final AdminPanelSection initialSection;

  const AdminShellPage({required this.initialSection, super.key});

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminControllerProvider.notifier)
          .selectSection(widget.initialSection);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AdminPanelState>>(adminControllerProvider, (
      previous,
      next,
    ) {
      final message = next.asData?.value.lastMessage;
      if (message == null || message.isEmpty) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    final state = ref.watch(adminControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _BlockingState(
          icon: Icons.cloud_off_rounded,
          title: 'Chua tai duoc khu quan tri',
          message: 'Nabi chua lay duoc phien Admin. Hay thu lai.',
          actionLabel: 'Thu lai',
          onAction: () => ref.read(adminControllerProvider.notifier).refresh(),
        ),
        data: (data) {
          if (!data.session.isAdmin) {
            return _BlockingState(
              icon: Icons.lock_person_rounded,
              title: 'Tai khoan chua co quyen Admin',
              message:
                  'Nabi da dang nhap, nhung tai khoan nay chua co vai tro quan tri dang hoat dong.',
              actionLabel: 'Dang xuat',
              onAction: _signOut,
            );
          }

          return Row(
            children: [
              _AdminNavRail(
                selected: data.section,
                sections: AdminPanelSection.values
                    .where(data.session.canAccessSection)
                    .toList(growable: false),
                onSelected: _goToSection,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      state: data,
                      search: _search,
                      onSearch: (value) {
                        ref
                            .read(adminControllerProvider.notifier)
                            .search(value);
                      },
                      onRefresh: () {
                        ref.read(adminControllerProvider.notifier).refresh();
                      },
                      onSignOut: _signOut,
                    ),
                    Expanded(
                      child: _AdminContent(state: data, onAction: _runAction),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goToSection(AdminPanelSection section) {
    context.go(section.routePath);
  }

  Future<void> _signOut() async {
    await ref.read(adminControllerProvider.notifier).signOut();
    if (mounted) context.go(AdminRoutePaths.login);
  }

  Future<void> _runAction(
    AdminPanelSection section,
    String action,
    String targetId,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ReasonDialog(action: action),
    );
    if (reason == null || reason.trim().isEmpty) return;

    await ref
        .read(adminControllerProvider.notifier)
        .runMutation(
          section: section,
          action: action,
          targetId: targetId,
          reason: reason,
        );
  }
}

class _AdminNavRail extends StatelessWidget {
  final AdminPanelSection selected;
  final List<AdminPanelSection> sections;
  final ValueChanged<AdminPanelSection> onSelected;

  const _AdminNavRail({
    required this.selected,
    required this.sections,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox(
        width: 96,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Align(
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ),
      );
    }

    final selectedIndex = sections.indexOf(selected);
    return NavigationRail(
      minWidth: 96,
      extended: MediaQuery.sizeOf(context).width >= 1180,
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      onDestinationSelected: (index) {
        onSelected(sections[index]);
      },
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Icon(
          Icons.admin_panel_settings_rounded,
          color: AppColors.primary,
          size: 32,
        ),
      ),
      destinations: sections
          .map(
            (section) => NavigationRailDestination(
              icon: Icon(section.icon),
              selectedIcon: Icon(section.selectedIcon),
              label: Text(section.label),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AdminPanelState state;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;

  const _TopBar({
    required this.state,
    required this.search,
    required this.onSearch,
    required this.onRefresh,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.section.label, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  'Quan tri theo quyen, moi thao tac nhay cam deu can ly do.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (state.section != AdminPanelSection.dashboard &&
              !state.isPermissionDenied)
            SizedBox(
              width: 320,
              child: TextField(
                controller: search,
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  labelText: 'Tim trong ${state.section.label}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Tim',
                    onPressed: () => onSearch(search.text),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            tooltip: 'Lam moi',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Dang xuat',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  final AdminPanelState state;
  final void Function(AdminPanelSection section, String action, String targetId)
  onAction;

  const _AdminContent({required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: state.isPermissionDenied
          ? _PermissionDeniedPanel(
              section: state.section,
              permission: state.deniedPermission!,
            )
          : switch (state.section) {
              AdminPanelSection.dashboard => _DashboardView(state: state),
              AdminPanelSection.audit => _AuditView(events: state.auditEvents),
              _ => _WorkQueueView(state: state, onAction: onAction),
            },
    );
  }
}

class _DashboardView extends StatelessWidget {
  final AdminPanelState state;

  const _DashboardView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.7,
          children: state.metrics.map(_MetricCard.new).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: AdminPanelSection.values
              .where((section) => section != AdminPanelSection.dashboard)
              .where(state.session.canAccessSection)
              .map((section) => _ShortcutCard(section: section))
              .toList(),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final AdminDashboardMetric metric;

  const _MetricCard(this.metric);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _statusIcon(metric.status),
              color: _statusColor(metric.status),
            ),
            const Spacer(),
            Text(metric.value.toString(), style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final AdminPanelSection section;

  const _ShortcutCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 88,
      child: OutlinedButton.icon(
        onPressed: () => context.go(section.routePath),
        icon: Icon(section.icon),
        label: Text(section.label),
      ),
    );
  }
}

class _WorkQueueView extends StatelessWidget {
  final AdminPanelState state;
  final void Function(AdminPanelSection section, String action, String targetId)
  onAction;

  const _WorkQueueView({required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const _EmptyPanel(
        title: 'Chua co du lieu phu hop',
        message: 'Nabi se hien thi danh sach khi Supabase RPC tra ve du lieu.',
      );
    }

    return Column(
      children: state.items
          .map(
            (item) => _WorkItemRow(
              section: state.section,
              session: state.session,
              item: item,
              onAction: onAction,
            ),
          )
          .toList(),
    );
  }
}

class _WorkItemRow extends StatelessWidget {
  final AdminPanelSection section;
  final AdminSession session;
  final AdminWorkItem item;
  final void Function(AdminPanelSection section, String action, String targetId)
  onAction;

  const _WorkItemRow({
    required this.section,
    required this.session,
    required this.item,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = section.actions
        .where((action) {
          return session.canRunMutation(
            AdminMutationCommand(
              section: section,
              action: action.key,
              targetId: item.id,
              reason: 'permission-check',
              idempotencyKey: 'permission-check',
            ),
          );
        })
        .toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(section.icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          _StatusChip(status: item.status),
          const SizedBox(width: AppSpacing.md),
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: OutlinedButton.icon(
                onPressed: () => onAction(section, action.key, item.id),
                icon: Icon(action.icon),
                label: Text(action.label),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuditView extends StatelessWidget {
  final List<AdminAuditEvent> events;

  const _AuditView({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyPanel(
        title: 'Chua co audit phu hop',
        message: 'Audit se hien thi khi co thao tac Admin duoc ghi nhan.',
      );
    }

    return Column(
      children: events
          .map(
            (event) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: _panelDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.action, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${event.target} - ${event.reason}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    event.createdAt?.toLocal().toString().split('.').first ??
                        '',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final String action;

  const _ReasonDialog({required this.action});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Xac nhan ${widget.action}'),
      content: TextField(
        controller: _reason,
        minLines: 3,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Ly do bat buoc',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huy'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_reason.text),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Xac nhan'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          status,
          style: AppTextStyles.bodySmall.copyWith(color: _statusColor(status)),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyPanel({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: _panelDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  color: AppColors.textHint,
                  size: 44,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedPanel extends StatelessWidget {
  final AdminPanelSection section;
  final String permission;

  const _PermissionDeniedPanel({
    required this.section,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: _panelDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  color: AppColors.warning,
                  size: 44,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Khong du quyen ${section.label}',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tai khoan Admin hien tai can quyen $permission de mo muc nay.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockingState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockingState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: _panelDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAction {
  final String key;
  final String label;
  final IconData icon;

  const _AdminAction(this.key, this.label, this.icon);
}

extension _AdminPanelSectionUi on AdminPanelSection {
  String get label {
    return switch (this) {
      AdminPanelSection.dashboard => 'Dashboard',
      AdminPanelSection.users => 'Nguoi dung',
      AdminPanelSection.payments => 'Thanh toan',
      AdminPanelSection.sales => 'Sale',
      AdminPanelSection.saleConversions => 'Quy doi diem Sale',
      AdminPanelSection.plans => 'Goi',
      AdminPanelSection.reports => 'Bao cao',
      AdminPanelSection.audit => 'Audit',
      AdminPanelSection.config => 'Cau hinh',
    };
  }

  String get routePath {
    return switch (this) {
      AdminPanelSection.dashboard => AdminRoutePaths.dashboard,
      AdminPanelSection.users => AdminRoutePaths.users,
      AdminPanelSection.payments => AdminRoutePaths.payments,
      AdminPanelSection.sales => AdminRoutePaths.sales,
      AdminPanelSection.saleConversions => AdminRoutePaths.saleConversions,
      AdminPanelSection.plans => AdminRoutePaths.plans,
      AdminPanelSection.reports => AdminRoutePaths.reports,
      AdminPanelSection.audit => AdminRoutePaths.audit,
      AdminPanelSection.config => AdminRoutePaths.config,
    };
  }

  IconData get icon {
    return switch (this) {
      AdminPanelSection.dashboard => Icons.space_dashboard_outlined,
      AdminPanelSection.users => Icons.people_outline_rounded,
      AdminPanelSection.payments => Icons.payments_outlined,
      AdminPanelSection.sales => Icons.badge_outlined,
      AdminPanelSection.saleConversions =>
        Icons.published_with_changes_outlined,
      AdminPanelSection.plans => Icons.workspace_premium_outlined,
      AdminPanelSection.reports => Icons.summarize_outlined,
      AdminPanelSection.audit => Icons.history_outlined,
      AdminPanelSection.config => Icons.tune_outlined,
    };
  }

  IconData get selectedIcon {
    return switch (this) {
      AdminPanelSection.dashboard => Icons.space_dashboard_rounded,
      AdminPanelSection.users => Icons.people_rounded,
      AdminPanelSection.payments => Icons.payments_rounded,
      AdminPanelSection.sales => Icons.badge_rounded,
      AdminPanelSection.saleConversions => Icons.published_with_changes_rounded,
      AdminPanelSection.plans => Icons.workspace_premium_rounded,
      AdminPanelSection.reports => Icons.summarize_rounded,
      AdminPanelSection.audit => Icons.history_rounded,
      AdminPanelSection.config => Icons.tune_rounded,
    };
  }

  List<_AdminAction> get actions {
    return switch (this) {
      AdminPanelSection.users => const [
        _AdminAction('active', 'Mo', Icons.lock_open_rounded),
        _AdminAction('suspended', 'Tam khoa', Icons.lock_rounded),
      ],
      AdminPanelSection.payments => const [
        _AdminAction('approve', 'Duyet', Icons.verified_rounded),
        _AdminAction('reject', 'Tu choi', Icons.block_rounded),
      ],
      AdminPanelSection.sales => const [
        _AdminAction('approve', 'Duyet', Icons.verified_user_rounded),
        _AdminAction('reject', 'Tu choi', Icons.block_rounded),
        _AdminAction('suspend', 'Tam dung', Icons.pause_circle_rounded),
      ],
      AdminPanelSection.saleConversions => const [
        _AdminAction('approve', 'Duyet', Icons.verified_rounded),
        _AdminAction('reject', 'Tu choi', Icons.block_rounded),
        _AdminAction('mark_paid', 'Da chi tra', Icons.payments_rounded),
      ],
      AdminPanelSection.plans => const [
        _AdminAction('upsert', 'Cap nhat', Icons.save_rounded),
      ],
      AdminPanelSection.reports => const [
        _AdminAction('export', 'Xuat', Icons.download_rounded),
      ],
      AdminPanelSection.config => const [
        _AdminAction('upsert', 'Luu phien ban', Icons.save_as_rounded),
      ],
      AdminPanelSection.dashboard => const [],
      AdminPanelSection.audit => const [],
    };
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.border),
  );
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') ||
      normalized.contains('reject') ||
      normalized.contains('suspend')) {
    return AppColors.error;
  }
  if (normalized.contains('pending') || normalized.contains('review')) {
    return AppColors.warning;
  }
  if (normalized.contains('active') ||
      normalized.contains('approved') ||
      normalized.contains('ready') ||
      normalized.contains('succeeded')) {
    return AppColors.success;
  }
  return AppColors.info;
}

IconData _statusIcon(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') || normalized.contains('reject')) {
    return Icons.error_outline_rounded;
  }
  if (normalized.contains('pending')) return Icons.pending_actions_rounded;
  return Icons.insights_rounded;
}
