import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRouter = GoRouter(
  initialLocation: AdminRoutePaths.dashboard,
  redirect: (context, state) {
    final isLogin = state.uri.path == AdminRoutePaths.login;
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    if (!hasSession && !isLogin) return AdminRoutePaths.login;
    if (hasSession && isLogin) return AdminRoutePaths.dashboard;
    if (state.uri.path == AdminRoutePaths.root) {
      return AdminRoutePaths.dashboard;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AdminRoutePaths.login,
      name: AdminRoutePaths.login,
      builder: (context, state) => const AdminLoginPage(),
    ),
    GoRoute(
      path: AdminRoutePaths.dashboard,
      name: AdminRoutePaths.dashboard,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.dashboard),
    ),
    GoRoute(
      path: AdminRoutePaths.users,
      name: AdminRoutePaths.users,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.users),
    ),
    GoRoute(
      path: AdminRoutePaths.payments,
      name: AdminRoutePaths.payments,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.payments),
    ),
    GoRoute(
      path: AdminRoutePaths.sales,
      name: AdminRoutePaths.sales,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.sales),
    ),
    GoRoute(
      path: AdminRoutePaths.saleConversions,
      name: AdminRoutePaths.saleConversions,
      builder: (context, state) => const AdminShellPage(
        initialSection: AdminPanelSection.saleConversions,
      ),
    ),
    GoRoute(
      path: AdminRoutePaths.plans,
      name: AdminRoutePaths.plans,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.plans),
    ),
    GoRoute(
      path: AdminRoutePaths.reports,
      name: AdminRoutePaths.reports,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.reports),
    ),
    GoRoute(
      path: AdminRoutePaths.audit,
      name: AdminRoutePaths.audit,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.audit),
    ),
    GoRoute(
      path: AdminRoutePaths.config,
      name: AdminRoutePaths.config,
      builder: (context, state) =>
          const AdminShellPage(initialSection: AdminPanelSection.config),
    ),
  ],
);
