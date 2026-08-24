import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin suspension is enforced in Supabase Auth and client profile checks', () {
    final build = File('docs/supabase/01_build_system.sql').readAsStringSync();
    final authDatasource = File(
      'lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart',
    ).readAsStringSync();
    final authRepository = File(
      'lib/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart',
    ).readAsStringSync();

    expect(build, contains("p_status in ('suspended', 'closed')"));
    expect(build, contains('banned_until'));
    expect(build, contains('delete from auth.sessions'));
    expect(authDatasource, contains('admin_status'));
    expect(authRepository, contains('AuthFailureCode.accountDisabled'));
    expect(authRepository, contains('Tài khoản bị khóa'));
  });
}
