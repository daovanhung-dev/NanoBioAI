import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_eligibility_projection_store.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_eligibility_reconciler.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = OFF');
    await database.execute(PersonalScheduleAiRequestsTable.createTable);
    await database.execute(LifestyleScheduleItemsTable.createTable);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'does nothing before opening the database for an unauthenticated user',
    () async {
      final gateway = _RecordingGateway(hasAuthenticatedUser: false);
      final projectionStore = _RecordingProjectionStore();
      final reconciler = ScheduleRewardEligibilityReconciler(
        gateway: gateway,
        projectionStore: projectionStore,
        databaseOverride: database,
        currentUserId: () => 'user-1',
      );

      final result = await reconciler.registerPendingFutureSchedules();

      expect(result.requestsProcessed, 0);
      expect(result.futureItemsProjected, 0);
      expect(gateway.calls, isEmpty);
      expect(projectionStore.calls, isEmpty);
    },
  );

  test(
    'registers the complete ten-item manifest and projects only future items',
    () async {
      await _insertSucceededRequest(
        database,
        requestId: 'request-1',
        scheduleDate: '2026-07-13',
      );
      await _insertScheduleItems(
        database,
        requestId: 'request-1',
        scheduleDate: '2026-07-13',
        startTimes: const [
          '09:00',
          '10:00',
          '10:00:00.001',
          '10:30',
          '11:00:15',
          '12:00',
          '13:00',
          '14:00',
          '15:00',
          '16:00',
        ],
      );
      final gateway = _RecordingGateway();
      final projectionStore = _RecordingProjectionStore();
      final reconciler = ScheduleRewardEligibilityReconciler(
        gateway: gateway,
        projectionStore: projectionStore,
        databaseOverride: database,
        currentUserId: () => 'user-1',
        now: () => DateTime.utc(2026, 7, 13, 3),
      );

      final result = await reconciler.registerPendingFutureSchedules();

      expect(result.requestsProcessed, 1);
      expect(result.futureItemsProjected, 8);
      expect(gateway.calls, hasLength(1));
      expect(gateway.calls.single.requestId, 'request-1');
      expect(gateway.calls.single.idempotencyKey, 'eligibility:request-1:v1');
      expect(gateway.calls.single.items, hasLength(10));
      expect(
        gateway.calls.single.items.map((item) => item.scheduleItemId),
        orderedEquals(List.generate(10, (index) => 'request-1-item-$index')),
      );

      expect(projectionStore.calls, hasLength(1));
      expect(projectionStore.calls.single.userId, 'user-1');
      expect(projectionStore.calls.single.requestId, 'request-1');
      expect(
        projectionStore.calls.single.items.map((item) => item.scheduleItemId),
        orderedEquals(
          List.generate(8, (index) => 'request-1-item-${index + 2}'),
        ),
      );
    },
  );

  test(
    'skips requests that are not structurally ten milestones per day',
    () async {
      await _insertSucceededRequest(
        database,
        requestId: 'bad-quota',
        scheduleDate: '2026-07-14',
        scheduleItemCount: 9,
      );
      await _insertScheduleItems(
        database,
        requestId: 'bad-quota',
        scheduleDate: '2026-07-14',
        count: 9,
      );
      await _insertSucceededRequest(
        database,
        requestId: 'missing-item',
        scheduleDate: '2026-07-15',
      );
      await _insertScheduleItems(
        database,
        requestId: 'missing-item',
        scheduleDate: '2026-07-15',
        count: 9,
      );
      final gateway = _RecordingGateway();
      final projectionStore = _RecordingProjectionStore();
      final reconciler = ScheduleRewardEligibilityReconciler(
        gateway: gateway,
        projectionStore: projectionStore,
        databaseOverride: database,
        currentUserId: () => 'user-1',
        now: () => DateTime.utc(2026, 7, 13),
      );

      final result = await reconciler.registerPendingFutureSchedules();

      expect(result.requestsProcessed, 0);
      expect(result.futureItemsProjected, 0);
      expect(gateway.calls, isEmpty);
      expect(projectionStore.calls, isEmpty);
    },
  );

  test(
    'registers only not-yet-open tasks when a Guest plan is migrated',
    () async {
      await _insertSucceededRequest(
        database,
        requestId: 'guest-request',
        scheduleDate: '2026-07-13',
        actorMode: GeneratedPlanActorModes.initialGuest,
      );
      await _insertScheduleItems(
        database,
        requestId: 'guest-request',
        scheduleDate: '2026-07-13',
        startTimes: const [
          '09:00',
          '10:00',
          '10:00:00.001',
          '10:30',
          '11:00',
          '12:00',
          '13:00',
          '14:00',
          '15:00',
          '16:00',
        ],
      );
      final gateway = _RecordingGateway();
      final projectionStore = _RecordingProjectionStore();
      final reconciler = ScheduleRewardEligibilityReconciler(
        gateway: gateway,
        projectionStore: projectionStore,
        databaseOverride: database,
        currentUserId: () => 'user-1',
        now: () => DateTime.utc(2026, 7, 13, 3),
      );

      final result = await reconciler.registerPendingFutureSchedules();

      expect(result.requestsProcessed, 1);
      expect(result.futureItemsProjected, 8);
      expect(gateway.calls, hasLength(1));
      expect(
        gateway.calls.single.items.map((item) => item.scheduleItemId),
        orderedEquals(
          List.generate(8, (index) => 'guest-request-item-${index + 2}'),
        ),
      );
      expect(projectionStore.calls.single.items, hasLength(8));
    },
  );

  test('excludes malformed schedule times from the local projection', () async {
    await _insertSucceededRequest(
      database,
      requestId: 'malformed-time',
      scheduleDate: '2026-07-14',
    );
    await _insertScheduleItems(
      database,
      requestId: 'malformed-time',
      scheduleDate: '2026-07-14',
      startTimes: const [
        '08:00',
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '25:00',
      ],
    );
    final gateway = _RecordingGateway();
    final projectionStore = _RecordingProjectionStore();
    final reconciler = ScheduleRewardEligibilityReconciler(
      gateway: gateway,
      projectionStore: projectionStore,
      databaseOverride: database,
      currentUserId: () => 'user-1',
      now: () => DateTime.utc(2026, 7, 13),
    );

    final result = await reconciler.registerPendingFutureSchedules();

    expect(gateway.calls.single.items, hasLength(10));
    expect(result.futureItemsProjected, 9);
    expect(projectionStore.calls.single.items, hasLength(9));
    expect(
      projectionStore.calls.single.items.any(
        (item) => item.startTime == '25:00',
      ),
      isFalse,
    );
  });

  test(
    'continues with later requests when one registration is retryable',
    () async {
      await _insertSucceededRequest(
        database,
        requestId: 'request-fails',
        scheduleDate: '2026-07-14',
      );
      await _insertScheduleItems(
        database,
        requestId: 'request-fails',
        scheduleDate: '2026-07-14',
      );
      await _insertSucceededRequest(
        database,
        requestId: 'request-succeeds',
        scheduleDate: '2026-07-15',
      );
      await _insertScheduleItems(
        database,
        requestId: 'request-succeeds',
        scheduleDate: '2026-07-15',
      );
      final gateway = _RecordingGateway(failingRequestIds: {'request-fails'});
      final projectionStore = _RecordingProjectionStore();
      final reconciler = ScheduleRewardEligibilityReconciler(
        gateway: gateway,
        projectionStore: projectionStore,
        databaseOverride: database,
        currentUserId: () => 'user-1',
        now: () => DateTime.utc(2026, 7, 13),
      );

      final result = await reconciler.registerPendingFutureSchedules();

      expect(
        gateway.calls.map((call) => call.requestId),
        orderedEquals(['request-fails', 'request-succeeds']),
      );
      expect(result.requestsProcessed, 1);
      expect(result.futureItemsProjected, 10);
      expect(projectionStore.calls, hasLength(1));
      expect(projectionStore.calls.single.requestId, 'request-succeeds');
    },
  );
}

Future<void> _insertSucceededRequest(
  Database database, {
  required String requestId,
  required String scheduleDate,
  int scheduleItemCount = 10,
  String actorMode = GeneratedPlanActorModes.memberNew,
}) {
  return database.insert(PersonalScheduleAiRequestsTable.tableName, {
    'request_id': requestId,
    'user_id': 'user-1',
    'actor_mode': actorMode,
    'status': GeneratedPlanRequestStatuses.succeeded,
    'start_date': scheduleDate,
    'days': 1,
    'meal_count': 0,
    'exercise_count': 0,
    'schedule_item_count': scheduleItemCount,
    'created_at': '2026-07-12T00:00:00.000Z',
    'updated_at': '2026-07-12T00:00:00.000Z',
    'completed_at': '2026-07-12T00:00:00.000Z',
  });
}

Future<void> _insertScheduleItems(
  Database database, {
  required String requestId,
  required String scheduleDate,
  int count = 10,
  List<String>? startTimes,
}) async {
  final times =
      startTimes ??
      List.generate(
        count,
        (index) => '${(8 + index).toString().padLeft(2, '0')}:00',
      );
  assert(times.length == count);
  for (var index = 0; index < count; index++) {
    await database.insert(LifestyleScheduleItemsTable.tableName, {
      'id': '$requestId-item-$index',
      'user_id': 'user-1',
      'schedule_date': scheduleDate,
      'start_time': times[index],
      'end_time': '23:59',
      'title': 'Nhiệm vụ ${index + 1}',
      'category': 'routine',
      'source_type': 'ai_schedule',
      'sort_order': index,
      'ai_generated': 1,
      'created_at': '2026-07-12T00:00:00.000Z',
      'updated_at': '2026-07-12T00:00:00.000Z',
    });
  }
}

class _RegistrationCall {
  final String requestId;
  final List<ScheduleRewardEligibilityItem> items;
  final String idempotencyKey;

  const _RegistrationCall({
    required this.requestId,
    required this.items,
    required this.idempotencyKey,
  });
}

class _RecordingGateway extends Fake implements ScheduleRewardOnlineGateway {
  @override
  final bool hasAuthenticatedUser;
  final Set<String> failingRequestIds;
  final List<_RegistrationCall> calls = [];

  _RecordingGateway({
    this.hasAuthenticatedUser = true,
    this.failingRequestIds = const {},
  });

  @override
  Future<ScheduleRewardRegistrationResult> registerEligibilities({
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
    required String idempotencyKey,
  }) async {
    calls.add(
      _RegistrationCall(
        requestId: requestId,
        items: List.unmodifiable(items),
        idempotencyKey: idempotencyKey,
      ),
    );
    if (failingRequestIds.contains(requestId)) {
      throw ScheduleRewardException.network();
    }
    return ScheduleRewardRegistrationResult(
      registeredCount: items.length,
      existingCount: 0,
    );
  }

  @override
  Future<ScheduleRewardCompletionAttempt> beginCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<void> uploadProof({
    required ScheduleRewardCompletionAttempt attempt,
    required File file,
  }) => throw UnimplementedError();

  @override
  Future<ScheduleRewardFinalizeResult> finalizeCompletion({
    required ScheduleRewardCompletionAttempt attempt,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<ScheduleRewardFinalizeResult> undoCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> downloadProof(String storagePath) =>
      throw UnimplementedError();
}

class _ProjectionCall {
  final String userId;
  final String requestId;
  final List<ScheduleRewardEligibilityItem> items;

  const _ProjectionCall({
    required this.userId,
    required this.requestId,
    required this.items,
  });
}

class _RecordingProjectionStore
    implements ScheduleRewardEligibilityProjectionStore {
  final List<_ProjectionCall> calls = [];

  @override
  Future<void> markRegistered({
    required String userId,
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
  }) async {
    calls.add(
      _ProjectionCall(
        userId: userId,
        requestId: requestId,
        items: List.unmodifiable(items),
      ),
    );
  }
}
