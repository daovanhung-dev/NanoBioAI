import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_datasource_contracts.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/repositories/authenticated_user_data_sync_repository_impl.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/cloud_sync_result.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/user_data_snapshot.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthenticatedUserDataSyncRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'pushes Guest onboarding only to a fresh cloud account, then pulls',
      () async {
        await AppPrefs.setPendingGuestUserId('guest-1');

        final remote = _FakeRemoteDatasource(
          pullSnapshots: [
            _freshSnapshot('auth-1'),
            _snapshot('auth-1', tableName: 'meal_plans'),
          ],
        );
        final local = _FakeLocalDatasource({
          'guest-1': _snapshot('guest-1', tableName: 'meal_plans'),
        });
        final repository = AuthenticatedUserDataSyncRepositoryImpl(
          remoteDatasource: remote,
          localDatasource: local,
        );

        final result = await repository.syncAfterAuthenticatedSession(
          AuthSyncReason.signUpSessionReady,
        );

        expect(result.pushedLocalGuestData, isTrue);
        expect(result.userId, 'auth-1');
        expect(remote.pushedSnapshot?.user?['id'], 'guest-1');
        expect(remote.pushedAuthUserId, 'auth-1');
        expect(local.replacedUserId, 'auth-1');
        expect(local.removedLocalUserId, 'guest-1');
        expect(await AppPrefs.pendingGuestUserId(), isNull);

        final routeState = const AuthRouteStateResolver().resolve(
          session: const AuthSessionSnapshot(
            userId: 'auth-1',
            email: 'auth-1@nanobio.local',
            emailConfirmed: true,
          ),
          profile: AuthProfile.fromMap(remote.lastSnapshot!.user!),
          requiresEmailConfirmation: false,
        );
        expect(routeState.status, AuthRouteStatus.authenticatedReady);
      },
    );

    test('cloud completed onboarding wins over pending Guest cache', () async {
      await AppPrefs.setPendingGuestUserId('guest-1');

      final remote = _FakeRemoteDatasource(
        pullSnapshots: [_snapshot('auth-1', tableName: 'daily_health_tasks')],
      );
      final local = _FakeLocalDatasource({
        'guest-1': _snapshot('guest-1', tableName: 'meal_plans'),
      });
      final repository = AuthenticatedUserDataSyncRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

      final result = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.signIn,
      );

      expect(result.pushedLocalGuestData, isFalse);
      expect(remote.pushedSnapshot, isNull);
      expect(local.replacedUserId, 'auth-1');
      expect(local.removedLocalUserId, 'guest-1');
      expect(await AppPrefs.pendingGuestUserId(), isNull);
    });

    test(
      'existing cloud data wins even before onboarding is marked completed',
      () async {
        await AppPrefs.setPendingGuestUserId('guest-1');

        final remote = _FakeRemoteDatasource(
          pullSnapshots: [
            _snapshot(
              'auth-1',
              tableName: 'health_profiles',
              onboardingStatus: 'in_progress',
            ),
          ],
        );
        final local = _FakeLocalDatasource({
          'guest-1': _snapshot('guest-1', tableName: 'meal_plans'),
        });
        final repository = AuthenticatedUserDataSyncRepositoryImpl(
          remoteDatasource: remote,
          localDatasource: local,
        );

        await repository.syncAfterAuthenticatedSession(AuthSyncReason.signIn);

        expect(remote.pushedSnapshot, isNull);
        expect(local.replacedUserId, 'auth-1');
        expect(await AppPrefs.isOnboardingCompleted(), isFalse);
      },
    );

    test(
      'sync failure after Guest upload does not clear pending Guest id',
      () async {
        await AppPrefs.setPendingGuestUserId('guest-1');

        final remote = _FakeRemoteDatasource(
          pullSnapshots: [_freshSnapshot('auth-1')],
          failFromPull: 2,
        );
        final local = _FakeLocalDatasource({
          'guest-1': _snapshot('guest-1', tableName: 'meal_plans'),
        });
        final repository = AuthenticatedUserDataSyncRepositoryImpl(
          remoteDatasource: remote,
          localDatasource: local,
        );

        await expectLater(
          repository.syncAfterAuthenticatedSession(AuthSyncReason.signIn),
          throwsStateError,
        );

        expect(remote.pushedSnapshot, isNotNull);
        expect(await AppPrefs.pendingGuestUserId(), 'guest-1');
      },
    );
  });
}

UserDataSnapshot _freshSnapshot(String userId) {
  return UserDataSnapshot(
    user: {
      'id': userId,
      'email': '$userId@nanobio.local',
      'subscription_tier': 'free',
      'onboarding_status': 'not_started',
    },
    tables: const {},
  );
}

UserDataSnapshot _snapshot(
  String userId, {
  required String tableName,
  String onboardingStatus = 'completed',
}) {
  return UserDataSnapshot(
    user: {
      'id': userId,
      'email': '$userId@nanobio.local',
      'subscription_tier': 'free',
      'onboarding_status': onboardingStatus,
    },
    tables: {
      tableName: [
        {'id': '$tableName-1', 'user_id': userId},
      ],
    },
  );
}

class _FakeRemoteDatasource implements UserDataSyncRemoteDatasource {
  @override
  final String? currentUserId = 'auth-1';

  final List<UserDataSnapshot?> pullSnapshots;
  final int? failFromPull;
  int _pullCalls = 0;

  UserDataSnapshot? pushedSnapshot;
  String? pushedAuthUserId;

  _FakeRemoteDatasource({required this.pullSnapshots, this.failFromPull});

  UserDataSnapshot? get lastSnapshot => pullSnapshots.isEmpty
      ? null
      : pullSnapshots[(pullSnapshots.length - 1)
            .clamp(0, pullSnapshots.length - 1)
            .toInt()];

  @override
  Future<Map<String, Object?>?> currentUserRow() async => lastSnapshot?.user;

  @override
  Future<UserDataSnapshot?> pullCurrentUserSnapshot() async {
    _pullCalls += 1;
    if (failFromPull != null && _pullCalls >= failFromPull!) {
      throw StateError('pull failed');
    }
    if (pullSnapshots.isEmpty) return null;
    final index = (_pullCalls - 1).clamp(0, pullSnapshots.length - 1).toInt();
    return pullSnapshots[index];
  }

  @override
  Future<void> replaceCloudWithLocalSnapshot(
    UserDataSnapshot localSnapshot,
    String authUserId,
  ) async {
    pushedSnapshot = localSnapshot;
    pushedAuthUserId = authUserId;
  }
}

class _FakeLocalDatasource implements UserDataSyncLocalDatasource {
  final Map<String, UserDataSnapshot> snapshots;

  String? replacedUserId;
  String? removedLocalUserId;

  _FakeLocalDatasource(this.snapshots);

  @override
  Future<UserDataSnapshot?> readSnapshot(String userId) async {
    return snapshots[userId];
  }

  @override
  Future<void> replaceFromCloud({
    required String userId,
    required UserDataSnapshot snapshot,
    String? removeLocalUserId,
  }) async {
    replacedUserId = userId;
    removedLocalUserId = removeLocalUserId;
  }
}
