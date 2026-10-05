import 'dart:convert';
import 'dart:math';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/core/storage/localdb/tables/fitness_training_programs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/fitness_training_catalog.dart';
import '../../domain/entities/fitness_training_program.dart';
import '../../domain/repositories/fitness_training_repository.dart';
import '../../domain/services/fitness_program_validator.dart';

class FitnessTrainingLocalDatasource implements FitnessTrainingRepository {
  const FitnessTrainingLocalDatasource({
    this.databaseOverride,
    this.idGenerator,
  });

  final Database? databaseOverride;
  final String Function()? idGenerator;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  @override
  Future<bool> guestInitialPlanAvailable(String userId) async {
    final db = await _db();
    final rows = await db.query(
      'users',
      columns: ['guest_initial_plan_used'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return !_asBool(rows.first['guest_initial_plan_used']);
  }

  @override
  Future<List<FitnessTrainingProgram>> loadPrograms(String userId) async {
    final db = await _db();
    final rows = await db.query(
      FitnessTrainingProgramsTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_programFromRow).toList(growable: false);
  }

  @override
  Future<FitnessTrainingProgram?> findByRequestId(
    String userId,
    String requestId,
  ) async {
    final db = await _db();
    final rows = await db.query(
      FitnessTrainingProgramsTable.tableName,
      where: 'user_id = ? AND request_id = ?',
      whereArgs: [userId, requestId],
      limit: 1,
    );
    return rows.isEmpty ? null : _programFromRow(rows.first);
  }

  @override
  Future<FitnessTrainingProgram> savePreview(
    FitnessTrainingProgram program, {
    required bool guest,
  }) async {
    final db = await _db();
    FitnessTrainingProgram? saved;
    await db.transaction((txn) async {
      final existing = await txn.query(
        FitnessTrainingProgramsTable.tableName,
        where: 'user_id = ? AND request_id = ?',
        whereArgs: [program.userId, program.requestId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        saved = _programFromRow(existing.first);
        return;
      }

      if (guest) {
        final changed = await txn.update(
          'users',
          {'guest_initial_plan_used': 1},
          where: 'id = ? AND COALESCE(guest_initial_plan_used, 0) = 0',
          whereArgs: [program.userId],
        );
        if (changed != 1) {
          throw const FitnessTrainingGuestQuotaExceededException();
        }
      }

      final preview = program.copyWith(
        status: FitnessProgramStatus.preview,
        quotaCommitted: guest,
      );
      await txn.insert(
        FitnessTrainingProgramsTable.tableName,
        _programRow(preview),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      saved = preview;
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    if (saved == null) throw StateError('Fitness preview was not saved.');
    return saved!;
  }

  @override
  Future<void> markQuotaCommitted({
    required String userId,
    required String programId,
  }) async {
    final db = await _db();
    await db.transaction((txn) async {
      final rows = await txn.query(
        FitnessTrainingProgramsTable.tableName,
        where: 'id = ? AND user_id = ?',
        whereArgs: [programId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Fitness preview was not found.');
      final program = _programFromRow(
        rows.first,
      ).copyWith(quotaCommitted: true, updatedAt: DateTime.now().toUtc());
      await txn.update(
        FitnessTrainingProgramsTable.tableName,
        _programRow(program),
        where: 'id = ? AND user_id = ?',
        whereArgs: [programId, userId],
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  @override
  Future<FitnessTrainingProgram> saveCheckIn({
    required String userId,
    required String programId,
    required FitnessWeeklyCheckIn checkIn,
  }) async {
    final db = await _db();
    late FitnessTrainingProgram updated;
    await db.transaction((txn) async {
      final rows = await txn.query(
        FitnessTrainingProgramsTable.tableName,
        where: 'id = ? AND user_id = ? AND status = ?',
        whereArgs: [programId, userId, FitnessProgramStatus.active],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Active fitness program was not found.');
      }
      final current = _programFromRow(rows.first);
      final withoutWeek = current.checkIns
          .where((item) => item.week != checkIn.week)
          .toList(growable: false);
      updated = current.copyWith(
        checkIns: [...withoutWeek, checkIn],
        updatedAt: DateTime.now().toUtc(),
      );
      await txn.update(
        FitnessTrainingProgramsTable.tableName,
        _programRow(updated),
        where: 'id = ? AND user_id = ?',
        whereArgs: [programId, userId],
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return updated;
  }

  @override
  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required FitnessTrainingCatalog catalog,
  }) async {
    if (week < 1 || week > 4) throw ArgumentError.value(week, 'week');
    final db = await _db();
    late FitnessTrainingProgram applied;
    await db.transaction((txn) async {
      final rows = await txn.query(
        FitnessTrainingProgramsTable.tableName,
        where: 'id = ? AND user_id = ?',
        whereArgs: [programId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Fitness program was not found.');
      final target = _programFromRow(rows.first);
      if (target.status == FitnessProgramStatus.archived ||
          !target.quotaCommitted) {
        throw StateError('Fitness preview is not ready to apply.');
      }
      if (target.status == FitnessProgramStatus.preview &&
          target.activeWeek != week) {
        throw StateError('Fitness preview week does not match.');
      }

      final now = DateTime.now().toUtc();
      applied = target.copyWith(
        status: FitnessProgramStatus.active,
        activeWeek: week,
        updatedAt: now,
      );

      await txn.update(
        FitnessTrainingProgramsTable.tableName,
        {'status': FitnessProgramStatus.archived, 'updated_at': _stamp(now)},
        where: 'user_id = ? AND status = ? AND id != ?',
        whereArgs: [userId, FitnessProgramStatus.active, programId],
      );

      final todayKey = _dateKey(today);
      await txn.delete(
        LifestyleScheduleItemsTable.tableName,
        where:
            'user_id = ? AND source_type = ? AND is_completed = 0 '
            'AND (schedule_date > ? OR (schedule_date = ? AND start_time >= ?))',
        whereArgs: [
          userId,
          'fitness_training',
          todayKey,
          todayKey,
          '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}',
        ],
      );

      await _upsertWeekSchedule(
        txn: txn,
        program: applied,
        week: week,
        today: today,
        catalog: catalog,
      );
      await txn.update(
        FitnessTrainingProgramsTable.tableName,
        _programRow(applied),
        where: 'id = ? AND user_id = ?',
        whereArgs: [programId, userId],
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return applied;
  }

  Future<void> _upsertWeekSchedule({
    required Transaction txn,
    required FitnessTrainingProgram program,
    required int week,
    required DateTime today,
    required FitnessTrainingCatalog catalog,
  }) async {
    final items = <LifestyleScheduleItemModel>[];
    final baseIndex = (week - 1) * 7;
    final now = DateTime.now().toUtc();
    final todayKey = _dateKey(today);
    final currentTime =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    for (final day in program.days) {
      final dayKey = _dateKey(day.date);
      if (day.dayIndex < baseIndex ||
          day.dayIndex >= baseIndex + 7 ||
          dayKey.compareTo(todayKey) < 0) {
        continue;
      }
      var order = 0;
      if (!day.isRestDay &&
          day.exercises.isNotEmpty &&
          _isFutureOccurrence(
            dayKey,
            program.intake.workoutTime,
            todayKey,
            currentTime,
          )) {
        final detail = <String>[];
        for (final planned in day.exercises) {
          final exercise = catalog.exercisesById[planned.exerciseId];
          if (exercise == null) throw StateError('Exercise catalog changed.');
          final dosage = planned.durationMinutes != null
              ? '${planned.durationMinutes} phút'
              : '${planned.sets} hiệp × ${planned.reps} lần';
          detail.add('${exercise.name}: $dosage');
        }
        items.add(
          _scheduleItem(
            program: program,
            day: day,
            title: program.intake.venue == 'home'
                ? 'Buổi tập tại nhà'
                : 'Buổi tập Gym',
            description: detail.join('\n'),
            category: 'routine',
            startTime: program.intake.workoutTime,
            endTime: _addMinutes(
              program.intake.workoutTime,
              program.intake.sessionMinutes,
            ),
            sortOrder: order++,
            now: now,
          ),
        );
      }

      final mealRanks = {
        for (
          var index = 0;
          index < FitnessProgramValidator.mealSlots.length;
          index++
        )
          FitnessProgramValidator.mealSlots[index]: index,
      };
      final orderedMeals = [...day.meals]
        ..sort(
          (a, b) => mealRanks[a.mealSlot]!.compareTo(mealRanks[b.mealSlot]!),
        );
      for (final meal in orderedMeals) {
        final recipe = catalog.recipesById[meal.recipeId];
        if (recipe == null) throw StateError('Recipe catalog changed.');
        final mealTime =
            mealRanks[meal.mealSlot]! < program.intake.mealTimes.length
            ? program.intake.mealTimes[mealRanks[meal.mealSlot]!]
            : '12:00';
        if (!_isFutureOccurrence(dayKey, mealTime, todayKey, currentTime)) {
          continue;
        }
        final nutrients = recipe.nutrientsPerServing;
        final description = [
          ...recipe.steps,
          'Khẩu phần: ${meal.servings.toStringAsFixed(1)}',
          if (nutrients['energy_kcal'] != null)
            'Năng lượng tham khảo: ${nutrients['energy_kcal']!.round()} kcal',
          if (nutrients['protein_g'] != null)
            'Đạm: ${nutrients['protein_g']!.round()} g',
        ].join('\n');
        items.add(
          _scheduleItem(
            program: program,
            day: day,
            title: recipe.name,
            description: description,
            category: 'meal',
            startTime: mealTime,
            sortOrder: order++,
            now: now,
          ),
        );
      }

      if (_isFutureOccurrence(dayKey, day.sleepTime, todayKey, currentTime)) {
        items.add(
          _scheduleItem(
            program: program,
            day: day,
            title: 'Chuẩn bị giờ ngủ',
            description:
                'Giờ ngủ mục tiêu ${day.sleepTime}, thức dậy ${day.wakeTime}. Đây là lịch nhắc wellness.',
            category: 'sleep',
            startTime: day.sleepTime,
            endTime: day.wakeTime,
            sortOrder: order,
            now: now,
          ),
        );
      }
    }

    final batch = txn.batch();
    for (final item in items) {
      batch.insert(
        LifestyleScheduleItemsTable.tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  LifestyleScheduleItemModel _scheduleItem({
    required FitnessTrainingProgram program,
    required FitnessProgramDay day,
    required String title,
    required String description,
    required String category,
    required String startTime,
    String? endTime,
    required int sortOrder,
    required DateTime now,
  }) => LifestyleScheduleItemModel(
    id: _newId(),
    userId: program.userId,
    scheduleDate: _dateKey(day.date),
    startTime: startTime,
    endTime: endTime ?? '',
    title: title,
    description: description,
    category: category,
    sourceType: 'fitness_training',
    sourceId: program.id,
    sortOrder: sortOrder,
    isCompleted: false,
    aiGenerated: true,
    encouragement: 'Điều chỉnh nhẹ nhàng theo cảm nhận của bạn.',
    createdAt: _stamp(now),
    updatedAt: _stamp(now),
  );

  Map<String, Object?> _programRow(FitnessTrainingProgram program) => {
    'id': program.id,
    'user_id': program.userId,
    'request_id': program.requestId,
    'status': program.status,
    'active_week': program.activeWeek,
    'quota_committed': program.quotaCommitted ? 1 : 0,
    'parent_program_id': program.parentProgramId,
    'program_json': jsonEncode(program.toJson()),
    'created_at': _stamp(program.createdAt),
    'updated_at': _stamp(program.updatedAt),
  };

  FitnessTrainingProgram _programFromRow(Map<String, Object?> row) {
    final source = row['program_json'];
    final decoded = source is String ? jsonDecode(source) : source;
    if (decoded is! Map) {
      throw const FormatException('Invalid fitness program.');
    }
    final map = Map<String, Object?>.from(decoded);
    map['id'] = row['id'];
    map['user_id'] = row['user_id'];
    map['request_id'] = row['request_id'];
    map['status'] = row['status'];
    map['active_week'] = row['active_week'];
    map['quota_committed'] = _asBool(row['quota_committed']);
    map['parent_program_id'] = row['parent_program_id'];
    map['created_at'] = row['created_at'];
    map['updated_at'] = row['updated_at'];
    return FitnessTrainingProgram.fromJson(map);
  }

  String _newId() => idGenerator?.call() ?? _uuidV4();

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _stamp(DateTime value) => value.toUtc().toIso8601String();

  bool _isFutureOccurrence(
    String date,
    String startTime,
    String today,
    String currentTime,
  ) => date != today || startTime.compareTo(currentTime) >= 0;

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return time;
    final total = (hour * 60 + minute + minutes) % (24 * 60);
    return '${(total ~/ 60).toString().padLeft(2, '0')}:'
        '${(total % 60).toString().padLeft(2, '0')}';
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString() == '1' || value?.toString() == 'true';
  }
}
