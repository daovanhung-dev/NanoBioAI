import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

void main() {
  test('Admin keeps six simplified destination path constants', () {
    expect(AdminRoutePaths.accounts, '/admin/accounts');
    expect(AdminRoutePaths.createAccount, '/admin/accounts/create');
    expect(AdminRoutePaths.upgradeAccount, '/admin/accounts/upgrade');
    expect(AdminRoutePaths.saleReview, '/admin/sales/review');
    expect(AdminRoutePaths.salePayouts, '/admin/sales/payouts');
    expect(AdminRoutePaths.membershipReview, '/admin/memberships/review');
  });

  test(
    'router protects all registered Admin destinations and redirects root',
    () {
      final source = File(
        'lib/app_versions/admin/router/admin_router.dart',
      ).readAsStringSync();

      for (final path in [
        'dashboard',
        'users',
        'payments',
        'sales',
        'saleConversions',
        'wellnessRewards',
        'reconciliation',
        'plans',
        'reports',
        'audit',
        'config',
      ]) {
        expect(
          RegExp(
            '_protected\\s*\\(\\s*AdminRoutePaths\\.$path',
          ).hasMatch(source),
          isTrue,
          reason: '$path is a protected route in the current router.',
        );
      }
      expect(RegExp(r'_protected\s*\(').allMatches(source).length, 12);
      expect(source, contains('child: AdminAccessGate('));
      expect(source, contains('state.uri.path == AdminRoutePaths.root'));
      expect(source, contains('return AdminRoutePaths.dashboard;'));
    },
  );

  test(
    'simplified navigation component contains six destination definitions',
    () {
      final source = File(
        'lib/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_simple_shell.dart',
      ).readAsStringSync();

      expect(RegExp(r'\n  _AdminDestination\(').allMatches(source).length, 6);
      expect(source, isNot(contains('ĐỐI SOÁT')));
      expect(source, isNot(contains('BÁO CÁO')));
      expect(source, isNot(contains('CẤU HÌNH')));
    },
  );
}
