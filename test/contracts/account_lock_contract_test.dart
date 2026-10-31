import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin suspension is enforced in backend auth and client profile checks',
    () {
      final build = File(
        'docs/archive/legacy-supabase/sql/01_build_system.sql',
      ).readAsStringSync();
      final authDatasource = File(
        'lib/app_versions/v2/features/auth/data/datasources/backend_auth_remote_datasource.dart',
      ).readAsStringSync();
      final authRepository = File(
        'lib/app_versions/v2/features/auth/data/repositories/backend_auth_repository.dart',
      ).readAsStringSync();

      expect(build, contains("p_status in ('suspended', 'closed')"));
      expect(build, contains('banned_until'));
      expect(build, contains('delete from auth.sessions'));
      expect(authDatasource, contains("'/api/v1/profile/me'"));
      expect(authRepository, contains('isAccessBlocked'));
      expect(authRepository, contains('AuthFailureCode.accountDisabled'));
      expect(authRepository, contains('Tài khoản bị khóa'));
    },
  );
}
