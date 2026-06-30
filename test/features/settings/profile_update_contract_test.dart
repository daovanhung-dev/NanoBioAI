import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile update contract', () {
    test(
      'profile page writes local cache first then schedules authenticated sync',
      () {
        final source = File(
          'lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart',
        ).readAsStringSync();

        expect(source, contains('currentSupabaseUserIdOrNull'));
        expect(source, isNot(contains('CloudProfileUpdatePayload')));
        expect(source, contains('SettingsLocalDatasource().updateUserProfile'));
        expect(source, contains('invalidateUserScopedProviders'));
        expect(source, contains("label: 'Email', enabled: false"));

        final datasourceSource = File(
          'lib/app_versions/v1/features/settings/data/datasources/'
          'settings_local_datasource.dart',
        ).readAsStringSync();
        expect(
          datasourceSource,
          contains('LocalUserDataSyncDispatcher.requestImmediateSync'),
        );
      },
    );

    test('auth profile service is read-only for profile/onboarding sync', () {
      final source = File(
        'lib/services/supabase/auth/auth_profile_service.dart',
      ).readAsStringSync();

      expect(source, contains('String? get currentUserId'));
      expect(source, isNot(contains('CloudProfileUpdatePayload')));
      expect(source, isNot(contains('CloudOnboardingPayload')));
      expect(source, isNot(contains(".from('users')")));
      expect(source, isNot(contains(".from('health_profiles')")));
    });
  });
}
