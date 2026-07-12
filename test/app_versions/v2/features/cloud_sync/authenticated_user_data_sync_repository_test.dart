import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_profile.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_datasource_contracts.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/repositories/authenticated_user_data_sync_repository_impl.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/cloud_sync_result.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/user_data_snapshot.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

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
          outbox: _FakeOutbox(),
        );

        final result = await repository.syncAfterAuthenticatedSession(
          AuthSyncReason.signUpSessionReady,
          guestAction: GuestMergeAction.mergeNow,
        );

        expect(result.pushedLocalGuestData, isTrue);
        expect(result.userId, 'auth-1');
        expect(remote.pushedSnapshot?.user?['id'], 'guest-1');
        expect(remote.pushedAuthUserId, 'auth-1');
        expect(local.replacedUserId, 'auth-1');
        expect(local.removedLocalUserId, 'guest-1');
        expect(await AppPrefs.pendingGuestUserId(), isNull);
        expect(await AppPrefs.pendingGuestSyncActionFor('auth-1'), isNull);

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
        outbox: _FakeOutbox(),
      );

      final consent = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.signIn,
      );
      expect(consent.status, UserDataSyncStatus.awaitingConsent);
      expect(local.replacedUserId, isNull);

      final result = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.signIn,
        guestAction: GuestMergeAction.useExistingCloud,
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
          outbox: _FakeOutbox(),
        );

        await repository.syncAfterAuthenticatedSession(
          AuthSyncReason.signIn,
          guestAction: GuestMergeAction.useExistingCloud,
        );

        expect(remote.pushedSnapshot, isNull);
        expect(local.replacedUserId, 'auth-1');
        expect(await AppPrefs.isOnboardingCompleted(), isFalse);
      },
    );

    test('pending auth outbox blocks Guest cloud inspection', () async {
      await AppPrefs.setPendingGuestUserId('guest-1');
      final remote = _FakeRemoteDatasource(
        pullSnapshots: [_freshSnapshot('auth-1')],
      );
      final local = _FakeLocalDatasource({
        'guest-1': _snapshot('guest-1', tableName: 'meal_plans'),
      });
      final outbox = _FakeOutbox(pendingCounts: [1, 1]);
      final repository = AuthenticatedUserDataSyncRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
        outbox: outbox,
      );

      final result = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.signIn,
      );

      expect(result.status, UserDataSyncStatus.pendingUpload);
      expect(remote.pullCalls, 0);
      expect(await AppPrefs.pendingGuestUserId(), 'guest-1');
    });

    test('pending outbox is never followed by cloud pull', () async {
      final remote = _FakeRemoteDatasource(
        pullSnapshots: [_snapshot('auth-1', tableName: 'meal_plans')],
      );
      final local = _FakeLocalDatasource({});
      final outbox = _FakeOutbox(pendingCounts: [1, 1]);
      final repository = AuthenticatedUserDataSyncRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
        outbox: outbox,
      );

      final result = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.connectivity,
      );

      expect(result.status, UserDataSyncStatus.pendingUpload);
      expect(result.pendingCount, 1);
      expect(remote.pullCalls, 0);
      expect(local.replacedUserId, isNull);
      expect(outbox.drainCalls, 1);
    });

    test('confirmed outbox drain happens before cloud pull', () async {
      final events = <String>[];
      final remote = _FakeRemoteDatasource(
        pullSnapshots: [_snapshot('auth-1', tableName: 'meal_plans')],
        events: events,
      );
      final local = _FakeLocalDatasource({}, events: events);
      final outbox = _FakeOutbox(
        pendingCounts: [1, 0],
        events: events,
      );
      final repository = AuthenticatedUserDataSyncRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
        outbox: outbox,
      );

      final result = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.resume,
      );

      expect(result.status, UserDataSyncStatus.success);
      expect(events, [
        'outbox:due',
        'outbox:drain',
        'cloud:pull',
        'local:replace',
      ]);
    });

    test('local write created during pull prevents cache replacement', () async {
      final remote = _FakeRemoteDatasource(
        pullSnapshots: [_snapshot('auth-1', tableName: 'meal_plans')],
      );
      final local = _FakeLocalDatasource({}, pendingOnReplace: 2);
      final repository = AuthenticatedUserDataSyncRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
        outbox: _FakeOutbox(),
      );

      final result = await repository.syncAfterAuthenticatedSession(
        AuthSyncReason.resume,
      );

      expect(result.status, UserDataSyncStatus.pendingUpload);
      expect(result.pendingCount, 2);
      expect(local.replacedUserId, isNull);
    });

    test(
      'sync failure after Guest upload does not clear pending Guest id',
      () async {
        await AppPrefs.setPendingGuestUserId('guest-1');

        final remote = _FakeRemoteDatasource(
          pullSnapshots: [
            _freshSnapshot('auth-1'),
            _snapshot('auth-1', tableName: 'meal_plans'),
          ],
          failOnPullCalls: const {2},
        );
        final local = _FakeLocalDatasource({
          'guest-1': _snapshot('guest-1', tableName: 'meal_plans'),
        });
        final repository = AuthenticatedUserDataSyncRepositoryImpl(
          remoteDatasource: remote,
          localDatasource: local,
          outbox: _FakeOutbox(),
        );

        final result = await repository.syncAfterAuthenticatedSession(
          AuthSyncReason.signIn,
          guestAction: GuestMergeAction.mergeNow,
        );

        expect(result.status, UserDataSyncStatus.error);
        expect(remote.pushedSnapshot, isNotNull);
        expect(await AppPrefs.pendingGuestUserId(), 'guest-1');
        expect(
          await AppPrefs.pendingGuestSyncActionFor('auth-1'),
          GuestMergeAction.useExistingCloud.name,
        );

        final retry = await repository.syncAfterAuthenticatedSession(
          AuthSyncReason.connectivity,
        );

        expect(retry.status, UserDataSyncStatus.success);
        expect(local.replacedUserId, 'auth-1');
        expect(await AppPrefs.pendingGuestUserId(), isNull);
        expect(await AppPrefs.pendingGuestSyncActionFor('auth-1'), isNull);
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

class _FakeOutbox extends UserDataSyncOutbox {
  final List<int> pendingCounts;
  final List<String>? events;
  var _pendingReadIndex = 0;
  var drainCalls = 0;

  _FakeOutbox({List<int>? pendingCounts, this.events})
    : pendingCounts = pendingCounts ?? const [0],
      super(currentUserId: () => 'auth-1', drainImmediately: false);

  @override
  Future<int> pendingCountForCurrentUser({Database? database}) async {
    final index = _pendingReadIndex
        .clamp(0, pendingCounts.length - 1)
        .toInt();
    _pendingReadIndex += 1;
    return pendingCounts[index];
  }

  @override
  Future<void> makeRetriesDueForCurrentUser({Database? database}) async {
    events?.add('outbox:due');
  }

  @override
  Future<int> drainPending({Database? database, int limit = 100}) async {
    drainCalls += 1;
    events?.add('outbox:drain');
    return 0;
  }
}

class _FakeRemoteDatasource implements UserDataSyncRemoteDatasource {
  @override
  final String? currentUserId = 'auth-1';

  final List<UserDataSnapshot?> pullSnapshots;
  final int? failFromPull;
  final Set<int> failOnPullCalls;
  final List<String>? events;
  int _pullCalls = 0;

  UserDataSnapshot? pushedSnapshot;
  String? pushedAuthUserId;

  _FakeRemoteDatasource({
    required this.pullSnapshots,
    this.failFromPull,
    this.failOnPullCalls = const {},
    this.events,
  });

  int get pullCalls => _pullCalls;

  UserDataSnapshot? get lastSnapshot => pullSnapshots.isEmpty
      ? null
      : pullSnapshots[(pullSnapshots.length - 1)
            .clamp(0, pullSnapshots.length - 1)
            .toInt()];

  @override
  Future<Map<String, Object?>?> currentUserRow() async => lastSnapshot?.user;

  @override
  Future<UserDataSnapshot?> pullCurrentUserSnapshot() async {
    events?.add('cloud:pull');
    _pullCalls += 1;
    if (failOnPullCalls.contains(_pullCalls) ||
        (failFromPull != null && _pullCalls >= failFromPull!)) {
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
  final List<String>? events;
  final int pendingOnReplace;

  String? replacedUserId;
  String? removedLocalUserId;

  _FakeLocalDatasource(
    this.snapshots, {
    this.events,
    this.pendingOnReplace = 0,
  });

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
    if (pendingOnReplace > 0) {
      throw LocalSyncPendingWriteException(pendingOnReplace);
    }
    events?.add('local:replace');
    replacedUserId = userId;
    removedLocalUserId = removeLocalUserId;
  }
}
