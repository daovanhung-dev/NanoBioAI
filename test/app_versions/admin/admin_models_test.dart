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
      expect(session.hasPermission(AdminPermissions.dashboardRead), isTrue);
      expect(session.canAccessSection(AdminPanelSection.dashboard), isFalse);
    });

    test('maps finance admin permissions to payment/report surfaces', () {
      final session = _session(
        roles: const [AdminRoleCode.financeAdmin],
        permissions: const {
          AdminPermissions.dashboardRead,
          AdminPermissions.paymentsWrite,
          AdminPermissions.reportsWrite,
          AdminPermissions.auditRead,
        },
      );

      expect(session.canAccessSection(AdminPanelSection.dashboard), isTrue);
      expect(session.canAccessSection(AdminPanelSection.payments), isTrue);
      expect(session.canAccessSection(AdminPanelSection.reports), isTrue);
      expect(session.canAccessSection(AdminPanelSection.audit), isTrue);
      expect(session.canAccessSection(AdminPanelSection.users), isFalse);
      expect(session.canAccessSection(AdminPanelSection.sales), isFalse);
      expect(
        session.canAccessSection(AdminPanelSection.saleConversions),
        isFalse,
      );
      expect(session.canAccessSection(AdminPanelSection.config), isFalse);
      expect(session.canAccessSection(AdminPanelSection.plans), isFalse);
    });

    test('maps operations admin permissions to user and Sale surfaces', () {
      final session = _session(
        roles: const [AdminRoleCode.operationsAdmin],
        permissions: const {
          AdminPermissions.dashboardRead,
          AdminPermissions.usersWrite,
          AdminPermissions.salesWrite,
          AdminPermissions.auditRead,
        },
      );

      expect(session.canAccessSection(AdminPanelSection.dashboard), isTrue);
      expect(session.canAccessSection(AdminPanelSection.users), isTrue);
      expect(session.canAccessSection(AdminPanelSection.sales), isTrue);
      expect(
        session.canAccessSection(AdminPanelSection.saleConversions),
        isTrue,
      );
      expect(session.canAccessSection(AdminPanelSection.audit), isTrue);
      expect(session.canAccessSection(AdminPanelSection.payments), isFalse);
      expect(session.canAccessSection(AdminPanelSection.reports), isFalse);
      expect(session.canAccessSection(AdminPanelSection.config), isFalse);
      expect(session.canAccessSection(AdminPanelSection.plans), isFalse);
    });

    test('checks mutation permission with the same section mapping', () {
      final operations = _session(
        roles: const [AdminRoleCode.operationsAdmin],
        permissions: const {
          AdminPermissions.dashboardRead,
          AdminPermissions.usersWrite,
          AdminPermissions.salesWrite,
          AdminPermissions.auditRead,
        },
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
      expect(operations.canRunMutation(paymentCommand), isFalse);
      expect(
        adminPermissionForMutation(saleCommand),
        AdminPermissions.salesWrite,
      );
    });
  });

  group('AdminMutationCommand', () {
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
