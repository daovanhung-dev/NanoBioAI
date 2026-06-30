import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

class GeneratedPlanActorModes {
  const GeneratedPlanActorModes._();

  static const initialGuest = 'initial_guest';
  static const memberNew = 'member_new';
}

class GeneratedPlanRequestStatuses {
  const GeneratedPlanRequestStatuses._();

  static const generating = 'generating';
  static const succeeded = 'succeeded';
  static const failed = 'failed';
}

class PersonalScheduleAiRequestRecord {
  final String requestId;
  final String userId;
  final String actorMode;
  final String status;
  final DateTime? startDate;
  final int days;
  final int mealCount;
  final int exerciseCount;
  final int scheduleItemCount;
  final String? errorCode;

  const PersonalScheduleAiRequestRecord({
    required this.requestId,
    required this.userId,
    required this.actorMode,
    required this.status,
    required this.startDate,
    required this.days,
    required this.mealCount,
    required this.exerciseCount,
    required this.scheduleItemCount,
    this.errorCode,
  });

  factory PersonalScheduleAiRequestRecord.fromMap(Map<String, Object?> map) {
    return PersonalScheduleAiRequestRecord(
      requestId: map['request_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      actorMode: map['actor_mode']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? ''),
      days: _readInt(map['days'], fallback: 7),
      mealCount: _readInt(map['meal_count']),
      exerciseCount: _readInt(map['exercise_count']),
      scheduleItemCount: _readInt(map['schedule_item_count']),
      errorCode: map['error_code']?.toString(),
    );
  }

  bool get isSucceeded =>
      status == GeneratedPlanRequestStatuses.succeeded &&
      startDate != null &&
      scheduleItemCount > 0;

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

abstract class PersonalScheduleAiRequestStore {
  Future<PersonalScheduleAiRequestRecord?> findByRequestId(String requestId);

  Future<bool> isGuestInitialPlanUsed(String userId);

  Future<void> markGenerating({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
  });

  Future<void> markFailed({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required String errorCode,
  });

  Future<void> commitGeneratedPlan({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required List<MealPlanModel> meals,
    required List<LifestyleScheduleItemModel> schedule,
    required bool replaceExistingRange,
    required bool markGuestInitialPlanUsed,
  });
}

class LocalPersonalScheduleAiRequestStore
    implements PersonalScheduleAiRequestStore {
  final Database? databaseOverride;
  final DateTime Function() _now;

  LocalPersonalScheduleAiRequestStore({
    this.databaseOverride,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  @override
  Future<PersonalScheduleAiRequestRecord?> findByRequestId(
    String requestId,
  ) async {
    final db = await _db();
    final rows = await db.query(
      PersonalScheduleAiRequestsTable.tableName,
      where: 'request_id = ?',
      whereArgs: [requestId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PersonalScheduleAiRequestRecord.fromMap(rows.first);
  }

  @override
  Future<bool> isGuestInitialPlanUsed(String userId) async {
    final db = await _db();
    final rows = await db.query(
      'users',
      columns: ['guest_initial_plan_used'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final value = rows.first['guest_initial_plan_used'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  @override
  Future<void> markGenerating({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
  }) async {
    final db = await _db();
    await _upsertRequest(
      db,
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.generating,
      startDate: startDate,
      days: days,
    );
  }

  @override
  Future<void> markFailed({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required String errorCode,
  }) async {
    final db = await _db();
    await _upsertRequest(
      db,
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.failed,
      startDate: startDate,
      days: days,
      errorCode: errorCode,
      completedAt: _now().toIso8601String(),
    );
  }

  @override
  Future<void> commitGeneratedPlan({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required List<MealPlanModel> meals,
    required List<LifestyleScheduleItemModel> schedule,
    required bool replaceExistingRange,
    required bool markGuestInitialPlanUsed,
  }) async {
    final db = await _db();
    await db.transaction((txn) async {
      if (replaceExistingRange) {
        final endDate = startDate.add(Duration(days: days - 1));
        await txn.delete(
          'meal_plans',
          where: 'user_id = ? AND plan_date >= ? AND plan_date <= ?',
          whereArgs: [userId, _dateKey(startDate), _dateKey(endDate)],
        );
        await txn.delete(
          'lifestyle_schedule_items',
          where: 'user_id = ? AND schedule_date >= ? AND schedule_date <= ?',
          whereArgs: [userId, _dateKey(startDate), _dateKey(endDate)],
        );
      }

      final batch = txn.batch();
      for (final meal in meals) {
        batch.insert(
          'meal_plans',
          meal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in schedule) {
        batch.insert(
          'lifestyle_schedule_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      await _upsertRequest(
        txn,
        requestId: requestId,
        userId: userId,
        actorMode: actorMode,
        status: GeneratedPlanRequestStatuses.succeeded,
        startDate: startDate,
        days: days,
        mealCount: meals.length,
        exerciseCount: schedule
            .where((item) => item.sourceType == 'exercise_task')
            .length,
        scheduleItemCount: schedule.length,
        completedAt: _now().toIso8601String(),
      );

      if (markGuestInitialPlanUsed) {
        await txn.update(
          'users',
          {
            'guest_initial_plan_used': 1,
            'updated_at': _now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  Future<void> _upsertRequest(
    DatabaseExecutor db, {
    required String requestId,
    required String userId,
    required String actorMode,
    required String status,
    required DateTime startDate,
    required int days,
    int mealCount = 0,
    int exerciseCount = 0,
    int scheduleItemCount = 0,
    String? errorCode,
    String? completedAt,
  }) async {
    final now = _now().toIso8601String();
    await db.insert(
      PersonalScheduleAiRequestsTable.tableName,
      {
        'request_id': requestId,
        'user_id': userId,
        'actor_mode': actorMode,
        'status': status,
        'start_date': _dateKey(startDate),
        'days': days,
        'meal_count': mealCount,
        'exercise_count': exerciseCount,
        'schedule_item_count': scheduleItemCount,
        'error_code': errorCode,
        'created_at': now,
        'updated_at': now,
        'completed_at': completedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
