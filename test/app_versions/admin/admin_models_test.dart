import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';

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
  });
}
