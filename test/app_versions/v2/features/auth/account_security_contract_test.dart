import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Account security contract', () {
    test(
      'Flutter client uses Edge Function and never admin/service-role APIs',
      () {
        final source = File(
          'lib/services/supabase/auth/account_security_service.dart',
        ).readAsStringSync();

        expect(source, contains('functions.invoke'));
        expect(source, contains('AUTH_DELETE_ACCOUNT_FUNCTION'));
        expect(source, contains('delete-account'));
        expect(source, isNot(contains('auth.admin')));
        expect(source.toLowerCase(), isNot(contains('service_role')));
        expect(source.toLowerCase(), isNot(contains('service-role')));
      },
    );

    test(
      'settings page wires password, logout, deletion, and auth route return',
      () {
        final source = File(
          'lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart',
        ).readAsStringSync();

        expect(source, contains('updatePassword'));
        expect(source, contains('signOut'));
        expect(source, contains('requestAccountDeletion'));
        expect(source, contains("context.go('/v2/auth')"));
        expect(source, contains('invalidateUserScopedProviders'));
        expect(source, contains('Yêu cầu xóa tài khoản'));
      },
    );
  });
}
