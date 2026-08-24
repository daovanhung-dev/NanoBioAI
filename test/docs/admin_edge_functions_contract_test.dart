import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Admin privileged writes stay behind authenticated Edge Functions', () {
    final config = File('supabase/config.toml').readAsStringSync();
    final createIndex = File(
      'supabase/functions/admin-create-account/index.ts',
    ).readAsStringSync();
    final grantIndex = File(
      'supabase/functions/admin-grant-membership/index.ts',
    ).readAsStringSync();
    final datasource = File(
      'lib/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart',
    ).readAsStringSync();

    for (final functionName in [
      'admin-create-account',
      'admin-grant-membership',
    ]) {
      expect(config, contains('[functions.$functionName]'));
    }
    expect(RegExp(r'verify_jwt = true').allMatches(config).length, greaterThanOrEqualTo(3));

    expect(createIndex, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(createIndex, contains('auth.admin.createUser'));
    expect(createIndex, contains('admin_create_account'));
    expect(createIndex, contains('support_admin'));
    expect(createIndex, contains('super_admin'));

    expect(grantIndex, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(grantIndex, contains('hasActiveAdminRole(actorId, ["super_admin"])'));
    expect(grantIndex, contains('source: "manual"'));
    expect(grantIndex, contains('provider: "admin_manual"'));
    expect(grantIndex, contains('admin_grant_membership'));

    expect(datasource, contains("functions.invoke('admin-create-account'"));
    expect(datasource, contains("functions.invoke('admin-grant-membership'"));
    expect(datasource, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
  });
}
