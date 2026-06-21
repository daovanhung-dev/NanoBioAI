import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';

void main() {
  group('Auth flow contract', () {
    test('v2 router uses shared auth route constants', () {
      expect(V2RoutePaths.authGate, AuthRoutePaths.authGate);
      expect(V2RoutePaths.login, AuthRoutePaths.login);
      expect(V2RoutePaths.register, AuthRoutePaths.register);
      expect(V2RoutePaths.verifyEmail, AuthRoutePaths.verifyEmail);
      expect(V2RoutePaths.authCallback, AuthRoutePaths.authCallback);
    });

    test('v1 auth entry and settings use shared auth route constants', () {
      final authEntrySource = File(
        'lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart',
      ).readAsStringSync();
      final settingsSource = File(
        'lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart',
      ).readAsStringSync();

      expect(authEntrySource, contains('AuthRoutePaths.login'));
      expect(authEntrySource, contains('AuthRoutePaths.register'));
      expect(authEntrySource, isNot(contains("'/v2/auth")));
      expect(settingsSource, contains('AuthRoutePaths.authGate'));
    });

    test('auth presentation delegates actions to controller provider', () {
      final source = File(
        'lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart',
      ).readAsStringSync();

      expect(source, contains('v2AuthControllerProvider'));
      expect(source, contains('v2AuthControllerProvider.notifier'));
      expect(source, isNot(contains('v2AuthRepositoryProvider')));
    });

    test('account route state is owned by Riverpod auth controller', () {
      final providersSource = File(
        'lib/app_versions/v2/features/auth/providers/auth_providers.dart',
      ).readAsStringSync();
      final controllerSource = File(
        'lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart',
      ).readAsStringSync();

      expect(
        providersSource,
        contains('AsyncNotifierProvider<AuthController, AuthRouteState>'),
      );
      expect(
        providersSource,
        contains('v2AuthRouteStateProvider = v2AuthControllerProvider'),
      );
      expect(
        controllerSource,
        contains('extends AsyncNotifier<AuthRouteState>'),
      );
      expect(controllerSource, contains('ref.watch(v2AuthChangesProvider)'));
      expect(controllerSource, contains('resolveAuthRouteState'));
      expect(
        controllerSource,
        contains('authenticatedUserDataSyncRepositoryProvider'),
      );
      expect(controllerSource, contains('AuthSyncReason.signIn'));
      expect(controllerSource, contains('AuthSyncReason.signUpSessionReady'));
      expect(controllerSource, contains('AuthSyncReason.authCallback'));
      expect(controllerSource, contains('RegistrationResult.sessionReady'));
    });

    test('Flutter auth client does not insert baseline profile rows', () {
      final authDatasourceSource = File(
        'lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart',
      ).readAsStringSync();
      final profileServiceSource = File(
        'lib/services/supabase/auth/auth_profile_service.dart',
      ).readAsStringSync();

      expect(authDatasourceSource, contains('subscription_tier'));
      expect(authDatasourceSource, isNot(contains(".from('users').insert")));
      expect(
        authDatasourceSource,
        isNot(contains(".from('health_profiles').insert")),
      );
      expect(
        authDatasourceSource,
        isNot(contains(".from('lifestyle_habits').insert")),
      );
      expect(profileServiceSource, isNot(contains(".from('users').insert")));
      expect(
        profileServiceSource,
        isNot(contains(".from('health_profiles').insert")),
      );
      expect(
        profileServiceSource,
        isNot(contains(".from('lifestyle_habits').insert")),
      );
    });
  });
}
