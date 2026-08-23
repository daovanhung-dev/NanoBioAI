import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/health_insights_entity.dart';

class HealthInsightsLocalDatasource {
  final Database? databaseOverride;
  final DateTime Function() _now;

  HealthInsightsLocalDatasource({
    this.databaseOverride,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<HealthInsightsHistoryEntity> readHistory({required int days}) async {
    final db = await _db();
    final userId = await _resolveUserId(db);
    final safeDays = days.clamp(1, 180).toInt();
    final today = _dateOnly(_now());
    final start = today.subtract(Duration(days: safeDays - 1));
    final startKey = _dateKey(start);
    final endKey = _dateKey(today);

    final logRows = await db.query(
      'health_tracking_logs',
      where:
          'user_id = ? AND substr(log_date, 1, 10) >= ? AND substr(log_date, 1, 10) <= ?',
      whereArgs: [userId, startKey, endKey],
      orderBy: 'log_date ASC, updated_at ASC, created_at ASC',
    );

    final taskRows = await db.query(
      'daily_health_tasks',
      columns: const ['task_date', 'is_completed'],
      where:
          'user_id = ? AND substr(task_date, 1, 10) >= ? AND substr(task_date, 1, 10) <= ?',
      whereArgs: [userId, startKey, endKey],
      orderBy: 'task_date ASC',
    );

    final mealRows = await db.query(
      'meal_plans',
      columns: const ['plan_date', 'is_completed'],
      where:
          'user_id = ? AND substr(plan_date, 1, 10) >= ? AND substr(plan_date, 1, 10) <= ?',
      whereArgs: [userId, startKey, endKey],
      orderBy: 'plan_date ASC',
    );

    final logsByDate = <String, HealthLogEntry>{};
    for (final row in logRows) {
      final entry = _mapHealthLog(row);
      if (entry == null) continue;
      final key = _dateKey(entry.date);
      final current = logsByDate[key];
      if (current == null || _isNewer(entry, current)) {
        logsByDate[key] = entry;
      }
    }

    final taskTotals = <String, int>{};
    final taskCompleted = <String, int>{};
    for (final row in taskRows) {
      final key = _datePart(row['task_date']);
      if (key == null) continue;
      taskTotals[key] = (taskTotals[key] ?? 0) + 1;
      if (_readBool(row['is_completed'])) {
        taskCompleted[key] = (taskCompleted[key] ?? 0) + 1;
      }
    }

    final mealTotals = <String, int>{};
    final mealCompleted = <String, int>{};
    for (final row in mealRows) {
      final key = _datePart(row['plan_date']);
      if (key == null) continue;
      mealTotals[key] = (mealTotals[key] ?? 0) + 1;
      if (_readBool(row['is_completed'])) {
        mealCompleted[key] = (mealCompleted[key] ?? 0) + 1;
      }
    }

    final adherenceDates = <String>{
      ...taskTotals.keys,
      ...mealTotals.keys,
    }.toList()
      ..sort();

    final adherence = <HealthDailyAdherenceEntry>[];
    for (final key in adherenceDates) {
      final date = DateTime.tryParse(key);
      if (date == null) continue;
      adherence.add(
        HealthDailyAdherenceEntry(
          date: _dateOnly(date),
          completedTasks: taskCompleted[key] ?? 0,
          totalTasks: taskTotals[key] ?? 0,
          completedMeals: mealCompleted[key] ?? 0,
          totalMeals: mealTotals[key] ?? 0,
        ),
      );
    }

    final logs = logsByDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return HealthInsightsHistoryEntity(
      userId: userId,
      logs: logs,
      adherence: adherence,
    );
  }

  Future<String> _resolveUserId(Database db) async {
    final authUserId = currentSupabaseUserIdOrNull();
    if (authUserId != null && authUserId.trim().isNotEmpty) {
      final rows = await db.query(
        'users',
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [authUserId],
        limit: 1,
      );
      if (rows.isNotEmpty) return authUserId;
    }

    final users = await db.query(
      'users',
      columns: const ['id'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (users.isEmpty) {
      throw StateError('Chưa có dữ liệu người dùng trong SQLite.');
    }

    final value = users.first['id']?.toString().trim() ?? '';
    if (value.isEmpty) {
      throw StateError('Dữ liệu người dùng chưa sẵn sàng.');
    }
    return value;
  }

  HealthLogEntry? _mapHealthLog(Map<String, Object?> row) {
    final dateText = _datePart(row['log_date']);
    final date = dateText == null ? null : DateTime.tryParse(dateText);
    if (date == null) return null;

    final updatedAt = _readDateTime(row['updated_at']) ??
        _readDateTime(row['created_at']) ??
        date;

    return HealthLogEntry(
      date: _dateOnly(date),
      updatedAt: updatedAt,
      weightKg: _readDouble(row['weight_kg']),
      calories: _readInt(row['calories']),
      waterMl: _readInt(row['water_ml']),
      sleepHours: _readDouble(row['sleep_hours']),
      stressLevel: _readInt(row['stress_level']),
      stepsCount: _readInt(row['steps_count']),
      heartRateBpm: _readInt(row['heart_rate_bpm']),
      oxygenSaturation: _readDouble(row['oxygen_saturation']),
      dailyScore: _readInt(row['daily_score']),
      mood: _readString(row['mood']),
    );
  }

  bool _isNewer(HealthLogEntry candidate, HealthLogEntry current) {
    final candidateTime = candidate.updatedAt;
    final currentTime = current.updatedAt;
    if (candidateTime == null) return false;
    if (currentTime == null) return true;
    return candidateTime.isAfter(currentTime);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String? _datePart(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.length < 10) return null;
    final part = text.substring(0, 10);
    return DateTime.tryParse(part) == null ? null : part;
  }

  DateTime? _readDateTime(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String? _readString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }
}
