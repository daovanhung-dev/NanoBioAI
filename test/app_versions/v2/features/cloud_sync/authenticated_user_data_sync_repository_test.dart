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

    test('pushes pending guest data then pulls cloud snapshot', () async {
      await AppPrefs.setPendingGuestUserId('guest-1');

      final remote = _FakeRemoteDatasource(
        currentUser: {'id': 'auth-1', 'onboarding_status': 'not_started'},
        pullSnapshot: _snapshot('auth-1', tableName: 'meal_plans'),
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
      expect(local.replacedUserId, 'auth-1');
      expect(local.removedLocalUserId, 'guest-1');
      expect(await AppPrefs.pendingGuestUserId(), isNull);

      final routeState = const AuthRouteStateResolver().resolve(
        session: const AuthSessionSnapshot(
          userId: 'auth-1',
          email: 'auth-1@nanobio.local',
          emailConfirmed: true,
        ),
        profile: AuthProfile.fromMap(remote.pullSnapshot!.user!),
        requiresEmailConfirmation: false,
      );
      expect(routeState.status, AuthRouteStatus.authenticatedReady);
    });

    test('cloud completed onboarding wins over pending guest cache', () async {
      await AppPrefs.setPendingGuestUserId('guest-1');

      final remote = _FakeRemoteDatasource(
        currentUser: {'id': 'auth-1', 'onboarding_status': 'completed'},
        pullSnapshot: _snapshot('auth-1', tableName: 'daily_health_tasks'),
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

    test('sync failure does not clear pending guest id', () async {
      await AppPrefs.setPendingGuestUserId('guest-1');

      final remote = _FakeRemoteDatasource(
        currentUser: {'id': 'auth-1', 'onboarding_status': 'not_started'},
        pullSnapshot: _snapshot('auth-1', tableName: 'meal_plans'),
        failPull: true,
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
    });
  });
}

UserDataSnapshot _snapshot(String userId, {required String tableName}) {
  return UserDataSnapshot(
    user: {
      'id': userId,
      'email': '$userId@nanobio.local',
      'subscription_tier': 'free',
      'onboarding_status': 'completed',
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

  final Map<String, Object?>? currentUser;
  final UserDataSnapshot? pullSnapshot;
  final bool failPull;

  UserDataSnapshot? pushedSnapshot;
  String? pushedAuthUserId;

  _FakeRemoteDatasource({
    required this.currentUser,
    required this.pullSnapshot,
    this.failPull = false,
  });

  @override
  Future<Map<String, Object?>?> currentUserRow() async => currentUser;

  @override
  Future<UserDataSnapshot?> pullCurrentUserSnapshot() async {
    if (failPull) throw StateError('pull failed');
    return pullSnapshot;
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
