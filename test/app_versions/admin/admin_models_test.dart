import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

void main() {
  group('AdminSession', () {
    test('maps roles and wildcard permissions', () {
      final session = AdminSession.fromMap({
        'user_id': 'admin-user',
        'roles': ['super_admin', 'finance_admin'],
        'permissions': ['*'],
        'is_active': true,
      });

      expect(session.isAdmin, isTrue);
      expect(session.roles, contains(AdminRoleCode.superAdmin));
      expect(session.hasPermission(AdminPermissions.paymentsWrite), isTrue);
      expect(session.hasPermission(AdminPermissions.configWrite), isTrue);
      expect(session.hasWildcardPermission, isTrue);
      expect(AdminPanelSection.values.every(session.canAccessSection), isTrue);
    });

    test('requires active role for admin access', () {
      final session = AdminSession.fromMap({
        'user_id': 'admin-user',
        'roles': ['operations_admin'],
        'permissions': [AdminPermissions.dashboardRead],
        'is_active': false,
      });

      expect(session.isAdmin, isFalse);
      expect(session.hasPermission(AdminPermissions.dashboardRead), isFalse);
      expect(session.canAccessSection(AdminPanelSection.dashboard), isFalse);
    });

    test('maps finance admin wildcard to all Admin surfaces', () {
      final session = _session(
        roles: const [AdminRoleCode.financeAdmin],
        permissions: const {AdminPermissions.wildcard},
      );

      expect(AdminPanelSection.values.every(session.canAccessSection), isTrue);
      expect(
        session.hasPermission(AdminPermissions.reconciliationWrite),
        isTrue,
      );
      expect(session.hasPermission(AdminPermissions.pointsWrite), isTrue);
    });

    test('maps operations admin wildcard to all Admin mutations', () {
      final session = _session(
        roles: const [AdminRoleCode.operationsAdmin],
        permissions: const {AdminPermissions.wildcard},
      );

      for (final section in AdminPanelSection.values) {
        expect(
          session.canAccessSection(section),
          isTrue,
          reason: section.value,
        );
      }
      expect(
        session.canRunMutation(
          const AdminMutationCommand(
            section: AdminPanelSection.payments,
            action: 'approve',
            targetId: 'payment-id',
            reason: 'Reviewed payment.',
            idempotencyKey: 'payment-id-1',
          ),
        ),
        isTrue,
      );
    });

    test('separates plan and system config permissions', () {
      final planAdmin = _session(
        roles: const [AdminRoleCode.superAdmin],
        permissions: const {
          AdminPermissions.dashboardRead,
          AdminPermissions.plansWrite,
        },
      );
      final configAdmin = _session(
        roles: const [AdminRoleCode.superAdmin],
        permissions: const {
          AdminPermissions.dashboardRead,
          AdminPermissions.configWrite,
        },
      );

      expect(planAdmin.canAccessSection(AdminPanelSection.plans), isTrue);
      expect(planAdmin.canAccessSection(AdminPanelSection.config), isFalse);
      expect(configAdmin.canAccessSection(AdminPanelSection.config), isTrue);
      expect(configAdmin.canAccessSection(AdminPanelSection.plans), isFalse);
      expect(
        adminPermissionForSection(AdminPanelSection.plans),
        AdminPermissions.plansWrite,
      );
    });

    test('checks mutation permission with the same section mapping', () {
      final operations = _session(
        roles: const [AdminRoleCode.operationsAdmin],
        permissions: const {AdminPermissions.wildcard},
      );
      const saleCommand = AdminMutationCommand(
        section: AdminPanelSection.saleConversions,
        action: 'approve',
        targetId: 'conversion-id',
        reason: 'Reviewed conversion.',
        idempotencyKey: 'conversion-id-1',
      );
      const paymentCommand = AdminMutationCommand(
        section: AdminPanelSection.payments,
        action: 'approve',
        targetId: 'payment-id',
        reason: 'Reviewed payment.',
        idempotencyKey: 'payment-id-1',
      );

      expect(operations.canRunMutation(saleCommand), isTrue);
      expect(operations.canRunMutation(paymentCommand), isTrue);
      expect(
        adminPermissionForMutation(saleCommand),
        AdminPermissions.salesWrite,
      );
    });

    test('does not treat read-only sections as mutation surfaces', () {
      final dashboardAdmin = _session(
        roles: const [AdminRoleCode.superAdmin],
        permissions: const {AdminPermissions.dashboardRead},
      );
      const dashboardCommand = AdminMutationCommand(
        section: AdminPanelSection.dashboard,
        action: 'refresh',
        targetId: 'dashboard',
        reason: 'permission check',
        idempotencyKey: 'dashboard-1',
      );

      expect(
        adminSectionSupportsMutation(AdminPanelSection.dashboard),
        isFalse,
      );
      expect(adminSectionSupportsMutation(AdminPanelSection.audit), isFalse);
      expect(dashboardAdmin.canRunMutation(dashboardCommand), isFalse);
    });
  });

  group('AdminMutationCommand', () {
    test('uses Vietnam timezone for Admin dashboard defaults', () {
      expect(AdminTimeDefaults.vietnamTimeZone, 'Asia/Ho_Chi_Minh');
    });

    test('keeps reason and idempotency key explicit', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.payments,
        action: 'approve',
        targetId: 'payment-id',
        reason: 'Verified provider payment.',
        idempotencyKey: 'payments-payment-id-1',
      );

      expect(command.reason, isNotEmpty);
      expect(command.idempotencyKey, startsWith('payments-'));
    });

    test('maps Sale conversion queue to review RPC and params', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.saleConversions,
        action: 'mark_paid',
        targetId: 'conversion-id',
        reason: 'Finance confirmed payout.',
        idempotencyKey: 'sale-conversions-conversion-id-1',
      );

      expect(
        adminListRpcForSection(AdminPanelSection.saleConversions),
        'admin_list_sale_point_conversions',
      );
      expect(
        adminRpcFunctionFor(command),
        'admin_review_sale_point_conversion',
      );
      expect(adminRpcParamsFor(command), {
        'p_reason': 'Finance confirmed payout.',
        'p_idempotency_key': 'sale-conversions-conversion-id-1',
        'p_conversion_id': 'conversion-id',
        'p_decision': 'mark_paid',
      });
      expect(AdminRoutePaths.saleConversions, '/admin/sale-conversions');
    });

    test('maps reconciliation queue to status RPC and route', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.reconciliation,
        action: 'resolved',
        targetId: 'discrepancy-id',
        reason: 'Matched payment and point ledger.',
        idempotencyKey: 'reconciliation-discrepancy-id-1',
      );

      expect(
        adminListRpcForSection(AdminPanelSection.reconciliation),
        'admin_list_reconciliation_discrepancies',
      );
      expect(
        adminRpcFunctionFor(command),
        'admin_update_reconciliation_discrepancy_status',
      );
      expect(adminRpcParamsFor(command), {
        'p_reason': 'Matched payment and point ledger.',
        'p_idempotency_key': 'reconciliation-discrepancy-id-1',
        'p_discrepancy_id': 'discrepancy-id',
        'p_status': 'resolved',
      });
      expect(AdminRoutePaths.reconciliation, '/admin/reconciliation');
    });

    test('maps manual Sale point adjustment to audited RPC', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.saleConversions,
        action: 'adjust_points',
        targetId: 'sale-user-id',
        reason: 'Manual one-admin correction.',
        idempotencyKey: 'points-sale-user-id-1',
        payload: {'point_delta_cents': 1000},
      );

      expect(adminPermissionForMutation(command), AdminPermissions.pointsWrite);
      expect(adminRpcFunctionFor(command), 'admin_adjust_sale_points');
      expect(adminRpcParamsFor(command), {
        'p_reason': 'Manual one-admin correction.',
        'p_idempotency_key': 'points-sale-user-id-1',
        'p_sale_user_id': 'sale-user-id',
        'p_point_delta_cents': 1000,
      });
    });

    test('maps plan section to plan-scoped config RPC', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.plans,
        action: 'upsert',
        targetId: 'plan_plus',
        reason: 'Update package config.',
        idempotencyKey: 'plans-plan-plus-1',
      );

      expect(
        adminListRpcForSection(AdminPanelSection.plans),
        'admin_list_plan_config_versions',
      );
      expect(adminRpcFunctionFor(command), 'admin_upsert_config_version');
      expect(adminRpcParamsFor(command), {
        'p_reason': 'Update package config.',
        'p_idempotency_key': 'plans-plan-plus-1',
        'p_config_key': 'plan_plus',
        'p_config_value': {'action': 'upsert'},
      });
    });

    test('rejects read-only sections as mutation RPCs', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.audit,
        action: 'export',
        targetId: 'audit',
        reason: 'Invalid write.',
        idempotencyKey: 'audit-1',
      );

      expect(() => adminRpcFunctionFor(command), throwsUnsupportedError);
      expect(() => adminRpcParamsFor(command), throwsUnsupportedError);
    });
  });
}

AdminSession _session({
  required List<AdminRoleCode> roles,
  required Set<String> permissions,
}) {
  return AdminSession(
    userId: 'admin-user',
    roles: roles,
    permissions: permissions,
    active: true,
  );
}
