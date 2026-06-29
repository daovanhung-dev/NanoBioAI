import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/health_scoring/health_scoring.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqliteHealthScoreHabitsLocalDatasource datasource;
  const period = HealthScorePeriod(
    startDate: '2026-06-23',
    endDate: '2026-06-29',
  );
  final now = DateTime.parse('2026-06-29T12:00:00');

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(HealthTrackingLogsTable.createTable);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(MealPlansTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    datasource = SqliteHealthScoreHabitsLocalDatasource(databaseOverride: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('filters by user and period while reading water and sleep', () async {
    await db.insert('health_tracking_logs', _log(id: 'in', userId: 'u1'));
    await db.insert(
      'health_tracking_logs',
      _log(id: 'other-user', userId: 'u2'),
    );
    await db.insert(
      'health_tracking_logs',
      _log(id: 'old', userId: 'u1', logDate: '2026-06-20'),
    );

    final result = await datasource.loadInputs(
      userId: 'u1',
      period: period,
      now: now,
    );

    expect(result.dailyLogs, hasLength(1));
    expect(result.dailyLogs.single.date, '2026-06-29');
    expect(result.dailyLogs.single.waterMl, 1500);
    expect(result.dailyLogs.single.sleepHours, 6.5);
  });

  test(
    'uses linked schedule entries as canonical to avoid double count',
    () async {
      await db.insert(
        'lifestyle_schedule_items',
        _schedule(
          id: 'schedule-meal',
          sourceType: 'meal_plan',
          sourceId: 'meal-linked',
          category: 'meal',
        ),
      );
      await db.insert(
        'lifestyle_schedule_items',
        _schedule(
          id: 'schedule-task',
          sourceType: 'daily_health_task',
          sourceId: 'task-linked',
          category: 'water',
        ),
      );
      await db.insert('meal_plans', _meal(id: 'meal-linked'));
      await db.insert('meal_plans', _meal(id: 'meal-standalone'));
      await db.insert('daily_health_tasks', _task(id: 'task-linked'));
      await db.insert('daily_health_tasks', _task(id: 'task-standalone'));

      final result = await datasource.loadInputs(
        userId: 'u1',
        period: period,
        now: now,
      );

      expect(result.completionEntries, hasLength(4));
      expect(
        result.completionEntries.where(
          (entry) => entry.group == HealthScoreCompletionGroup.meals,
        ),
        hasLength(2),
      );
      expect(
        result.completionEntries.where(
          (entry) => entry.group == HealthScoreCompletionGroup.tasksHabits,
        ),
        hasLength(2),
      );
    },
  );

  test('marks future or not-due-today schedule entries as not due', () async {
    await db.insert(
      'lifestyle_schedule_items',
      _schedule(id: 'due', startTime: '07:00'),
    );
    await db.insert(
      'lifestyle_schedule_items',
      _schedule(id: 'not-due', startTime: '23:00'),
    );
    await db.insert(
      'lifestyle_schedule_items',
      _schedule(id: 'future', scheduleDate: '2026-06-30'),
    );

    final result = await datasource.loadInputs(
      userId: 'u1',
      period: const HealthScorePeriod(
        startDate: '2026-06-29',
        endDate: '2026-06-30',
      ),
      now: now,
    );

    final due = result.completionEntries.firstWhere(
      (entry) => entry.id == 'schedule:due',
    );
    final notDue = result.completionEntries.firstWhere(
      (entry) => entry.id == 'schedule:not-due',
    );
    final future = result.completionEntries.firstWhere(
      (entry) => entry.id == 'schedule:future',
    );

    expect(due.isDue, isTrue);
    expect(notDue.isDue, isFalse);
    expect(future.isDue, isFalse);
  });
}

Map<String, Object?> _log({
  required String id,
  required String userId,
  String logDate = '2026-06-29',
}) {
  return {
    'id': id,
    'user_id': userId,
    'log_date': logDate,
    'water_ml': 1500,
    'sleep_hours': 6.5,
    'created_at': '2026-06-29T08:00:00',
    'updated_at': '2026-06-29T08:00:00',
  };
}

Map<String, Object?> _schedule({
  required String id,
  String userId = 'u1',
  String scheduleDate = '2026-06-29',
  String startTime = '08:00',
  String sourceType = 'ai_schedule',
  String sourceId = '',
  String category = 'water',
}) {
  return {
    'id': id,
    'user_id': userId,
    'schedule_date': scheduleDate,
    'start_time': startTime,
    'end_time': '08:30',
    'title': id,
    'description': '',
    'category': category,
    'source_type': sourceType,
    'source_id': sourceId,
    'target_value': 1,
    'current_value': 1,
    'unit': 'lan',
    'is_completed': 1,
    'sort_order': 1,
    'ai_generated': 1,
    'created_at': '2026-06-29T08:00:00',
    'updated_at': '2026-06-29T08:00:00',
  };
}

Map<String, Object?> _meal({required String id}) {
  return {
    'id': id,
    'user_id': 'u1',
    'plan_date': '2026-06-29',
    'meal_type': 'breakfast',
    'meal_name': id,
    'description': '',
    'calories': 300,
    'protein': 10,
    'carbs': 30,
    'fat': 8,
    'fiber': 4,
    'water_ml': 250,
    'meal_order': 1,
    'start_time': '07:00',
    'end_time': '07:30',
    'cooking_instructions': '',
    'is_completed': 1,
    'ai_generated': 1,
    'created_at': '2026-06-29T08:00:00',
    'updated_at': '2026-06-29T08:00:00',
  };
}

Map<String, Object?> _task({required String id}) {
  return {
    'id': id,
    'user_id': 'u1',
    'task_date': '2026-06-29',
    'task_code': id,
    'category': 'water',
    'title': id,
    'description': '',
    'target_value': 1,
    'current_value': 1,
    'unit': 'lan',
    'is_completed': 1,
    'sort_order': 1,
    'source': 'test',
    'encouragement': '',
    'created_at': '2026-06-29T08:00:00',
    'updated_at': '2026-06-29T08:00:00',
  };
}
