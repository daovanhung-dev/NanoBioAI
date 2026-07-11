import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  test('sign in succeeds when post-auth cloud sync fails', () async {
    final authRepository = _FakeAuthRepository();
    final syncRepository = _FakeCloudSyncRepository(
      failReasons: {AuthSyncReason.signIn},
    );
    final container = ProviderContainer(
      overrides: [
        authBackendAvailabilityProvider.overrideWithValue(
          AuthBackendAvailability.ready,
        ),
        v2AuthRepositoryProvider.overrideWithValue(authRepository),
        authenticatedUserDataSyncRepositoryProvider.overrideWithValue(
          syncRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(v2AuthControllerProvider.future);

    await expectLater(
      container
          .read(v2AuthControllerProvider.notifier)
          .signInWithEmail(
            const LoginCommand(
              email: 'dev.free@nanobio.local',
              password: 'NanoBio@123456',
            ),
          ),
      completes,
    );

    final state = container.read(v2AuthControllerProvider).requireValue;
    expect(state.status, AuthRouteStatus.authenticatedReady);
    expect(syncRepository.reasons, [
      AuthSyncReason.authGateRefresh,
      AuthSyncReason.signIn,
    ]);
  });
}

class _FakeAuthRepository implements AuthRepository {
  var signedIn = false;

  @override
  Stream<void> watchAuthChanges() => const Stream<void>.empty();

  @override
  Future<AuthRouteState> resolveAuthRouteState() async {
    if (!signedIn) return const AuthRouteState.unauthenticated();
    return const AuthRouteState.authenticatedReady(
      userId: '10000000-0000-4000-8000-000000000101',
      email: 'dev.free@nanobio.local',
      subscriptionTier: 'free',
    );
  }

  @override
  Future<void> signInWithEmail(LoginCommand command) async {
    signedIn = true;
  }

  @override
  Future<RegistrationResult> signUpWithEmail(RegisterCommand command) async {
    signedIn = true;
    return RegistrationResult.sessionReady;
  }

  @override
  Future<void> recoverSessionFromUri(Uri uri) async {
    signedIn = true;
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

class _FakeCloudSyncRepository implements AuthenticatedUserDataSyncRepository {
  final Set<AuthSyncReason> failReasons;
  final reasons = <AuthSyncReason>[];

  _FakeCloudSyncRepository({this.failReasons = const {}});

  @override
  Future<CloudSyncResult> syncAfterAuthenticatedSession(
    AuthSyncReason reason,
  ) async {
    reasons.add(reason);
    if (failReasons.contains(reason)) {
      throw StateError('post-auth sync failed');
    }
    return CloudSyncResult(
      userId: '10000000-0000-4000-8000-000000000101',
      reason: reason,
      pushedLocalGuestData: false,
      pulledTables: const [],
    );
  }
}
