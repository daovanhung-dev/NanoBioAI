import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_conditions_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_habits_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:nano_app/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart';
import 'package:nano_app/features/daily_health_tracking/data/models/daily_health_task_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DailyHealthTrackingLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(UsersTable.createTable);
    await db.execute(HealthGoalsTable.createTable);
    await db.execute(HealthConditionsTable.createTable);
    await db.execute(LifestyleHabitsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
    await db.execute(DailyHealthTasksTable.createTable);
    datasource = DailyHealthTrackingLocalDatasource(databaseOverride: db);
    await db.insert('users', {
      'id': 'u1',
      'full_name': 'User One',
      'subscription_tier': 'premium',
      'created_at': '2026-06-18T08:00:00',
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('completeTaskById completes task and syncs health log water', () async {
    final today = _dateKey(DateTime.now());
    await DailyHealthTasksDao(
      db,
    ).upsertMany([_task(id: 'task-1', taskDate: today)]);

    final updated = await datasource.completeTaskById('task-1');
    final log = await HealthTrackingLogsDao(
      db,
    ).getByUserAndDate(userId: 'u1', logDate: today);

    expect(updated.isCompleted, isTrue);
    expect(updated.currentValue, 1500);
    expect(log, isNotNull);
    expect(log!.waterMl, 1500);
  });

  test(
    'saveTodayMood, setTodayWater, and saveTodayWeight upsert health log',
    () async {
      final today = _dateKey(DateTime.now());

      await datasource.saveTodayMood('stressed');
      await datasource.setTodayWater(900);
      await datasource.saveTodayWeight(63.2);

      final log = await HealthTrackingLogsDao(
        db,
      ).getByUserAndDate(userId: 'u1', logDate: today);

      expect(log, isNotNull);
      expect(log!.mood, 'stressed');
      expect(log.waterMl, 900);
      expect(log.weightKg, 63.2);
    },
  );

  test('addTodayWater updates matching water task when present', () async {
    final today = _dateKey(DateTime.now());
    await DailyHealthTasksDao(
      db,
    ).upsertMany([_task(id: 'task-water', taskDate: today, targetValue: 1000)]);

    await datasource.addTodayWater(500);

    final task = await DailyHealthTasksDao(db).getById('task-water');
    final log = await HealthTrackingLogsDao(
      db,
    ).getByUserAndDate(userId: 'u1', logDate: today);

    expect(task!.currentValue, 500);
    expect(task.isCompleted, isFalse);
    expect(log!.waterMl, 500);
  });
}

DailyHealthTaskModel _task({
  required String id,
  required String taskDate,
  double targetValue = 1500,
}) {
  return DailyHealthTaskModel(
    id: id,
    userId: 'u1',
    taskDate: taskDate,
    taskCode: 'water_daily',
    category: 'water',
    title: 'Uống nước',
    description: 'Uống đủ nước',
    targetValue: targetValue,
    currentValue: 0,
    unit: 'ml',
    isCompleted: false,
    sortOrder: 1,
    source: 'test',
    encouragement: 'Tốt lắm',
    createdAt: '2026-06-18T08:00:00',
    updatedAt: '2026-06-18T08:00:00',
  );
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
