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
