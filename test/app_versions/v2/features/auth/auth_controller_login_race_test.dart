import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  test('auth stream event during sign in does not rebuild auth route state', () async {
    final authChanges = StreamController<String?>.broadcast();
    final repository = _RaceAuthRepository(
      onSignInEvent: () => authChanges.add('session-user-id'),
    );
    final syncRepository = _NoopCloudSyncRepository();

    final container = ProviderContainer(
      overrides: [
        authBackendAvailabilityProvider.overrideWithValue(
          AuthBackendAvailability.ready,
        ),
        v2AuthRepositoryProvider.overrideWithValue(repository),
        authenticatedUserDataSyncRepositoryProvider.overrideWithValue(
          syncRepository,
        ),
        v2AuthChangesProvider.overrideWith((ref) => authChanges.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await authChanges.close();
    });

    await container.read(v2AuthControllerProvider.future);
    expect(repository.resolveCalls, 1);

    await container
        .read(v2AuthControllerProvider.notifier)
        .signInWithEmail(
          const LoginCommand(
            email: 'dev.free@nanobio.local',
            password: 'NanoBio@123456',
          ),
        );
    await Future<void>.delayed(Duration.zero);

    final state = container.read(v2AuthControllerProvider).requireValue;
    expect(state.status, AuthRouteStatus.authenticatedReady);
    expect(container.read(currentAuthUserIdProvider), 'session-user-id');

    // Initial build + the explicit post-sign-in resolve. The auth stream event
    // must not create a third competing resolve while sign-in is in flight.
    expect(repository.resolveCalls, 2);
  });
}

class _RaceAuthRepository implements AuthRepository {
  _RaceAuthRepository({required this.onSignInEvent});

  final void Function() onSignInEvent;
  bool signedIn = false;
  int resolveCalls = 0;

  @override
  Stream<String?> watchAuthChanges() => const Stream<String?>.empty();

  @override
  Future<AuthRouteState> resolveAuthRouteState() async {
    resolveCalls++;
    if (!signedIn) return const AuthRouteState.unauthenticated();
    return const AuthRouteState.authenticatedReady(
      userId: 'session-user-id',
      email: 'dev.free@nanobio.local',
      subscriptionTier: 'free',
    );
  }

  @override
  Future<void> signInWithEmail(LoginCommand command) async {
    onSignInEvent();
    await Future<void>.delayed(Duration.zero);
    signedIn = true;
  }

  @override
  Future<RegistrationResult> signUpWithEmail(RegisterCommand command) async {
    signedIn = true;
    return RegistrationResult.sessionReady;
  }

  @override
  Future<AuthCallbackResult> recoverSessionFromUri(Uri uri) async {
    signedIn = true;
    return const AuthCallbackResult.emailConfirmation();
  }

  @override
  Future<void> requestAccountDeletion() async {}

  @override
  Future<void> resendEmailConfirmation(String email) async {}

  @override
  Future<void> sendPasswordRecovery(String email) async {}

  @override
  Future<void> signOut() async {
    signedIn = false;
  }

  @override
  Future<void> updatePassword(UpdatePasswordCommand command) async {}
}

class _NoopCloudSyncRepository implements AuthenticatedUserDataSyncRepository {
  @override
  Future<UserDataSyncOutcome> syncAfterAuthenticatedSession(
    AuthSyncReason reason, {
    GuestMergeAction? guestAction,
  }) async {
    return CloudSyncResult(
      userId: 'session-user-id',
      reason: reason,
      pushedLocalGuestData: false,
      pulledTables: const [],
    );
  }
}
