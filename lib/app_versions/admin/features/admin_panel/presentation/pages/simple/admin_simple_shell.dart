import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

class AdminSimpleShell extends ConsumerWidget {
  final String selectedPath;
  final String title;
  final Widget child;

  const AdminSimpleShell({
    required this.selectedPath,
    required this.title,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(adminAccessControllerProvider).asData?.value;
    final session = access?.session;
    final destinations = _destinations.where((item) => item.allowed(session)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await ref.read(adminAccessControllerProvider.notifier).signOut();
                  if (context.mounted) context.go(AdminRoutePaths.login);
                },
                icon: const Icon(Icons.logout_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: compact
              ? Drawer(
                  child: SafeArea(
                    child: _AdminNavigation(
                      destinations: destinations,
                      selectedPath: selectedPath,
                      onSelect: (path) {
                        Navigator.pop(context);
                        context.go(path);
                      },
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                SizedBox(
                  width: 250,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: SafeArea(
                      top: false,
                      child: _AdminNavigation(
                        destinations: destinations,
                        selectedPath: selectedPath,
                        onSelect: context.go,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 28,
                          20,
                          compact ? 16 : 28,
                          36,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminNavigation extends StatelessWidget {
  final List<_AdminDestination> destinations;
  final String selectedPath;
  final ValueChanged<String> onSelect;

  const _AdminNavigation({
    required this.destinations,
    required this.selectedPath,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.admin_panel_settings_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NanoBio Admin', style: Theme.of(context).textTheme.titleMedium),
                  Text('6 công việc chính', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    String? lastGroup;
    for (final item in destinations) {
      if (lastGroup != item.group) {
        lastGroup = item.group;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
            child: Text(
              item.group.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
          ),
        );
      }
      final selected = selectedPath == item.path;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Icon(selected ? item.selectedIcon : item.icon),
              title: Text(item.label),
              selected: selected,
              onTap: () => onSelect(item.path),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
      children: widgets,
    );
  }
}

class _AdminDestination {
  final String group;
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final bool Function(AdminSession? session) allowed;

  const _AdminDestination({
    required this.group,
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.allowed,
  });
}

final _destinations = <_AdminDestination>[
  _AdminDestination(
    group: 'Tài khoản',
    label: 'Tạo tài khoản',
    path: AdminRoutePaths.createAccount,
    icon: Icons.person_add_alt_outlined,
    selectedIcon: Icons.person_add_alt_1_rounded,
    allowed: (session) =>
        session?.roles.contains(AdminRoleCode.superAdmin) == true ||
        session?.roles.contains(AdminRoleCode.supportAdmin) == true,
  ),
  _AdminDestination(
    group: 'Tài khoản',
    label: 'Nâng cấp tài khoản',
    path: AdminRoutePaths.upgradeAccount,
    icon: Icons.workspace_premium_outlined,
    selectedIcon: Icons.workspace_premium_rounded,
    allowed: (session) => session?.roles.contains(AdminRoleCode.superAdmin) == true,
  ),
  _AdminDestination(
    group: 'Tài khoản',
    label: 'Quản trị tài khoản',
    path: AdminRoutePaths.accounts,
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts_rounded,
    allowed: (session) => session?.hasPermission(AdminPermissions.usersWrite) == true,
  ),
  _AdminDestination(
    group: 'Sale',
    label: 'Duyệt Sale',
    path: AdminRoutePaths.saleReview,
    icon: Icons.how_to_reg_outlined,
    selectedIcon: Icons.how_to_reg_rounded,
    allowed: (session) => session?.hasPermission(AdminPermissions.salesWrite) == true,
  ),
  _AdminDestination(
    group: 'Sale',
    label: 'Thanh toán Sale',
    path: AdminRoutePaths.salePayouts,
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    allowed: (session) => session?.hasPermission(AdminPermissions.salesWrite) == true,
  ),
  _AdminDestination(
    group: 'Thành viên',
    label: 'Duyệt nâng cấp gói',
    path: AdminRoutePaths.membershipReview,
    icon: Icons.verified_outlined,
    selectedIcon: Icons.verified_rounded,
    allowed: (session) => session?.canReviewMembershipPayments == true,
  ),
];
