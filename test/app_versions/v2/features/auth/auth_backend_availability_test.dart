import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  for (final availability in <AuthBackendAvailability>[
    AuthBackendAvailability.missingConfiguration,
    AuthBackendAvailability.initializationFailed,
  ]) {
    test('keeps auth controller safe when ${availability.name}', () async {
      final container = ProviderContainer(
        overrides: [
          authBackendAvailabilityProvider.overrideWithValue(availability),
        ],
      );
      addTearDown(container.dispose);

      final routeState = await container.read(v2AuthControllerProvider.future);
      expect(routeState.status, AuthRouteStatus.unauthenticated);

      expect(
        () => container.read(v2AuthRepositoryProvider),
        throwsA(
          predicate<Object>((error) {
            final description = error.toString();
            return description.contains(
                  authBackendUnavailableFailure(availability).userMessage,
                ) &&
                !description.contains('LateInitializationError');
          }, 'a guarded provider error without touching Supabase.instance'),
        ),
      );

      await expectLater(
        container
            .read(v2AuthControllerProvider.notifier)
            .signInWithEmail(
              const LoginCommand(
                email: 'nabi@example.com',
                password: '12345678',
              ),
            ),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.code,
            'code',
            AuthFailureCode.configuration,
          ),
        ),
      );
    });
  }
}
