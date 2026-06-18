import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/features/daily_health_tracking/data/models/daily_health_task_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
  });

  tearDown(() async {
    await db.close();
  });

  test('DailyHealthTasksDao upserts and queries today tasks', () async {
    final dao = DailyHealthTasksDao(db);
    const task = DailyHealthTaskModel(
      id: 'task-1',
      userId: 'u1',
      taskDate: '2026-06-16',
      taskCode: 'water_daily',
      category: 'water',
      title: 'Drink water',
      description: 'Drink enough water',
      targetValue: 2000,
      currentValue: 0,
      unit: 'ml',
      isCompleted: false,
      sortOrder: 1,
      source: 'profile',
      encouragement: 'Nice',
      createdAt: '2026-06-16T08:00:00',
      updatedAt: '2026-06-16T08:00:00',
    );

    await dao.upsertMany([task]);
    await dao.upsertMany([
      task.copyWith(currentValue: 2000, isCompleted: true),
    ]);

    final tasks = await dao.getByUserAndDate(
      userId: 'u1',
      taskDate: '2026-06-16',
    );

    expect(tasks, hasLength(1));
    expect(tasks.single.isCompleted, isTrue);
    expect(tasks.single.currentValue, 2000);
  });

  test('DailyHealthTasksDao stores seven days of generated tasks', () async {
    final dao = DailyHealthTasksDao(db);
    const categories = ['water', 'body', 'mind', 'brain'];
    final tasks = [
      for (var day = 17; day <= 23; day++)
        for (final category in categories)
          DailyHealthTaskModel(
            id: 'daily_u1_2026-06-$day-ai-$category',
            userId: 'u1',
            taskDate: '2026-06-$day',
            taskCode: 'ai_$category',
            category: category,
            title: '$category task',
            description: '$category description',
            targetValue: category == 'water' ? 2000 : 1,
            currentValue: 0,
            unit: category == 'water' ? 'ml' : 'lan',
            isCompleted: false,
            sortOrder: categories.indexOf(category) + 1,
            source: 'ai',
            encouragement: 'Nice',
            createdAt: '2026-06-16T08:00:00',
            updatedAt: '2026-06-16T08:00:00',
          ),
    ];

    await dao.upsertMany(tasks);

    final restored = await dao.getByUserAndDate(
      userId: 'u1',
      taskDate: '2026-06-20',
    );

    expect(tasks, hasLength(28));
    expect(restored, hasLength(4));
    expect(restored.map((task) => task.category).toSet(), categories.toSet());
  });

  test('HealthTrackingLogsDao upserts daily log by user and date', () async {
    final dao = HealthTrackingLogsDao(db);
    const log = HealthTrackingLogModel(
      id: 'log-1',
      userId: 'u1',
      logDate: '2026-06-16',
      waterMl: 500,
      heartRateBpm: 70,
      oxygenSaturation: 98.1,
      createdAt: '2026-06-16T08:00:00',
      updatedAt: '2026-06-16T08:00:00',
    );

    await dao.upsertByUserAndDate(log);
    await dao.upsertByUserAndDate(
      log.copyWith(
        waterMl: 1000,
        heartRateBpm: 74,
        oxygenSaturation: 98.6,
        updatedAt: '2026-06-16T09:00:00',
      ),
    );

    final restored = await dao.getByUserAndDate(
      userId: 'u1',
      logDate: '2026-06-16',
    );

    expect(restored, isNotNull);
    expect(restored!.waterMl, 1000);
    expect(restored.heartRateBpm, 74);
    expect(restored.oxygenSaturation, 98.6);
  });
}
