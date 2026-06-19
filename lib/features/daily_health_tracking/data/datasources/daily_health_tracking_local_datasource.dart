import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/daily_health_profile_entity.dart';
import '../../domain/entities/daily_health_summary_entity.dart';
import '../../domain/entities/daily_health_task_entity.dart';
import '../../domain/services/daily_health_task_generator.dart';
import '../daos/daily_health_tasks_dao.dart';
import '../models/daily_health_task_model.dart';

class DailyHealthTrackingLocalDatasource {
  static const _tag = 'DAILY_TRACKING_DS';

  final Database? databaseOverride;
  final DailyHealthTaskGenerator taskGenerator;

  const DailyHealthTrackingLocalDatasource({
    this.databaseOverride,
    this.taskGenerator = const DailyHealthTaskGenerator(),
  });

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<DailyHealthProfileEntity> fetchLatestProfile() async {
    final db = await _db();
    return _fetchLatestProfile(db);
  }

  Future<void> seedGeneratedTasks(
    List<DailyHealthTaskModel> tasks, {
    bool requireComplete = false,
    DateTime? startDate,
    int days = 7,
  }) async {
    if (requireComplete) {
      _validateGeneratedTasks(tasks, startDate: startDate, days: days);
    }

    final db = await _db();
    await DailyHealthTasksDao(db).upsertMany(tasks);
  }

  Future<DailyHealthSummaryEntity> getTodaySummary({
    bool forceReload = false,
  }) async {
    final date = _dateKey(DateTime.now());
    AppLogger.database(_tag, 'Load summary for $date');

    try {
      final db = await _db();
      final profile = await _fetchLatestProfile(db);
      final dao = DailyHealthTasksDao(db);
      var tasks = await dao.getByUserAndDate(
        userId: profile.userId,
        taskDate: date,
      );

      if (tasks.isEmpty) {
        AppLogger.database(_tag, 'No tasks for today, generating from profile');
        final now = DateTime.now().toIso8601String();
        final generated = taskGenerator
            .generate(profile: profile, taskDate: date, createdAt: now)
            .map(DailyHealthTaskModel.fromEntity)
            .toList();
        await dao.upsertMany(generated);
        tasks = await dao.getByUserAndDate(
          userId: profile.userId,
          taskDate: date,
        );
      } else if (forceReload) {
        AppLogger.database(_tag, 'Reloaded ${tasks.length} existing task(s)');
      }

      final summary = DailyHealthSummaryEntity(
        userId: profile.userId,
        fullName: profile.fullName,
        taskDate: date,
        tasks: tasks.map((task) => task.toEntity()).toList(),
      );

      AppLogger.summary(_tag, 'DAILY_TRACKING_SUMMARY', {
        'userId': summary.userId,
        'date': summary.taskDate,
        'tasks': summary.totalTasks,
        'completed': summary.completedTasks,
        'score': summary.score,
      });

      return summary;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to load daily tracking summary', e, st);
      rethrow;
    }
  }

  Future<DailyHealthTaskEntity> updateTask(DailyHealthTaskEntity task) async {
    AppLogger.database(_tag, 'Update daily task ${task.taskCode}');

    try {
      final db = await _db();
      final now = DateTime.now().toIso8601String();
      final updated = task.copyWith(
        currentValue: task.currentValue.clamp(0, task.targetValue).toDouble(),
        isCompleted: task.currentValue >= task.targetValue,
        updatedAt: now,
      );
      final model = DailyHealthTaskModel.fromEntity(updated);
      await DailyHealthTasksDao(db).updateTask(model);
      await _syncHealthLog(db, updated);
      AppLogger.success(_tag, 'Task updated: ${updated.taskCode}');
      return updated;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to update daily task', e, st);
      rethrow;
    }
  }

  Future<DailyHealthTaskEntity> completeTaskById(String id) async {
    AppLogger.database(_tag, 'Complete daily task by id');

    try {
      final db = await _db();
      final task = await DailyHealthTasksDao(db).getById(id);
      if (task == null) {
        throw StateError('Daily health task not found');
      }

      return updateTask(
        task.toEntity().copyWith(
          currentValue: task.targetValue,
          isCompleted: true,
        ),
      );
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to complete daily task', e, st);
      rethrow;
    }
  }

  Future<void> saveTodayMood(String mood) async {
    AppLogger.database(_tag, 'Save today mood');
    await _updateTodayHealthLog((current, now) {
      return current.copyWith(mood: mood, updatedAt: now);
    });
  }

  Future<void> addTodayWater(int amountMl) async {
    AppLogger.database(_tag, 'Add today water');
    await _updateWater((currentWater) => currentWater + amountMl);
  }

  Future<void> setTodayWater(int waterMl) async {
    AppLogger.database(_tag, 'Set today water');
    await _updateWater((_) => waterMl);
  }

  Future<void> saveTodayWeight(double weightKg) async {
    AppLogger.database(_tag, 'Save today weight');
    await _updateTodayHealthLog((current, now) {
      return current.copyWith(weightKg: weightKg, updatedAt: now);
    });
  }

  Future<DailyHealthProfileEntity> _fetchLatestProfile(Database db) async {
    AppLogger.database(_tag, 'Fetching latest user profile');

    final users = await db.query('users', orderBy: 'created_at DESC', limit: 1);
    if (users.isEmpty) {
      throw Exception('Chưa có dữ liệu người dùng trong SQLite.');
    }

    final user = users.first;
    final userId = user['id'].toString();

    final goalRows = await db.query(
      'health_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    final conditionRows = await db.query(
      'health_conditions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    final habitRows = await db.query(
      'lifestyle_habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final lifestyle = habitRows.isNotEmpty
        ? habitRows.first
        : <String, Object?>{};

    return DailyHealthProfileEntity(
      userId: userId,
      fullName: user['full_name']?.toString() ?? 'bạn',
      goals: goalRows
          .expand((row) => [row['goal_code'], row['goal_name']])
          .whereType<Object>()
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
      conditions: conditionRows
          .expand((row) => [row['condition_code'], row['condition_name']])
          .whereType<Object>()
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
      habits: _readHabits(lifestyle),
      sleepQuality: lifestyle['sleep_quality']?.toString() ?? '',
      activityLevel: lifestyle['activity_level']?.toString() ?? '',
      waterPerDay: lifestyle['water_per_day']?.toString() ?? '',
    );
  }

  Future<void> _syncHealthLog(Database db, DailyHealthTaskEntity task) async {
    if (task.userId == null) return;
    if (task.taskCode != 'water_daily' &&
        task.taskCode != 'water_morning' &&
        task.taskCode != 'body_steps') {
      return;
    }

    final dao = HealthTrackingLogsDao(db);
    final dailyTasks = await DailyHealthTasksDao(
      db,
    ).getByUserAndDate(userId: task.userId!, taskDate: task.taskDate);
    final totalWater = dailyTasks
        .where((item) => item.category == 'water')
        .fold<int>(0, (sum, item) => sum + item.currentValue.round());
    final totalSteps = dailyTasks
        .where((item) => item.taskCode == 'body_steps')
        .fold<int>(0, (sum, item) => sum + item.currentValue.round());
    final existing = await dao.getByUserAndDate(
      userId: task.userId!,
      logDate: task.taskDate,
    );
    final now = DateTime.now().toIso8601String();
    final current =
        existing ??
        HealthTrackingLogModel(
          id: 'health_log_${task.userId}_${task.taskDate}',
          userId: task.userId,
          logDate: task.taskDate,
          createdAt: now,
          updatedAt: now,
        );

    final next = current.copyWith(
      waterMl: totalWater > 0 ? totalWater : current.waterMl,
      stepsCount: totalSteps > 0 ? totalSteps : current.stepsCount,
      updatedAt: now,
    );

    await dao.upsertByUserAndDate(next);
  }

  Future<void> _updateWater(int Function(int currentWater) resolveWater) async {
    await _updateTodayHealthLog(
      (current, now) {
        final nextWater = resolveWater(current.waterMl).clamp(0, 10000).toInt();
        return current.copyWith(waterMl: nextWater, updatedAt: now);
      },
      afterSave: (db, log) async {
        await _syncWaterTask(db: db, log: log);
      },
    );
  }

  Future<void> _syncWaterTask({
    required Database db,
    required HealthTrackingLogModel log,
  }) async {
    final userId = log.userId;
    if (userId == null || userId.isEmpty) return;

    final dao = DailyHealthTasksDao(db);
    final tasks = await dao.getByUserAndDate(
      userId: userId,
      taskDate: log.logDate,
    );
    final waterTasks = tasks
        .where((task) => task.category == 'water')
        .toList(growable: false);
    if (waterTasks.isEmpty) return;

    final task = waterTasks.firstWhere(
      (item) => item.taskCode == 'water_daily',
      orElse: () => waterTasks.reduce(
        (current, next) =>
            current.targetValue >= next.targetValue ? current : next,
      ),
    );
    final nextValue = log.waterMl.clamp(0, task.targetValue).toDouble();
    await dao.updateTask(
      task.copyWith(
        currentValue: nextValue,
        isCompleted: nextValue >= task.targetValue,
        updatedAt: log.updatedAt,
      ),
    );
  }

  Future<void> _updateTodayHealthLog(
    HealthTrackingLogModel Function(HealthTrackingLogModel current, String now)
    update, {
    Future<void> Function(Database db, HealthTrackingLogModel log)? afterSave,
  }) async {
    final db = await _db();
    final profile = await _fetchLatestProfile(db);
    final date = _dateKey(DateTime.now());
    final dao = HealthTrackingLogsDao(db);
    final existing = await dao.getByUserAndDate(
      userId: profile.userId,
      logDate: date,
    );
    final now = DateTime.now().toIso8601String();
    final current =
        existing ??
        HealthTrackingLogModel(
          id: 'health_log_${profile.userId}_$date',
          userId: profile.userId,
          logDate: date,
          createdAt: now,
          updatedAt: now,
        );
    final next = update(current, now);
    await dao.upsertByUserAndDate(next);
    await afterSave?.call(db, next);
  }

  List<String> _readHabits(Map<String, Object?> row) {
    final habits = <String>[];
    final codes = [
      'skip_breakfast',
      'eat_late',
      'eat_sweet',
      'eat_oily',
      'low_vegetable',
      'low_water',
      'fast_food',
      'alcohol',
      'coffee_high',
    ];

    for (final code in codes) {
      if (_readBool(row[code])) habits.add(code);
    }

    return habits;
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _validateGeneratedTasks(
    List<DailyHealthTaskModel> tasks, {
    required DateTime? startDate,
    required int days,
  }) {
    const categories = {'water', 'body', 'mind', 'brain'};
    final expectedCount = days * categories.length;
    if (tasks.length != expectedCount) {
      throw StateError(
        'Expected $expectedCount daily health tasks, got ${tasks.length}',
      );
    }

    if (startDate == null) return;

    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final date = _dateKey(startDate.add(Duration(days: dayIndex)));
      final found = tasks
          .where((task) => task.taskDate == date)
          .map((task) => task.category)
          .toSet();
      if (!found.containsAll(categories)) {
        throw StateError('Missing daily health categories for $date');
      }
    }
  }
}
