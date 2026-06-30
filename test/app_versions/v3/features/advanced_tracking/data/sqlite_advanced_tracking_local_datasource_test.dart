import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/advanced_tracking/advanced_tracking.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqliteAdvancedTrackingLocalDatasource datasource;
  late int syncRequests;

  const period = AdvancedTrackingPeriod(
    startDate: '2026-06-28',
    endDate: '2026-06-30',
  );

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(HealthGoalsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
    syncRequests = 0;
    LocalUserDataSyncDispatcher.register(({Database? database}) {
      syncRequests++;
    });
    datasource = SqliteAdvancedTrackingLocalDatasource(databaseOverride: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates hydration goal in existing health_goals storage', () async {
    final goal = await datasource.createHydrationGoal(
      subjectUserId: 'u1',
      now: DateTime.parse('2026-06-30T08:00:00'),
    );
    final loaded = await datasource.loadActiveGoal(
      subjectUserId: 'u1',
      goalCode: advancedTrackingHydrationGoalCode,
    );

    expect(goal.goalCode, advancedTrackingHydrationGoalCode);
    expect(goal.goalName, advancedTrackingHydrationGoalName);
    expect(loaded?.id, goal.id);
    expect(syncRequests, 1);
  });

  test('loads hydration logs by subject and period only', () async {
    await db.insert('health_tracking_logs', _log(id: 'in-1', userId: 'u1'));
    await db.insert(
      'health_tracking_logs',
      _log(id: 'in-2', userId: 'u1', logDate: '2026-06-29', waterMl: 2200),
    );
    await db.insert(
      'health_tracking_logs',
      _log(id: 'other-user', userId: 'u2', waterMl: 500),
    );
    await db.insert(
      'health_tracking_logs',
      _log(id: 'old', userId: 'u1', logDate: '2026-06-20'),
    );

    final logs = await datasource.loadHydrationLogs(
      subjectUserId: 'u1',
      period: period,
    );

    expect(logs, hasLength(2));
    expect(
      logs.map((log) => log.date),
      containsAll(['2026-06-28', '2026-06-29']),
    );
    expect(logs.every((log) => log.waterMl >= 1500), isTrue);
  });
}

Map<String, Object?> _log({
  required String id,
  required String userId,
  String logDate = '2026-06-28',
  int waterMl = 1500,
}) {
  return {
    'id': id,
    'user_id': userId,
    'log_date': logDate,
    'water_ml': waterMl,
    'created_at': '${logDate}T08:00:00',
    'updated_at': '${logDate}T08:00:00',
  };
}
