import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_accounts_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_create_account_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_membership_review_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_sale_payout_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_sale_review_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_upgrade_account_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

final adminRouter = GoRouter(
  initialLocation: AdminRoutePaths.accounts,
  redirect: (context, state) {
    if (state.uri.path == AdminRoutePaths.root) return AdminRoutePaths.accounts;
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
    _protected(AdminRoutePaths.accounts, const AdminAccountsPage()),
    _protected(AdminRoutePaths.createAccount, const AdminCreateAccountPage()),
    _protected(AdminRoutePaths.upgradeAccount, const AdminUpgradeAccountPage()),
    _protected(AdminRoutePaths.saleReview, const AdminSaleReviewPage()),
    _protected(AdminRoutePaths.salePayouts, const AdminSalePayoutPage()),
    _protected(
      AdminRoutePaths.membershipReview,
      const AdminMembershipReviewPage(),
    ),
    _legacy(AdminRoutePaths.dashboard, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.users, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.payments, AdminRoutePaths.membershipReview),
    _legacy(AdminRoutePaths.sales, AdminRoutePaths.saleReview),
    _legacy(AdminRoutePaths.saleConversions, AdminRoutePaths.salePayouts),
    _legacy(AdminRoutePaths.wellnessRewards, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.reconciliation, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.plans, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.reports, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.audit, AdminRoutePaths.accounts),
    _legacy(AdminRoutePaths.config, AdminRoutePaths.accounts),
  ],
);

GoRoute _protected(String path, Widget child) {
  return GoRoute(
    path: path,
    name: path,
    pageBuilder: (context, state) => _adminPage(
      state: state,
      child: AdminAccessGate(child: child),
    ),
  );
}

GoRoute _legacy(String path, String target) {
  return GoRoute(path: path, redirect: (_, __) => target);
}

CustomTransitionPage<void> _adminPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final offset = Tween<Offset>(
        begin: const Offset(0, .006),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
