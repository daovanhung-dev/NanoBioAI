import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/health_score_habits_models.dart';

class SqliteHealthScoreHabitsLocalDatasource {
  final Database? databaseOverride;

  const SqliteHealthScoreHabitsLocalDatasource({this.databaseOverride});

  Future<HealthScoreInputSnapshot> loadInputs({
    required String userId,
    required HealthScorePeriod period,
    required DateTime now,
  }) async {
    final db = databaseOverride ?? await DatabaseService.database;
    final scheduleRows = await _queryByDateRange(
      db: db,
      table: 'lifestyle_schedule_items',
      userId: userId,
      dateColumn: 'schedule_date',
      period: period,
      orderBy: 'schedule_date ASC, sort_order ASC, start_time ASC',
    );

    final linkedMealIds = <String>{};
    final linkedTaskIds = <String>{};
    final entries = <HealthScoreCompletionEntry>[];

    for (final row in scheduleRows) {
      final date = HealthScoreDateKey.fromValue(row['schedule_date']);
      if (date == null) continue;

      final sourceType = _readString(row['source_type']) ?? '';
      final sourceId = _readString(row['source_id']);
      if (sourceType == _sourceMealPlan && sourceId != null) {
        linkedMealIds.add(sourceId);
      }
      if (sourceType == _sourceDailyHealthTask && sourceId != null) {
        linkedTaskIds.add(sourceId);
      }

      final category = _readString(row['category']) ?? 'habit';
      final group = sourceType == _sourceMealPlan || category == 'meal'
          ? HealthScoreCompletionGroup.meals
          : HealthScoreCompletionGroup.tasksHabits;
      entries.add(
        HealthScoreCompletionEntry(
          id: 'schedule:${_readString(row['id']) ?? entries.length}',
          date: date,
          group: group,
          category: category,
          title: _readString(row['title']) ?? category,
          isCompleted: _readBool(row['is_completed']),
          isDue: _isDue(
            date: date,
            time: _readString(row['start_time']),
            now: now,
          ),
        ),
      );
    }

    final mealRows = await _queryByDateRange(
      db: db,
      table: 'meal_plans',
      userId: userId,
      dateColumn: 'plan_date',
      period: period,
      orderBy: 'plan_date ASC, meal_order ASC, start_time ASC',
    );
    for (final row in mealRows) {
      final id = _readString(row['id']);
      if (id != null && linkedMealIds.contains(id)) continue;
      final date = HealthScoreDateKey.fromValue(row['plan_date']);
      if (date == null) continue;

      entries.add(
        HealthScoreCompletionEntry(
          id: 'meal:${id ?? entries.length}',
          date: date,
          group: HealthScoreCompletionGroup.meals,
          category: 'meal',
          title: _readString(row['meal_name']) ?? 'Meal',
          isCompleted: _readBool(row['is_completed']),
          isDue: _isDue(
            date: date,
            time: _readString(row['start_time']),
            now: now,
          ),
        ),
      );
    }

    final taskRows = await _queryByDateRange(
      db: db,
      table: 'daily_health_tasks',
      userId: userId,
      dateColumn: 'task_date',
      period: period,
      orderBy: 'task_date ASC, sort_order ASC, created_at ASC',
    );
    for (final row in taskRows) {
      final id = _readString(row['id']);
      if (id != null && linkedTaskIds.contains(id)) continue;
      final date = HealthScoreDateKey.fromValue(row['task_date']);
      if (date == null) continue;

      entries.add(
        HealthScoreCompletionEntry(
          id: 'task:${id ?? entries.length}',
          date: date,
          group: HealthScoreCompletionGroup.tasksHabits,
          category: _readString(row['category']) ?? 'health',
          title: _readString(row['title']) ?? 'Task',
          isCompleted: _readBool(row['is_completed']),
          isDue: _isDue(date: date, time: null, now: now),
        ),
      );
    }

    final logRows = await _queryByDateRange(
      db: db,
      table: 'health_tracking_logs',
      userId: userId,
      dateColumn: 'log_date',
      period: period,
      orderBy: 'log_date ASC, updated_at DESC, created_at DESC',
    );
    final logsByDate = <String, HealthScoreDailyLogEntry>{};
    for (final row in logRows) {
      final date = HealthScoreDateKey.fromValue(row['log_date']);
      if (date == null) continue;
      final existing = logsByDate[date];
      if (existing != null) continue;

      logsByDate[date] = HealthScoreDailyLogEntry(
        date: date,
        waterMl: _readInt(row['water_ml']) ?? 0,
        sleepHours: _readDouble(row['sleep_hours']) ?? 0,
      );
    }

    return HealthScoreInputSnapshot(
      userId: userId,
      period: period,
      now: now,
      completionEntries: entries,
      dailyLogs: logsByDate.values.toList(growable: false),
    );
  }

  Future<List<Map<String, Object?>>> _queryByDateRange({
    required Database db,
    required String table,
    required String userId,
    required String dateColumn,
    required HealthScorePeriod period,
    required String orderBy,
  }) {
    return db.query(
      table,
      where:
          'user_id = ? AND substr($dateColumn, 1, 10) >= ? AND substr($dateColumn, 1, 10) <= ?',
      whereArgs: [userId, period.startDate, period.endDate],
      orderBy: orderBy,
    );
  }

  bool _isDue({
    required String date,
    required String? time,
    required DateTime now,
  }) {
    final itemDate = DateTime.tryParse(date);
    if (itemDate == null) return false;

    final today = HealthScoreDateKey.dateOnly(now);
    final day = HealthScoreDateKey.dateOnly(itemDate);
    if (day.isBefore(today)) return true;
    if (day.isAfter(today)) return false;

    final timeParts = (time ?? '').split(':');
    if (timeParts.length != 2) return true;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return true;

    return !now.isBefore(DateTime(day.year, day.month, day.day, hour, minute));
  }

  String? _readString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool _readBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }

  static const _sourceMealPlan = 'meal_plan';
  static const _sourceDailyHealthTask = 'daily_health_task';
}
