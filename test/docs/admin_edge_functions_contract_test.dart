import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Admin privileged writes stay behind authenticated Edge Functions', () {
    final config = File('docs/archive/legacy-supabase/project/config.toml').readAsStringSync();
    final createIndex = File(
      'docs/archive/legacy-supabase/project/functions/admin-create-account/index.ts',
    ).readAsStringSync();
    final grantIndex = File(
      'docs/archive/legacy-supabase/project/functions/admin-grant-membership/index.ts',
    ).readAsStringSync();
    final bulkGrantIndex = File(
      'docs/archive/legacy-supabase/project/functions/admin-grant-membership-bulk/index.ts',
    ).readAsStringSync();
    final bulkGrantHandler = File(
      'docs/archive/legacy-supabase/project/functions/admin-grant-membership-bulk/handler.ts',
    ).readAsStringSync();
    final adjustIndex = File(
      'docs/archive/legacy-supabase/project/functions/admin-adjust-membership-period/index.ts',
    ).readAsStringSync();
    final adjustHandler = File(
      'docs/archive/legacy-supabase/project/functions/admin-adjust-membership-period/handler.ts',
    ).readAsStringSync();
    final datasource = File(
      'lib/app_versions/admin/features/admin_panel/data/datasources/admin_backend_datasource.dart',
    ).readAsStringSync();

    for (final functionName in [
      'admin-create-account',
      'admin-grant-membership',
      'admin-grant-membership-bulk',
      'admin-adjust-membership-period',
    ]) {
      expect(config, contains('[functions.$functionName]'));
    }
    expect(
      RegExp(r'verify_jwt = true').allMatches(config).length,
      greaterThanOrEqualTo(4),
    );

    expect(createIndex, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(createIndex, contains('auth.admin.createUser'));
    expect(createIndex, contains('admin_create_account'));
    expect(createIndex, contains('support_admin'));
    expect(createIndex, contains('super_admin'));

    expect(grantIndex, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(
      grantIndex,
      contains('hasActiveAdminRole(actorId, ["super_admin"])'),
    );
    expect(grantIndex, contains('source: "manual"'));
    expect(grantIndex, contains('provider: "admin_manual"'));
    expect(grantIndex, contains('admin_grant_membership'));

    expect(bulkGrantIndex, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(
      bulkGrantIndex,
      contains('hasActiveAdminRole(actorId, ["super_admin"])'),
    );
    expect(bulkGrantIndex, contains('admin_grant_membership_bulk'));
    expect(bulkGrantHandler, contains('all_registered'));
    expect(bulkGrantHandler, contains('endsAt: null'));
    expect(bulkGrantHandler, contains('idempotency_key'));

    expect(adjustIndex, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(adjustIndex, contains('admin_adjust_membership_period'));
    expect(adjustIndex, contains('hasActiveAdminRole'));
    expect(adjustIndex, contains('role_code'));
    expect(adjustIndex, contains("admin_status === \"active\""));
    for (final token in [
      'expected_ends_at',
      'idempotency_key',
      'add_days',
      'subtract_days',
      'set_end_at',
      'Chỉ Super Admin',
      'requestError',
    ]) {
      expect(adjustHandler, contains(token), reason: token);
    }

    expect(datasource, contains("'/api/v1/admin/accounts'"));
    expect(datasource, contains("'/api/v1/admin/memberships/grant'"));
    expect(datasource, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
  });
}
