import 'dart:convert';

import 'package:nano_app/core/storage/localdb/daos/health_score_ledgers_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/health_score_ledger_model.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';
import '../../domain/services/daily_schedule_score_service.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';
import '../../domain/services/schedule_completion_exception.dart';
import '../daos/lifestyle_schedule_items_dao.dart';
import '../daos/schedule_completion_proofs_dao.dart';
import '../models/lifestyle_schedule_item_model.dart';
import '../models/schedule_completion_proof_model.dart';
import '../models/lifestyle_schedule_timeline_builder.dart';

class LifestyleScheduleLocalDatasource {
  final Database? databaseOverride;
  final DateTime Function() _now;

  LifestyleScheduleLocalDatasource({
    this.databaseOverride,
    DateTime Function()? now,
  }) : _now = now ?? LifestyleScheduleWindowPolicy.vietnamNow;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<void> seedGeneratedSchedule(
    List<LifestyleScheduleItemModel> items, {
    bool requireComplete = false,
    bool replaceExistingRange = false,
    DateTime? startDate,
    int days = 7,
  }) async {
    if (requireComplete) {
      validateGeneratedSchedule(items, startDate: startDate, days: days);
    }

    final db = await _db();
    final dao = LifestyleScheduleItemsDao(db);
    if (replaceExistingRange && startDate != null && items.isNotEmpty) {
      final userId = items.first.userId;
      if (userId != null && userId.isNotEmpty) {
        await dao.deleteByUserIdAndDateRange(
          userId: userId,
          startDate: _dateKey(startDate),
          endDate: _dateKey(startDate.add(Duration(days: days - 1))),
        );
      }
    }

    await dao.upsertMany(items);
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  void validateGeneratedSchedule(
    List<LifestyleScheduleItemModel> items, {
    required DateTime? startDate,
    required int days,
  }) {
    _validateGeneratedSchedule(items, startDate: startDate, days: days);
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

  Future<List<MealPlanModel>> getMealPlansForScheduleSeed({
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    final db = await _db();
    final endDate = startDate.add(Duration(days: days - 1));
    return MealPlansDao(db).getByUserIdAndDateRange(
      userId: userId,
      startDate: _dateKey(startDate),
      endDate: _dateKey(endDate),
    );
  }

  Future<DateTime> getNextGeneratedPlanStartDate({
    required String userId,
    required DateTime fallbackStartDate,
  }) async {
    final db = await _db();
    final scheduleRows = await db.rawQuery(
      'SELECT MAX(schedule_date) AS last_date FROM lifestyle_schedule_items WHERE user_id = ?',
      [userId],
    );

    final lastScheduleDate = _readDate(scheduleRows.firstOrNull?['last_date']);
    if (lastScheduleDate == null) return _dateOnly(fallbackStartDate);

    final nextDate = lastScheduleDate.add(const Duration(days: 1));
    final fallback = _dateOnly(fallbackStartDate);
    return nextDate.isBefore(fallback) ? fallback : _dateOnly(nextDate);
  }

  Future<LifestyleScheduleItemEntity> updateItemCompletion({
    required LifestyleScheduleItemEntity item,
    required bool isCompleted,
    String? completionProofPath,
    String? completionProofCapturedAt,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) async {
    final db = await _db();
    final nowDate = _now();
    final proofPath = completionProofPath?.trim();
    if (isCompleted && (proofPath == null || proofPath.isEmpty)) {
      throw const ScheduleCompletionException(
        ScheduleCompletionErrorCode.proofRequired,
        'Bạn cần chụp ảnh minh chứng trước khi hoàn thành nhiệm vụ.',
      );
    }
    final now = nowDate.toIso8601String();
    final updated = await db.transaction((transaction) async {
      final scheduleDao = LifestyleScheduleItemsDao(transaction);
      final currentModel = await scheduleDao.getById(item.id);
      if (currentModel == null) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.notFound,
          'Nabi chưa tìm thấy nhiệm vụ này. Bạn tải lại lịch trình nhé.',
        );
      }
      final current = currentModel.toEntity();
      _validateCompletionWindow(current, nowDate);

      if (isCompleted && current.isCompleted) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.alreadyCompleted,
          'Nhiệm vụ này đã được hoàn thành rồi.',
        );
      }
      if (!isCompleted && !current.isCompleted) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.notCompleted,
          'Nhiệm vụ này chưa được hoàn thành để hoàn tác.',
        );
      }

      final capturedAt = completionProofCapturedAt ?? now;
      final next = current.copyWith(
        currentValue: isCompleted ? current.targetValue : 0,
        isCompleted: isCompleted,
        completionProofPath: isCompleted ? proofPath : null,
        completionProofCapturedAt: isCompleted ? capturedAt : null,
        completedAt: isCompleted ? now : null,
        clearCompletionProof: !isCompleted,
        updatedAt: now,
      );
      await scheduleDao.update(LifestyleScheduleItemModel.fromEntity(next));

      final proofDao = ScheduleCompletionProofsDao(transaction);
      if (isCompleted) {
        final normalizedEligibilityId = _nonEmpty(rewardEligibilityId);
        await proofDao.insert(
          ScheduleCompletionProofModel(
            id: 'proof_${current.id}_${nowDate.microsecondsSinceEpoch}',
            userId: current.userId,
            scheduleItemId: current.id,
            rewardEligibilityId: normalizedEligibilityId,
            completionAttemptId: _nonEmpty(completionAttemptId),
            scheduleDate: current.scheduleDate,
            startTime: current.startTime,
            scheduleTitle: current.title,
            localPath: proofPath!,
            pathKind: _isAbsolutePath(proofPath)
                ? ScheduleProofPathKinds.legacyAbsolute
                : ScheduleProofPathKinds.relative,
            cloudObjectPath: _nonEmpty(completionProofCloudObjectPath),
            capturedAt: capturedAt,
            completedAt: now,
            uploadStatus: normalizedEligibilityId == null
                ? ScheduleProofUploadStatuses.localOnly
                : ScheduleProofUploadStatuses.pending,
            rewardStatus: normalizedEligibilityId == null
                ? ScheduleProofRewardStatuses.notEligible
                : ScheduleProofRewardStatuses.pending,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final projectionUserId = _nonEmpty(current.userId);
        if (normalizedEligibilityId != null && projectionUserId != null) {
          await _ensureRewardEligibilityProjection(transaction);
          await transaction.insert(
            ScheduleRewardEligibilityCacheTable.tableName,
            {
              'schedule_item_id': current.id,
              'user_id': projectionUserId,
              'eligibility_id': normalizedEligibilityId,
              'request_id': null,
              'status': 'completion_pending',
              'window_start': current.scheduledAt?.toIso8601String(),
              'window_end': current.completionDeadline?.toIso8601String(),
              'synced_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } else {
        final activeProof = await proofDao.getLatestActiveForSchedule(
          current.id,
        );
        if (activeProof != null) {
          await proofDao.markReversed(id: activeProof.id, reversedAt: now);
          if (activeProof.rewardEligibilityId != null) {
            await _ensureRewardEligibilityProjection(transaction);
            await transaction.update(
              ScheduleRewardEligibilityCacheTable.tableName,
              {'status': 'reversed', 'synced_at': now},
              where: 'schedule_item_id = ?',
              whereArgs: [current.id],
            );
          }
        }
      }

      if (current.isMealLinked) {
        await MealPlansDao(
          transaction,
        ).updateCompleted(id: current.sourceId!, isCompleted: isCompleted);
      }

      if (current.isDailyTaskLinked) {
        final taskDao = DailyHealthTasksDao(transaction);
        final task = await taskDao.getById(current.sourceId!);
        if (task != null) {
          await taskDao.updateTask(
            task.copyWith(
              currentValue: isCompleted ? task.targetValue : 0,
              isCompleted: isCompleted,
              updatedAt: now,
            ),
          );
        }
      }

      await _syncDailyScheduleScore(transaction, next, nowDate: nowDate);
      return next;
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);

    return updated;
  }

  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) async {
    final db = await _db();
    final item = await LifestyleScheduleItemsDao(db).getById(id);
    if (item == null) {
      throw const ScheduleCompletionException(
        ScheduleCompletionErrorCode.notFound,
        'Nabi chưa tìm thấy nhiệm vụ này. Bạn tải lại lịch trình nhé.',
      );
    }

    return updateItemCompletion(
      item: item.toEntity(),
      isCompleted: true,
      completionProofPath: completionProofPath,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
  }

  Future<List<ScheduleCompletionProofModel>> getCompletionProofs() async {
    final db = await _db();
    final user = await _fetchLatestUser(db);
    return ScheduleCompletionProofsDao(db).getByUser(user['id'].toString());
  }

  Future<void> updateCompletionProofRemoteState({
    required String proofId,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? cloudObjectPath,
    String? uploadStatus,
    String? rewardStatus,
  }) async {
    final db = await _db();
    final updatedAt = _now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final proofDao = ScheduleCompletionProofsDao(txn);
      final proof = await proofDao.getById(proofId);
      await proofDao.updateRemoteState(
        id: proofId,
        rewardEligibilityId: rewardEligibilityId,
        completionAttemptId: completionAttemptId,
        cloudObjectPath: cloudObjectPath,
        uploadStatus: uploadStatus,
        rewardStatus: rewardStatus,
        updatedAt: updatedAt,
      );
      if (proof != null && rewardStatus != null) {
        await _ensureRewardEligibilityProjection(txn);
        await txn.update(
          ScheduleRewardEligibilityCacheTable.tableName,
          {
            'eligibility_id': rewardEligibilityId ?? proof.rewardEligibilityId,
            'status': rewardStatus,
            'synced_at': updatedAt,
          },
          where: 'schedule_item_id = ?',
          whereArgs: [proof.scheduleItemId],
        );
      }
    });
  }

  Future<Map<String, Object?>> _fetchLatestUser(Database db) async {
    final users = await db.query('users', orderBy: 'created_at DESC', limit: 1);
    if (users.isEmpty) {
      throw StateError('Nabi chưa tìm thấy hồ sơ phù hợp để mở lịch chăm sóc.');
    }
    return users.first;
  }

  Future<void> _ensureRewardEligibilityProjection(DatabaseExecutor db) async {
    await db.execute(ScheduleRewardEligibilityCacheTable.createTable);
    await db.execute(ScheduleRewardEligibilityCacheTable.createUserStatusIndex);
    await db.execute(
      ScheduleRewardEligibilityCacheTable.createEligibilityIndex,
    );
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

  Future<void> _syncDailyScheduleScore(
    DatabaseExecutor db,
    LifestyleScheduleItemEntity item, {
    required DateTime nowDate,
  }) async {
    final userId = item.userId;
    if (userId == null || userId.isEmpty) return;

    final items = await LifestyleScheduleItemsDao(
      db,
    ).getByDate(userId: userId, scheduleDate: item.scheduleDate);
    if (items.isEmpty) return;

    final result = DailyScheduleScoreService.calculate(
      items: items.map((entry) => entry.toEntity()).toList(growable: false),
      scheduleDate: item.scheduleDate,
      now: nowDate,
    );
    final dao = HealthTrackingLogsDao(db);
    final existing = await dao.getByUserAndDate(
      userId: userId,
      logDate: item.scheduleDate,
    );
    final now = nowDate.toIso8601String();
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
      current.copyWith(dailyScore: result.score, updatedAt: now),
    );

    await HealthScoreLedgersDao(db).upsert(
      HealthScoreLedgerModel(
        id: 'health_score_${userId}_${item.scheduleDate}_${DailyScheduleScoreService.formulaVersion}',
        userId: userId,
        periodStart: item.scheduleDate,
        periodEnd: item.scheduleDate,
        score: result.score,
        formulaVersion: DailyScheduleScoreService.formulaVersion,
        breakdown: jsonEncode({
          'completed_due_items': result.completedDueItems,
          'due_items': result.dueItems,
          'source': 'lifestyle_schedule_items',
        }),
        idempotencyKey:
            'health_score:$userId:${item.scheduleDate}:${DailyScheduleScoreService.formulaVersion}',
        calculatedAt: now,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  void _validateCompletionWindow(
    LifestyleScheduleItemEntity item,
    DateTime now,
  ) {
    final scheduled = item.scheduledAt;
    if (scheduled == null) {
      throw const ScheduleCompletionException(
        ScheduleCompletionErrorCode.invalidScheduleTime,
        'Giờ của nhiệm vụ chưa hợp lệ nên Nabi đã tạm khóa thao tác này.',
      );
    }
    final status = LifestyleScheduleWindowPolicy.statusAt(
      scheduleDate: item.scheduleDate,
      startTime: item.startTime,
      isCompleted: false,
      now: now,
    );
    if (status == CompletionWindowStatus.waiting) {
      throw const ScheduleCompletionException(
        ScheduleCompletionErrorCode.waiting,
        'Nhiệm vụ chưa đến giờ thực hiện. Bạn quay lại đúng giờ nhé.',
      );
    }
    if (status == CompletionWindowStatus.locked) {
      throw const ScheduleCompletionException(
        ScheduleCompletionErrorCode.locked,
        'Nhiệm vụ đã hết thời gian thực hiện và được khóa.',
      );
    }
  }

  String? _nonEmpty(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool _isAbsolutePath(String value) {
    final normalized = value.trim();
    return normalized.startsWith('/') ||
        normalized.startsWith(r'\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(normalized);
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  DateTime? _readDate(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
