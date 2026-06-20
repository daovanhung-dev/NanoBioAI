import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile update contract', () {
    test(
      'profile page updates cloud first then mirrors local cache by auth UUID',
      () {
        final source = File(
          'lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart',
        ).readAsStringSync();

        expect(source, contains('currentSupabaseUserIdOrNull'));
        expect(source, contains('CloudProfileUpdatePayload'));
        expect(source, contains('AuthProfileService().updateProfile'));
        expect(source, contains('SettingsLocalDatasource().updateUserProfile'));
        expect(source, contains('invalidateUserScopedProviders'));
        expect(source, contains("label: 'Email', enabled: false"));
      },
    );

    test(
      'cloud profile service updates scoped users and health profile rows',
      () {
        final source = File(
          'lib/services/supabase/auth/auth_profile_service.dart',
        ).readAsStringSync();

        expect(source, contains('CloudProfileUpdatePayload'));
        expect(source, contains(".from('users')"));
        expect(source, contains(".from('health_profiles')"));
        expect(source, contains(".eq('id', userId)"));
        expect(source, contains(".eq('user_id', userId)"));
      },
    );
  });
}
