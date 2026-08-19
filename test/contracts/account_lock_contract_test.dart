import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin suspension is enforced in Supabase Auth and client profile checks', () {
    final migration = File(
      'docs/supabase/20260819_auth_account_lock.sql',
    ).readAsStringSync();
    final authDatasource = File(
      'lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart',
    ).readAsStringSync();
    final authRepository = File(
      'lib/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart',
    ).readAsStringSync();

    expect(migration, contains("p_status in ('suspended', 'closed')"));
    expect(migration, contains('banned_until'));
    expect(migration, contains('delete from auth.sessions'));
    expect(authDatasource, contains('admin_status'));
    expect(authRepository, contains('AuthFailureCode.accountDisabled'));
    expect(authRepository, contains('Tài khoản bị khóa'));
  });
}
