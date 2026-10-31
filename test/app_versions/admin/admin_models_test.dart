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
      expect(session.hasWildcardPermission, isTrue);
      expect(AdminPanelSection.values.every(session.canAccessSection), isTrue);
      expect(session.canUseUserApp, isTrue);
    });

    test('maps unified app access mode for dual and Admin-only accounts', () {
      final dual = AdminSession.fromMap({
        'user_id': 'dual-user',
        'roles': ['super_admin'],
        'permissions': ['*'],
        'is_active': true,
        'app_access_mode': 'both',
        'can_use_user_app': true,
      });
      final adminOnly = AdminSession.fromMap({
        'user_id': 'admin-only',
        'roles': ['super_admin'],
        'permissions': ['*'],
        'is_active': true,
        'app_access_mode': 'admin',
        'can_use_user_app': false,
      });

      expect(dual.canUseUserApp, isTrue);
      expect(adminOnly.canUseUserApp, isFalse);
    });

    test('requires active role for admin access', () {
      final session = AdminSession.fromMap({
        'user_id': 'admin-user',
        'roles': ['support_admin', 'content_admin', 'operations_admin'],
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

    test('hides payment review from Support even with a legacy wildcard', () {
      final session = _session(
        roles: const [AdminRoleCode.supportAdmin],
        permissions: const {AdminPermissions.wildcard},
      );

      expect(session.canAccessSection(AdminPanelSection.users), isTrue);
      expect(session.canAccessSection(AdminPanelSection.payments), isFalse);
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
        isFalse,
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
      expect(operations.canRunMutation(paymentCommand), isFalse);
      expect(
        adminPermissionForMutation(saleCommand),
        AdminPermissions.salesWrite,
      );
    });

    test(
      'keeps operations admin as legacy alias while adding support and content',
      () {
        final session = AdminSession.fromMap({
          'user_id': 'admin-user',
          'roles': ['support_admin', 'content_admin', 'operations_admin'],
          'permissions': ['*'],
          'is_active': true,
        });

        expect(session.roles, contains(AdminRoleCode.supportAdmin));
        expect(session.roles, contains(AdminRoleCode.contentAdmin));
        expect(session.roles, contains(AdminRoleCode.operationsAdmin));
        expect(session.hasWildcardPermission, isTrue);
        expect(session.hasPermission(AdminPermissions.paymentsWrite), isFalse);
      },
    );

    test('allows only Finance and Super Admins to review payments', () {
      for (final role in const [
        AdminRoleCode.superAdmin,
        AdminRoleCode.financeAdmin,
      ]) {
        final session = _session(
          roles: [role],
          permissions: const {AdminPermissions.paymentsWrite},
        );
        expect(session.canAccessSection(AdminPanelSection.payments), isTrue);
      }

      for (final role in const [
        AdminRoleCode.supportAdmin,
        AdminRoleCode.contentAdmin,
        AdminRoleCode.operationsAdmin,
      ]) {
        final session = _session(
          roles: [role],
          permissions: const {AdminPermissions.paymentsWrite},
        );
        expect(
          session.canAccessSection(AdminPanelSection.payments),
          isFalse,
          reason: role.value,
        );
      }
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
    test('preserves audit context for backend mutations', () {
      const command = AdminMutationCommand(
        section: AdminPanelSection.sales,
        action: 'approve',
        targetId: 'sale-user-1',
        reason: 'Đã đối chiếu thông tin.',
        idempotencyKey: 'sale-user-1-approve-1',
      );

      expect(command.reason, 'Đã đối chiếu thông tin.');
      expect(command.idempotencyKey, 'sale-user-1-approve-1');
      expect(command.targetId, 'sale-user-1');
    });
  });

  group('payment review contracts', () {
    test(
      'maps server-owned transfer details from the payment list response',
      () {
        final item = AdminWorkItem.fromMap({
          'id': 'payment-1',
          'title': 'Plus',
          'subtitle': 'Nguyen Van A',
          'status': 'pending_review',
          'section': 'payments',
          'created_at': '2026-07-31T08:00:00Z',
          'transfer_reference': 'NB12AB34CD56EF',
          'transfer_memo': 'NB12AB34CD56EF',
          'payer_full_name': 'Nguyễn Văn A',
          'billing_cycle': 'monthly',
          'amount_cents': 99000,
          'currency': 'VND',
          'transfer_confirmed_at': '2026-07-31T08:12:00Z',
        });

        final details = item.paymentReconciliation;
        expect(details, isNotNull);
        expect(details!.transferReference, 'NB12AB34CD56EF');
        expect(details.transferMemo, 'NB12AB34CD56EF');
        expect(details.payerFullName, 'Nguyễn Văn A');
        expect(details.billingCycle, 'monthly');
        expect(details.amountCents, 99000);
        expect(details.currency, 'VND');
        expect(
          details.transferConfirmedAt,
          DateTime.parse('2026-07-31T08:12:00Z'),
        );
      },
    );

    test(
      'allows a payment review only after customer confirmation or legacy pending',
      () {
        expect(adminPaymentStatusCanBeReviewed('pending_review'), isTrue);
        expect(adminPaymentStatusCanBeReviewed(' pending '), isTrue);
        expect(adminPaymentStatusCanBeReviewed('awaiting_transfer'), isFalse);
        expect(adminPaymentStatusCanBeReviewed('succeeded'), isFalse);
        expect(adminPaymentStatusCanBeReviewed('pending_reversal'), isFalse);
      },
    );

    test('normalizes an invalid negative payment alert count to zero', () {
      final alert = AdminPaymentReviewAlert.fromMap({
        'pending_review_count': -1,
      });

      expect(alert.pendingReviewCount, 0);
      expect(alert.hasPendingReviews, isFalse);
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
