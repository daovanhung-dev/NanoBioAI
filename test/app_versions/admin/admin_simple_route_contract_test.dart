import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

void main() {
  test('Admin exposes exactly the six simplified work destinations', () {
    expect(AdminRoutePaths.accounts, '/admin/accounts');
    expect(AdminRoutePaths.createAccount, '/admin/accounts/create');
    expect(AdminRoutePaths.upgradeAccount, '/admin/accounts/upgrade');
    expect(AdminRoutePaths.saleReview, '/admin/sales/review');
    expect(AdminRoutePaths.salePayouts, '/admin/sales/payouts');
    expect(AdminRoutePaths.membershipReview, '/admin/memberships/review');
  });

  test('router keeps legacy Admin URLs as redirects and gates new pages', () {
    final source = File(
      'lib/app_versions/admin/router/admin_router.dart',
    ).readAsStringSync();

    for (final path in [
      'AdminRoutePaths.accounts',
      'AdminRoutePaths.createAccount',
      'AdminRoutePaths.upgradeAccount',
      'AdminRoutePaths.saleReview',
      'AdminRoutePaths.salePayouts',
      'AdminRoutePaths.membershipReview',
    ]) {
      expect(source, contains('_protected($path'));
    }
    expect(source, contains('AdminAccessGate(child: child)'));
    expect(source, contains('_legacy(AdminRoutePaths.dashboard, AdminRoutePaths.accounts)'));
    expect(source, contains('_legacy(AdminRoutePaths.payments, AdminRoutePaths.membershipReview)'));
    expect(source, contains('_legacy(AdminRoutePaths.saleConversions, AdminRoutePaths.salePayouts)'));
  });

  test('simplified shell contains only six destination definitions', () {
    final source = File(
      'lib/app_versions/admin/features/admin_panel/presentation/pages/simple/admin_simple_shell.dart',
    ).readAsStringSync();

    expect(RegExp(r'\n  _AdminDestination\(').allMatches(source).length, 6);
    expect(source, isNot(contains('ĐỐI SOÁT')));
    expect(source, isNot(contains('BÁO CÁO')));
    expect(source, isNot(contains('CẤU HÌNH')));
  });
}
