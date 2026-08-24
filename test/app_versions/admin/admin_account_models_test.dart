import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_account_models.dart';

void main() {
  group('AdminAccountSummary', () {
    test('maps account, access and subscription details defensively', () {
      final account = AdminAccountSummary.fromMap({
        'id': 'user-1',
        'display_name': 'Nguyễn Văn A',
        'email': 'a@example.com',
        'phone': '0912345678',
        'account_status': 'active',
        'plan_code': 'plus',
        'sale_status': 'pending',
        'created_at': '2026-08-24T00:00:00.000Z',
        'subscription_status': 'active',
        'subscription_starts_at': '2026-08-24T00:00:00.000Z',
        'subscription_ends_at': '2026-09-24T00:00:00.000Z',
      });

      expect(account.id, 'user-1');
      expect(account.displayName, 'Nguyễn Văn A');
      expect(account.planCode, 'plus');
      expect(account.saleStatus, 'pending');
      expect(account.subscriptionStatus, 'active');
      expect(account.subscriptionEndsAt, isNotNull);
    });

    test('falls back to safe defaults for sparse search results', () {
      final account = AdminAccountSummary.fromMap({'id': 'user-2'});

      expect(account.id, 'user-2');
      expect(account.displayName, 'Tài khoản');
      expect(account.accountStatus, 'active');
      expect(account.planCode, 'free');
      expect(account.saleStatus, 'none');
    });
  });

  group('Admin membership commands', () {
    test('keep reason and idempotency explicit', () {
      final request = AdminMembershipGrantRequest(
        userId: 'user-1',
        planCode: 'family_plus',
        startsAt: DateTime.utc(2026, 8, 24),
        endsAt: DateTime.utc(2026, 9, 24),
        reason: 'Phê duyệt nội bộ.',
        idempotencyKey: 'grant-1',
      );

      expect(request.reason, isNotEmpty);
      expect(request.idempotencyKey, 'grant-1');
      expect(request.endsAt.isAfter(request.startsAt), isTrue);
    });
  });
}
