import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

final adminRouter = GoRouter(
  initialLocation: AdminRoutePaths.dashboard,
  redirect: (context, state) {
    if (state.uri.path == AdminRoutePaths.root) {
      return AdminRoutePaths.dashboard;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AdminRoutePaths.login,
      name: AdminRoutePaths.login,
      pageBuilder: (context, state) => _adminPage(
        state: state,
        child: const AdminLoginPage(),
      ),
    ),
    _protected(AdminRoutePaths.dashboard, AdminPanelSection.dashboard),
    _protected(AdminRoutePaths.users, AdminPanelSection.users),
    _protected(AdminRoutePaths.payments, AdminPanelSection.payments),
    _protected(AdminRoutePaths.sales, AdminPanelSection.sales),
    _protected(
      AdminRoutePaths.saleConversions,
      AdminPanelSection.saleConversions,
    ),
    _protected(
      AdminRoutePaths.wellnessRewards,
      AdminPanelSection.wellnessRewards,
    ),
    _protected(
      AdminRoutePaths.reconciliation,
      AdminPanelSection.reconciliation,
    ),
    _protected(AdminRoutePaths.plans, AdminPanelSection.plans),
    _protected(AdminRoutePaths.reports, AdminPanelSection.reports),
    _protected(AdminRoutePaths.audit, AdminPanelSection.audit),
    _protected(AdminRoutePaths.config, AdminPanelSection.config),
  ],
);

GoRoute _protected(String path, AdminPanelSection section) {
  return GoRoute(
    path: path,
    name: path,
    pageBuilder: (context, state) => _adminPage(
      state: state,
      child: AdminAccessGate(
        child: AdminWorkspacePage(initialSection: section),
      ),
    ),
  );
}

CustomTransitionPage<void> _adminPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final offset = Tween<Offset>(
        begin: const Offset(0, .008),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
