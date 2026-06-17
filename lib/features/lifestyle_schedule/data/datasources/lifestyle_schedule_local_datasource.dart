import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';
import '../daos/lifestyle_schedule_items_dao.dart';
import '../models/lifestyle_schedule_item_model.dart';
import '../models/lifestyle_schedule_timeline_builder.dart';

class LifestyleScheduleLocalDatasource {
  final Database? databaseOverride;
  final DateTime Function() _now;

  LifestyleScheduleLocalDatasource({
    this.databaseOverride,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<void> seedGeneratedSchedule(
    List<LifestyleScheduleItemModel> items, {
    bool requireComplete = false,
    DateTime? startDate,
    int days = 7,
  }) async {
    if (requireComplete) {
      _validateGeneratedSchedule(items, startDate: startDate, days: days);
    }

    final db = await _db();
    await LifestyleScheduleItemsDao(db).upsertMany(items);
  }

  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({
    DateTime? anchorDate,
  }) async {
    final db = await _db();
    final user = await _fetchLatestUser(db);
    final userId = user['id'].toString();
    final fullName = user['full_name']?.toString() ?? 'ban';
    final start = _dateOnly(anchorDate ?? _now());
    final end = start.add(const Duration(days: 6));

    final items = await LifestyleScheduleItemsDao(db).getByDateRange(
      userId: userId,
      startDate: _dateKey(start),
      endDate: _dateKey(end),
    );

    return LifestyleScheduleSummaryEntity(
      userId: userId,
      fullName: fullName,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }

  Future<List<MealPlanModel>> getMealPlansForScheduleSeed() async {
    final db = await _db();
    return MealPlansDao(db).getAll();
  }

  Future<LifestyleScheduleItemEntity> updateItemCompletion({
    required LifestyleScheduleItemEntity item,
    required bool isCompleted,
  }) async {
    final db = await _db();
    if (isCompleted && !_canCompleteNow(item)) {
      throw StateError('Task can only be completed from ${item.startTime}');
    }

    final now = _now().toIso8601String();
    final currentValue = isCompleted ? item.targetValue : 0.0;
    final updated = item.copyWith(
      currentValue: currentValue,
      isCompleted: isCompleted,
      updatedAt: now,
    );

    await LifestyleScheduleItemsDao(
      db,
    ).update(LifestyleScheduleItemModel.fromEntity(updated));

    if (item.isMealLinked) {
      await MealPlansDao(
        db,
      ).updateCompleted(id: item.sourceId!, isCompleted: isCompleted);
    }

    if (item.isDailyTaskLinked) {
      final dao = DailyHealthTasksDao(db);
      final task = await dao.getById(item.sourceId!);
      if (task != null) {
        await dao.updateTask(
          task.copyWith(
            currentValue: isCompleted ? task.targetValue : 0,
            isCompleted: isCompleted,
            updatedAt: now,
          ),
        );
      }
    }

    await _syncDailyScheduleScore(db, updated);

    return updated;
  }

  Future<Map<String, Object?>> _fetchLatestUser(Database db) async {
    final users = await db.query('users', orderBy: 'created_at DESC', limit: 1);
    if (users.isEmpty) {
      throw Exception('Chua co du lieu nguoi dung trong SQLite.');
    }
    return users.first;
  }

  void _validateGeneratedSchedule(
    List<LifestyleScheduleItemModel> items, {
    required DateTime? startDate,
    required int days,
  }) {
    if (startDate == null) {
      if (items.isEmpty) throw StateError('Lifestyle schedule is empty');
      return;
    }

    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final date = _dateKey(startDate.add(Duration(days: dayIndex)));
      final dayItems = items
          .where((item) => item.scheduleDate == date)
          .toList(growable: false);
      final mealCount = dayItems
          .where(
            (item) => item.sourceType == LifestyleScheduleSourceTypes.mealPlan,
          )
          .length;
      final exerciseCount = dayItems
          .where(
            (item) =>
                item.sourceType == LifestyleScheduleSourceTypes.exerciseTask,
          )
          .length;
      final routineCount = dayItems
          .where(
            (item) =>
                item.sourceType == LifestyleScheduleSourceTypes.aiSchedule,
          )
          .length;

      if (dayItems.length != LifestyleScheduleTimelineBuilder.itemsPerDay) {
        throw StateError(
          'Expected ${LifestyleScheduleTimelineBuilder.itemsPerDay} schedule items for $date',
        );
      }
      if (mealCount != LifestyleScheduleTimelineBuilder.mealItemsPerDay) {
        throw StateError('Missing meal schedule items for $date');
      }
      if (exerciseCount !=
          LifestyleScheduleTimelineBuilder.exerciseItemsPerDay) {
        throw StateError('Missing exercise schedule items for $date');
      }
      if (routineCount != LifestyleScheduleTimelineBuilder.routineItemsPerDay) {
        throw StateError('Missing routine schedule items for $date');
      }
    }
  }

  bool _canCompleteNow(LifestyleScheduleItemEntity item) {
    final scheduledAt = _scheduledAt(item);
    if (scheduledAt == null) return true;
    return !_now().isBefore(scheduledAt);
  }

  DateTime? _scheduledAt(LifestyleScheduleItemEntity item) {
    final date = DateTime.tryParse(item.scheduleDate);
    final parts = item.startTime.split(':');
    if (date == null || parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _syncDailyScheduleScore(
    Database db,
    LifestyleScheduleItemEntity item,
  ) async {
    final userId = item.userId;
    if (userId == null || userId.isEmpty) return;

    final items = await LifestyleScheduleItemsDao(
      db,
    ).getByDate(userId: userId, scheduleDate: item.scheduleDate);
    if (items.isEmpty) return;

    final completed = items.where((entry) => entry.isCompleted).length;
    final score = ((completed / items.length) * 100).round();
    final dao = HealthTrackingLogsDao(db);
    final existing = await dao.getByUserAndDate(
      userId: userId,
      logDate: item.scheduleDate,
    );
    final now = _now().toIso8601String();
    final current =
        existing ??
        HealthTrackingLogModel(
          id: 'health_log_${userId}_${item.scheduleDate}',
          userId: userId,
          logDate: item.scheduleDate,
          createdAt: now,
          updatedAt: now,
        );

    await dao.upsertByUserAndDate(
      current.copyWith(dailyScore: score, updatedAt: now),
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
