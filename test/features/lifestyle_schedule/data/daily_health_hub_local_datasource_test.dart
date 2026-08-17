import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/daily_health_hub_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/daily_health_snapshot_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/manual_health_task_draft.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_health_action_type.dart';
import 'package:nano_app/core/storage/localdb/tables/health_score_ledgers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_health_checkin_outbox_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DailyHealthHubLocalDatasource datasource;
  final now = DateTime(2026, 8, 17, 10, 10);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(UsersTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
    await db.execute(HealthScoreLedgersTable.createTable);
    await db.execute(ScheduleHealthCheckInOutboxTable.createTable);
    await db.execute(ScheduleHealthCheckInOutboxTable.createPendingIndex);
    await db.execute(ScheduleHealthCheckInOutboxTable.createScheduleIndex);
    await db.insert('users', {
      'id': 'user-1',
      'created_at': '2026-08-01T00:00:00.000',
      'updated_at': '2026-08-01T00:00:00.000',
    });
    datasource = DailyHealthHubLocalDatasource(
      databaseOverride: db,
      now: () => now,
      random: Random(7),
    );
  });

  tearDown(() async => db.close());

  test('creates seven daily manual tasks with UUID ids and metadata', () async {
    final items = await datasource.createManualTaskSeries(
      ManualHealthTaskDraft(
        firstDate: DateTime(2026, 8, 17),
        startTime: '11:00',
        title: 'Nghỉ mắt 5 phút',
        category: LifestyleScheduleCategories.routine,
        actionType: ScheduleHealthActionType.quickComplete,
        repeat: ManualHealthTaskRepeat.daily,
        reminderEnabled: false,
      ),
    );

    expect(items, hasLength(7));
    expect(items.every((item) => item.isManualHealthTask), isTrue);
    expect(items.every((item) => item.aiGenerated == false), isTrue);
    expect(
      items.every(
        (item) => RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(item.id),
      ),
      isTrue,
    );
    final metadata = ManualHealthTaskMetadata.tryParse(items.first.sourceId);
    expect(metadata, isNotNull);
    expect(metadata!.reminderEnabled, isFalse);
    expect(metadata.repeat, ManualHealthTaskRepeat.daily);
  });

  test('hydration completion updates snapshot without letting manual task alter health score', () async {
    final items = await datasource.createManualTaskSeries(
      ManualHealthTaskDraft(
        firstDate: DateTime(2026, 8, 17),
        startTime: '10:00',
        title: 'Uống một cốc nước',
        category: LifestyleScheduleCategories.water,
        actionType: ScheduleHealthActionType.hydration,
      ),
    );

    final completed = await datasource.completeCheckInTask(
      item: items.single,
      input: const DailyHealthCheckInInput(waterDeltaMl: 250),
    );
    final snapshot = await datasource.getSnapshot(DateTime(2026, 8, 17));

    expect(completed.isCompleted, isTrue);
    expect(completed.completedAt, isNotNull);
    expect(snapshot.waterMl, 250);
    expect(snapshot.dailyScore, 0);
  });

  test('undo reverses task state but keeps self-reported health value', () async {
    final item = (await datasource.createManualTaskSeries(
      ManualHealthTaskDraft(
        firstDate: DateTime(2026, 8, 17),
        startTime: '10:00',
        title: 'Uống một cốc nước',
        category: LifestyleScheduleCategories.water,
        actionType: ScheduleHealthActionType.hydration,
      ),
    ))
        .single;
    final completed = await datasource.completeCheckInTask(
      item: item,
      input: const DailyHealthCheckInInput(waterDeltaMl: 250),
    );

    final undone = await datasource.undoCheckInTask(completed);
    final snapshot = await datasource.getSnapshot(DateTime(2026, 8, 17));

    expect(undone.isCompleted, isFalse);
    expect(undone.currentValue, 0);
    expect(snapshot.waterMl, 250);
    expect(snapshot.dailyScore, 0);
  });

  test('standalone check-in rejects future health logs', () async {
    expect(
      () => datasource.recordStandaloneCheckIn(
        date: DateTime(2026, 8, 18),
        input: const DailyHealthCheckInInput(waterDeltaMl: 250),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('standalone mood and stress check-in merges with existing daily log', () async {
    await datasource.recordStandaloneCheckIn(
      date: DateTime(2026, 8, 17),
      input: const DailyHealthCheckInInput(waterDeltaMl: 500),
    );
    final snapshot = await datasource.recordStandaloneCheckIn(
      date: DateTime(2026, 8, 17),
      input: const DailyHealthCheckInInput(
        mood: 'good',
        stressLevel: 2,
      ),
    );

    expect(snapshot.waterMl, 500);
    expect(snapshot.mood, 'good');
    expect(snapshot.stressLevel, 2);
  });
  test('authenticated completion queues durable reward evidence before RPC', () async {
    final item = (await datasource.createManualTaskSeries(
      ManualHealthTaskDraft(
        firstDate: DateTime(2026, 8, 17),
        startTime: '10:00',
        title: 'Uống một cốc nước',
        category: LifestyleScheduleCategories.water,
        actionType: ScheduleHealthActionType.hydration,
      ),
    ))
        .single;

    await datasource.completeCheckInTask(
      item: item,
      input: const DailyHealthCheckInInput(waterDeltaMl: 250),
      queueReward: true,
    );

    final pending = await datasource.pendingRewardAttempts();
    expect(pending, hasLength(1));
    expect(pending.single.scheduleItemId, item.id);
    expect(pending.single.input.waterDeltaMl, 250);
    expect(pending.single.isPending, isTrue);
  });


}
