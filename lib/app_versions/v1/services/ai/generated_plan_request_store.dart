import 'dart:convert';

import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_staging_table.dart';
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

class GeneratedPlanStagingSnapshot {
  final int invocationCount;
  final Map<String, List<Map<String, dynamic>>> chunks;
  final Map<String, PlanGenerationSource> chunkSources;

  const GeneratedPlanStagingSnapshot({
    required this.invocationCount,
    required this.chunks,
    this.chunkSources = const {},
  });
}

class PersonalScheduleAiInvocationLimitException implements Exception {
  static const userMessage =
      'Đã tạm dừng sau nhiều lượt thử. Bạn có thể tiếp tục lịch này sau.';

  const PersonalScheduleAiInvocationLimitException();

  @override
  String toString() => userMessage;
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
  final PlanGenerationSource generationSource;
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
    this.generationSource = PlanGenerationSource.unknown,
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
      generationSource: PlanGenerationSource.fromStorage(
        map['generation_source'],
      ),
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

  Future<String?> findIncompleteRequestId({
    required String userId,
    required String actorMode,
    DateTime? startDate,
    required int days,
  });

  Future<GeneratedPlanStagingSnapshot> prepareStaging({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
  });

  Future<int> incrementBackendInvocationCount({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
  });

  Future<void> saveStagedChunk({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
    required String chunkKey,
    required List<Map<String, dynamic>> payload,
    PlanGenerationSource source = PlanGenerationSource.ai,
  });

  Future<void> saveGeneratedPlanDay({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required int day,
    required List<MealPlanModel> meals,
    required List<LifestyleScheduleItemModel> schedule,
    required bool replaceExistingDay,
    required int mealCount,
    required int exerciseCount,
    required int scheduleItemCount,
    required PlanGenerationSource generationSource,
  });

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
    required PlanGenerationSource generationSource,
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
  Future<String?> findIncompleteRequestId({
    required String userId,
    required String actorMode,
    DateTime? startDate,
    required int days,
  }) async {
    final db = await _db();
    final where = StringBuffer(
      'user_id = ? AND actor_mode = ? AND days = ? AND status IN (?, ?)',
    );
    final whereArgs = <Object?>[
      userId,
      actorMode,
      days,
      GeneratedPlanRequestStatuses.generating,
      GeneratedPlanRequestStatuses.failed,
    ];
    if (startDate != null) {
      where.write(' AND start_date = ?');
      whereArgs.add(_dateKey(startDate));
    }
    final rows = await db.query(
      PersonalScheduleAiRequestsTable.tableName,
      columns: const ['request_id'],
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['request_id']?.toString();
  }

  @override
  Future<GeneratedPlanStagingSnapshot> prepareStaging({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
  }) async {
    final db = await _db();
    return db.transaction((txn) async {
      final table = PersonalScheduleAiStagingTable.tableName;
      final metaRows = await txn.query(
        table,
        where: 'request_id = ? AND chunk_key = ?',
        whereArgs: [requestId, _stagingMetaKey],
        limit: 1,
      );
      final now = _now().toIso8601String();
      if (metaRows.isEmpty ||
          metaRows.first['input_fingerprint'] != inputFingerprint ||
          metaRows.first['catalog_fingerprint'] != catalogFingerprint ||
          metaRows.first['prompt_version'] != promptVersion) {
        await txn.delete(
          table,
          where: 'request_id = ?',
          whereArgs: [requestId],
        );
        await txn.insert(table, {
          'request_id': requestId,
          'chunk_key': _stagingMetaKey,
          'input_fingerprint': inputFingerprint,
          'catalog_fingerprint': catalogFingerprint,
          'prompt_version': promptVersion,
          'payload_json': '{}',
          'invocation_count': 0,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        // A new explicit continuation gets a fresh bounded call window while
        // retaining previously validated daily chunks.
        await txn.update(
          table,
          {'invocation_count': 0, 'updated_at': now},
          where: 'request_id = ? AND chunk_key = ?',
          whereArgs: [requestId, _stagingMetaKey],
        );
      }

      final rows = await txn.query(
        table,
        where: 'request_id = ? AND chunk_key != ?',
        whereArgs: [requestId, _stagingMetaKey],
        orderBy: 'chunk_key ASC',
      );
      final chunks = <String, List<Map<String, dynamic>>>{};
      final chunkSources = <String, PlanGenerationSource>{};
      for (final row in rows) {
        final decoded = jsonDecode(row['payload_json']?.toString() ?? '[]');
        final chunkKey = row['chunk_key']!.toString();
        if (decoded is List) {
          // Old v5 staging rows contain only the validated item list. Treat
          // their provenance as unknown so resumed work is never billed as
          // fully AI generated by assumption.
          chunks[chunkKey] = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
          chunkSources[chunkKey] = PlanGenerationSource.unknown;
          continue;
        }
        if (decoded is! Map || decoded['items'] is! List) {
          throw const FormatException('Invalid generated-plan staging data.');
        }
        chunks[chunkKey] = (decoded['items'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        chunkSources[chunkKey] = PlanGenerationSource.fromStorage(
          decoded['source'],
        );
      }
      return GeneratedPlanStagingSnapshot(
        invocationCount: 0,
        chunks: chunks,
        chunkSources: chunkSources,
      );
    });
  }

  @override
  Future<int> incrementBackendInvocationCount({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
  }) async {
    final db = await _db();
    return db.transaction((txn) async {
      final rows = await txn.query(
        PersonalScheduleAiStagingTable.tableName,
        columns: const [
          'input_fingerprint',
          'catalog_fingerprint',
          'prompt_version',
          'invocation_count',
        ],
        where: 'request_id = ? AND chunk_key = ?',
        whereArgs: [requestId, _stagingMetaKey],
        limit: 1,
      );
      if (rows.isEmpty ||
          rows.first['input_fingerprint'] != inputFingerprint ||
          rows.first['catalog_fingerprint'] != catalogFingerprint ||
          rows.first['prompt_version'] != promptVersion) {
        throw StateError('Generated-plan staging fingerprint changed.');
      }
      final current = _readInt(rows.first['invocation_count']);
      if (current >= maxBackendInvocationsPerSession) {
        throw const PersonalScheduleAiInvocationLimitException();
      }
      final next = current + 1;
      await txn.update(
        PersonalScheduleAiStagingTable.tableName,
        {'invocation_count': next, 'updated_at': _now().toIso8601String()},
        where: 'request_id = ? AND chunk_key = ?',
        whereArgs: [requestId, _stagingMetaKey],
      );
      return next;
    });
  }

  @override
  Future<void> saveStagedChunk({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
    required String chunkKey,
    required List<Map<String, dynamic>> payload,
    PlanGenerationSource source = PlanGenerationSource.ai,
  }) async {
    final db = await _db();
    final now = _now().toIso8601String();
    await db.transaction((txn) async {
      final metaRows = await txn.query(
        PersonalScheduleAiStagingTable.tableName,
        columns: const [
          'input_fingerprint',
          'catalog_fingerprint',
          'prompt_version',
        ],
        where: 'request_id = ? AND chunk_key = ?',
        whereArgs: [requestId, _stagingMetaKey],
        limit: 1,
      );
      if (metaRows.isEmpty ||
          metaRows.first['input_fingerprint'] != inputFingerprint ||
          metaRows.first['catalog_fingerprint'] != catalogFingerprint ||
          metaRows.first['prompt_version'] != promptVersion) {
        throw StateError('Generated-plan staging fingerprint changed.');
      }
      await txn.insert(PersonalScheduleAiStagingTable.tableName, {
        'request_id': requestId,
        'chunk_key': chunkKey,
        'input_fingerprint': inputFingerprint,
        'catalog_fingerprint': catalogFingerprint,
        'prompt_version': promptVersion,
        'payload_json': jsonEncode({
          'source': source.storageValue,
          'items': payload,
        }),
        'invocation_count': 0,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> saveGeneratedPlanDay({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required int day,
    required List<MealPlanModel> meals,
    required List<LifestyleScheduleItemModel> schedule,
    required bool replaceExistingDay,
    required int mealCount,
    required int exerciseCount,
    required int scheduleItemCount,
    required PlanGenerationSource generationSource,
  }) async {
    if (days < 1 || days > 7 || day < 1 || day > days) {
      throw RangeError.range(day, 1, days, 'day');
    }
    if (meals.length != 5 || schedule.isEmpty) {
      throw StateError('Generated schedule day is incomplete.');
    }
    final date = _dateKey(startDate.add(Duration(days: day - 1)));
    if (meals.any((meal) => meal.userId != userId || meal.planDate != date) ||
        schedule.any(
          (item) => item.userId != userId || item.scheduleDate != date,
        )) {
      throw StateError('Generated schedule day does not match its owner/date.');
    }

    final db = await _db();
    await db.transaction((txn) async {
      if (replaceExistingDay) {
        await txn.delete(
          'meal_plans',
          where: 'user_id = ? AND plan_date = ?',
          whereArgs: [userId, date],
        );
        await txn.delete(
          'lifestyle_schedule_items',
          where: 'user_id = ? AND schedule_date = ?',
          whereArgs: [userId, date],
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
        status: GeneratedPlanRequestStatuses.generating,
        startDate: startDate,
        days: days,
        mealCount: mealCount,
        exerciseCount: exerciseCount,
        scheduleItemCount: scheduleItemCount,
        generationSource: generationSource,
      );
    });
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
    required PlanGenerationSource generationSource,
    required bool markGuestInitialPlanUsed,
  }) async {
    final db = await _db();
    if (meals.map((meal) => meal.id).toSet().length != meals.length ||
        schedule.map((item) => item.id).toSet().length != schedule.length) {
      throw StateError('Generated plan contains duplicate SQLite row IDs.');
    }
    await db.transaction((txn) async {
      // Each validated day was already committed atomically by
      // saveGeneratedPlanDay(). Verify this request's own rows; unrelated
      // user-created entries in the same date range are allowed to remain.
      if (!await _hasExpectedRows(
            txn,
            table: 'meal_plans',
            dateColumn: 'plan_date',
            userId: userId,
            expectedDates: {for (final meal in meals) meal.id: meal.planDate},
          ) ||
          !await _hasExpectedRows(
            txn,
            table: 'lifestyle_schedule_items',
            dateColumn: 'schedule_date',
            userId: userId,
            expectedDates: {
              for (final item in schedule) item.id: item.scheduleDate,
            },
          )) {
        throw StateError('Generated plan rows are incomplete in SQLite.');
      }

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
        generationSource: generationSource,
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
      await txn.delete(
        PersonalScheduleAiStagingTable.tableName,
        where: 'request_id = ?',
        whereArgs: [requestId],
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  Future<bool> _hasExpectedRows(
    DatabaseExecutor db, {
    required String table,
    required String dateColumn,
    required String userId,
    required Map<String, String> expectedDates,
  }) async {
    if (expectedDates.isEmpty || expectedDates.length > 900) return false;
    final ids = expectedDates.keys.toList(growable: false);
    final rows = await db.query(
      table,
      columns: ['id', dateColumn],
      where:
          'user_id = ? AND id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: [userId, ...ids],
    );
    if (rows.length != expectedDates.length) return false;
    return rows.every(
      (row) =>
          expectedDates[row['id']?.toString()] == row[dateColumn]?.toString(),
    );
  }

  Future<void> _upsertRequest(
    DatabaseExecutor db, {
    required String requestId,
    required String userId,
    required String actorMode,
    required String status,
    required DateTime startDate,
    required int days,
    int? mealCount,
    int? exerciseCount,
    int? scheduleItemCount,
    PlanGenerationSource? generationSource,
    String? errorCode,
    String? completedAt,
  }) async {
    final now = _now().toIso8601String();
    final existing = await db.query(
      PersonalScheduleAiRequestsTable.tableName,
      columns: const [
        'user_id',
        'actor_mode',
        'meal_count',
        'exercise_count',
        'schedule_item_count',
        'generation_source',
      ],
      where: 'request_id = ?',
      whereArgs: [requestId],
      limit: 1,
    );
    final previous = existing.isEmpty ? null : existing.first;
    final values = {
      'user_id': userId,
      'actor_mode': actorMode,
      'status': status,
      'start_date': _dateKey(startDate),
      'days': days,
      'meal_count': mealCount ?? _readInt(previous?['meal_count']),
      'exercise_count': exerciseCount ?? _readInt(previous?['exercise_count']),
      'schedule_item_count':
          scheduleItemCount ?? _readInt(previous?['schedule_item_count']),
      'generation_source':
          (generationSource ??
                  PlanGenerationSource.fromStorage(
                    previous?['generation_source'],
                  ))
              .storageValue,
      'error_code': errorCode,
      'updated_at': now,
      'completed_at': completedAt,
    };
    if (existing.isNotEmpty) {
      if (existing.first['user_id'] != userId ||
          existing.first['actor_mode'] != actorMode) {
        throw StateError('Generated-plan request identity conflict.');
      }
      await db.update(
        PersonalScheduleAiRequestsTable.tableName,
        values,
        where: 'request_id = ?',
        whereArgs: [requestId],
      );
      return;
    }
    await db.insert(PersonalScheduleAiRequestsTable.tableName, {
      'request_id': requestId,
      ...values,
      'created_at': now,
    });
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static const _stagingMetaKey = '__meta__';
  static const maxBackendInvocationsPerSession = 300;

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
