import 'dart:convert';
import 'dart:math';

import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/health_score_ledgers_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/health_score_ledger_model.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/manual_health_task_draft.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../domain/entities/schedule_health_reward_attempt_entity.dart';
import '../../domain/services/daily_schedule_score_service.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';
import '../../domain/services/schedule_completion_exception.dart';
import '../../domain/services/schedule_health_action_policy.dart';
import '../daos/lifestyle_schedule_items_dao.dart';
import '../daos/schedule_health_reward_attempts_dao.dart';
import '../models/lifestyle_schedule_item_model.dart';
import '../models/schedule_health_reward_attempt_model.dart';

class DailyHealthHubLocalDatasource {
  final Database? databaseOverride;
  final DateTime Function() _now;
  final Random _random;

  DailyHealthHubLocalDatasource({
    this.databaseOverride,
    DateTime Function()? now,
    Random? random,
  })  : _now = now ?? LifestyleScheduleWindowPolicy.vietnamNow,
        _random = random ?? Random.secure();

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<DailyHealthSnapshotEntity> getSnapshot(DateTime date) async {
    final db = await _db();
    final user = await _fetchLatestUser(db);
    final userId = user['id'].toString();
    final dateKey = _dateKey(date);
    final log = await HealthTrackingLogsDao(db).getByUserAndDate(
      userId: userId,
      logDate: dateKey,
    );
    return _snapshot(userId: userId, dateKey: dateKey, log: log);
  }

  Future<LifestyleScheduleItemEntity?> getScheduleItem(String id) async {
    final db = await _db();
    return (await LifestyleScheduleItemsDao(db).getById(id))?.toEntity();
  }

  Future<ScheduleHealthRewardAttemptEntity?> latestRewardAttempt(
    String scheduleItemId,
  ) async {
    final db = await _db();
    return (await ScheduleHealthRewardAttemptsDao(db)
            .latestForScheduleItem(scheduleItemId))
        ?.toEntity();
  }

  Future<List<ScheduleHealthRewardAttemptEntity>> pendingRewardAttempts({
    int limit = 20,
  }) async {
    final db = await _db();
    final rows = await ScheduleHealthRewardAttemptsDao(db).getPending(limit: limit);
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  Future<void> updateRewardAttempt({
    required String id,
    required String syncStatus,
    String? rewardStatus,
    int? pointsDelta,
    String? lastErrorCode,
  }) async {
    final db = await _db();
    await ScheduleHealthRewardAttemptsDao(db).updateResult(
      id: id,
      syncStatus: syncStatus,
      rewardStatus: rewardStatus,
      pointsDelta: pointsDelta,
      lastErrorCode: lastErrorCode,
      updatedAt: _now().toIso8601String(),
    );
  }

  Future<DailyHealthSnapshotEntity> recordStandaloneCheckIn({
    required DateTime date,
    required DailyHealthCheckInInput input,
  }) async {
    final now = _now();
    final requestedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (requestedDate.isAfter(today)) {
      throw const FormatException('Chưa thể ghi nhận sức khỏe cho ngày tương lai.');
    }
    if (input.isEmpty) {
      throw const FormatException('Bạn chưa chọn dữ liệu cần ghi nhận.');
    }
    _validateStandaloneInput(input);
    final db = await _db();
    final user = await _fetchLatestUser(db);
    final userId = user['id'].toString();
    final dateKey = _dateKey(date);
    late HealthTrackingLogModel updated;
    await db.transaction((txn) async {
      updated = await _mergeHealthLog(
        txn,
        userId: userId,
        dateKey: dateKey,
        input: input,
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return _snapshot(userId: userId, dateKey: dateKey, log: updated);
  }

  Future<List<LifestyleScheduleItemEntity>> createManualTaskSeries(
    ManualHealthTaskDraft draft,
  ) async {
    final db = await _db();
    final user = await _fetchLatestUser(db);
    final userId = user['id'].toString();
    final now = _now();
    final items = _buildManualTaskSeries(
      userId: userId,
      draft: draft,
      now: now,
    );

    await LifestyleScheduleItemsDao(db).upsertMany(items);
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  Future<List<LifestyleScheduleItemEntity>> replaceManualTaskSeries({
    required LifestyleScheduleItemEntity existingItem,
    required ManualHealthTaskDraft draft,
  }) async {
    if (!existingItem.isManualHealthTask) {
      throw const FormatException('Chỉ nhiệm vụ tự tạo mới có thể chỉnh sửa.');
    }
    if (ManualHealthTaskMetadata.tryParse(existingItem.sourceId) == null) {
      throw const FormatException('Nhiệm vụ tự tạo chưa có thông tin quản lý.');
    }

    final userId = existingItem.userId?.trim();
    final sourceId = existingItem.sourceId?.trim();
    if (userId == null ||
        userId.isEmpty ||
        sourceId == null ||
        sourceId.isEmpty) {
      throw StateError('Nabi chưa xác định được chủ sở hữu nhiệm vụ.');
    }

    final db = await _db();
    final now = _now();
    final items = _buildManualTaskSeries(
      userId: userId,
      draft: draft,
      now: now,
    );

    await db.transaction((txn) async {
      final dao = LifestyleScheduleItemsDao(txn);
      await dao.deleteBySource(
        userId: userId,
        sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
        sourceId: sourceId,
        fromDate: existingItem.scheduleDate,
      );
      await dao.upsertMany(items);
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  List<LifestyleScheduleItemModel> _buildManualTaskSeries({
    required String userId,
    required ManualHealthTaskDraft draft,
    required DateTime now,
  }) {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw FormatException(errors.first);

    final firstDate = DateTime(
      draft.firstDate.year,
      draft.firstDate.month,
      draft.firstDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (firstDate.isBefore(today)) {
      throw const FormatException('Ngày bắt đầu không thể nằm trong quá khứ.');
    }

    final occurrences = draft.occurrenceDates();
    if (occurrences.isEmpty) {
      throw const FormatException(
        'Không có ngày phù hợp với kiểu lặp lại đã chọn.',
      );
    }
    final firstScheduled = LifestyleScheduleWindowPolicy.parseScheduledAt(
      scheduleDate: _dateKey(occurrences.first),
      startTime: draft.startTime,
    );
    if (firstScheduled == null ||
        firstScheduled
            .add(LifestyleScheduleItemEntity.completionWindow)
            .isBefore(now)) {
      throw const FormatException(
        'Hãy chọn thời gian chưa kết thúc cửa sổ xác nhận.',
      );
    }

    final seriesId = _uuidV4();
    final metadata = ManualHealthTaskMetadata(
      seriesId: seriesId,
      actionType: draft.actionType,
      reminderEnabled: draft.reminderEnabled,
      repeat: draft.repeat,
    );
    final createdAt = now.toIso8601String();
    return occurrences.map((date) {
      return LifestyleScheduleItemModel(
        id: _uuidV4(),
        userId: userId,
        scheduleDate: _dateKey(date),
        startTime: draft.startTime,
        title: draft.title.trim(),
        description: draft.description.trim(),
        category: draft.category,
        sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
        sourceId: metadata.encode(),
        targetValue: 1,
        currentValue: 0,
        unit: 'lần',
        isCompleted: false,
        sortOrder: 900,
        aiGenerated: false,
        encouragement: ScheduleHealthActionPolicy.encouragement(
          draft.actionType,
        ),
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }).toList(growable: false);
  }

  Future<void> deleteManualTaskSeries(
    LifestyleScheduleItemEntity item, {
    bool fromThisDateForward = true,
  }) async {
    if (!item.isManualHealthTask) {
      throw const FormatException('Chỉ nhiệm vụ tự tạo mới có thể xóa.');
    }
    final userId = item.userId?.trim();
    final sourceId = item.sourceId?.trim();
    if (userId == null || userId.isEmpty || sourceId == null || sourceId.isEmpty) {
      throw StateError('Nabi chưa xác định được chuỗi nhiệm vụ cần xóa.');
    }

    final db = await _db();
    final dao = LifestyleScheduleItemsDao(db);
    final affected = await dao.getAllByUserId(userId);
    await dao.deleteBySource(
      userId: userId,
      sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
      sourceId: sourceId,
      fromDate: fromThisDateForward ? item.scheduleDate : null,
    );
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);

    final affectedDates = affected
        .where(
          (entry) =>
              entry.sourceId == sourceId &&
              (!fromThisDateForward ||
                  entry.scheduleDate.compareTo(item.scheduleDate) >= 0),
        )
        .map((entry) => entry.scheduleDate)
        .toSet();
    for (final dateKey in affectedDates) {
      final probe = LifestyleScheduleItemEntity(
        id: item.id,
        userId: userId,
        scheduleDate: dateKey,
        startTime: item.startTime,
        title: item.title,
        category: item.category,
        sourceType: item.sourceType,
      );
      await _syncDailyScheduleScore(db, probe, nowDate: _now());
    }
  }

  Future<LifestyleScheduleItemEntity> completeCheckInTask({
    required LifestyleScheduleItemEntity item,
    required DailyHealthCheckInInput input,
    bool queueReward = false,
  }) async {
    final action = ScheduleHealthActionPolicy.forItem(item);
    if (action == ScheduleHealthActionType.photoProof) {
      throw const FormatException(
        'Nhiệm vụ này cần ảnh minh chứng và phải dùng luồng camera.',
      );
    }
    _validateInput(action, input);

    final db = await _db();
    final nowDate = _now();
    final nowText = nowDate.toIso8601String();
    late LifestyleScheduleItemEntity updated;
    await db.transaction((txn) async {
      final scheduleDao = LifestyleScheduleItemsDao(txn);
      final currentModel = await scheduleDao.getById(item.id);
      if (currentModel == null) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.notFound,
          'Nabi chưa tìm thấy nhiệm vụ này. Bạn tải lại lịch trình nhé.',
        );
      }
      final current = currentModel.toEntity();
      _validateCompletionWindow(current, nowDate);
      if (current.isCompleted) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.alreadyCompleted,
          'Nhiệm vụ này đã được hoàn thành rồi.',
        );
      }

      final userId = current.userId?.trim();
      if (userId == null || userId.isEmpty) {
        throw StateError('Nabi chưa xác định được hồ sơ đang chăm sóc.');
      }
      if (!input.isEmpty) {
        await _mergeHealthLog(
          txn,
          userId: userId,
          dateKey: current.scheduleDate,
          input: input,
        );
      }

      updated = current.copyWith(
        currentValue: current.targetValue,
        isCompleted: true,
        completedAt: nowText,
        updatedAt: nowText,
      );
      await scheduleDao.update(LifestyleScheduleItemModel.fromEntity(updated));
      await _syncLinkedDailyTask(txn, current, isCompleted: true, now: nowText);
      await _syncDailyScheduleScore(txn, updated, nowDate: nowDate);
      if (queueReward) {
        final attempt = ScheduleHealthRewardAttemptEntity(
          id: _uuidV4(),
          userId: userId,
          scheduleItemId: updated.id,
          actionType: action,
          input: input,
          completionToken: nowText,
          syncStatus: ScheduleHealthRewardAttemptStatuses.pending,
          createdAt: nowText,
          updatedAt: nowText,
        );
        await ScheduleHealthRewardAttemptsDao(txn).insert(
          ScheduleHealthRewardAttemptModel.fromEntity(attempt),
        );
      }
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return updated;
  }

  Future<LifestyleScheduleItemEntity> undoCheckInTask(
    LifestyleScheduleItemEntity item, {
    bool rewardUndoPending = false,
  }) async {
    final action = ScheduleHealthActionPolicy.forItem(item);
    if (action == ScheduleHealthActionType.photoProof) {
      throw const FormatException(
        'Nhiệm vụ có ảnh minh chứng phải dùng luồng hoàn tác hiện tại.',
      );
    }

    final db = await _db();
    final nowDate = _now();
    final nowText = nowDate.toIso8601String();
    late LifestyleScheduleItemEntity updated;
    await db.transaction((txn) async {
      final scheduleDao = LifestyleScheduleItemsDao(txn);
      final currentModel = await scheduleDao.getById(item.id);
      if (currentModel == null) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.notFound,
          'Nabi chưa tìm thấy nhiệm vụ này. Bạn tải lại lịch trình nhé.',
        );
      }
      final current = currentModel.toEntity();
      if (!current.isWithinCompletionWindow(nowDate)) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.locked,
          'Nhiệm vụ đã hết thời gian hoàn tác.',
        );
      }
      if (!current.isCompleted) {
        throw const ScheduleCompletionException(
          ScheduleCompletionErrorCode.notCompleted,
          'Nhiệm vụ này chưa được hoàn thành để hoàn tác.',
        );
      }

      updated = current.copyWith(
        currentValue: 0,
        isCompleted: false,
        updatedAt: nowText,
        clearCompletionProof: true,
      );
      await scheduleDao.update(LifestyleScheduleItemModel.fromEntity(updated));
      await _syncLinkedDailyTask(txn, current, isCompleted: false, now: nowText);
      await _syncDailyScheduleScore(txn, updated, nowDate: nowDate);
      final attemptDao = ScheduleHealthRewardAttemptsDao(txn);
      final latest = await attemptDao.latestForScheduleItem(updated.id);
      if (latest != null &&
          latest.syncStatus != ScheduleHealthRewardAttemptStatuses.reversed) {
        await attemptDao.updateResult(
          id: latest.id,
          syncStatus: rewardUndoPending
              ? ScheduleHealthRewardAttemptStatuses.undoPending
              : ScheduleHealthRewardAttemptStatuses.reversed,
          rewardStatus: rewardUndoPending ? 'undo_pending' : 'reversed',
          pointsDelta: latest.pointsDelta == 0 ? null : -latest.pointsDelta.abs(),
          updatedAt: nowText,
        );
      }
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return updated;
  }

  Future<void> _syncLinkedDailyTask(
    DatabaseExecutor db,
    LifestyleScheduleItemEntity item, {
    required bool isCompleted,
    required String now,
  }) async {
    if (!item.isDailyTaskLinked) return;
    final dao = DailyHealthTasksDao(db);
    final task = await dao.getById(item.sourceId!);
    if (task == null) return;
    await dao.updateTask(
      task.copyWith(
        currentValue: isCompleted ? task.targetValue : 0,
        isCompleted: isCompleted,
        updatedAt: now,
      ),
    );
  }

  Future<HealthTrackingLogModel> _mergeHealthLog(
    DatabaseExecutor db, {
    required String userId,
    required String dateKey,
    required DailyHealthCheckInInput input,
  }) async {
    final dao = HealthTrackingLogsDao(db);
    final existing = await dao.getByUserAndDate(
      userId: userId,
      logDate: dateKey,
    );
    final now = _now().toIso8601String();
    final current = existing ??
        HealthTrackingLogModel(
          id: 'health_log_${userId}_$dateKey',
          userId: userId,
          logDate: dateKey,
          createdAt: now,
          updatedAt: now,
        );
    final nextWater = (current.waterMl + input.waterDeltaMl).clamp(0, 100000).toInt();
    final next = current.copyWith(
      waterMl: nextWater,
      sleepHours: input.sleepHours,
      stressLevel: input.stressLevel,
      mood: input.mood,
      weightKg: input.weightKg,
      updatedAt: now,
    );
    await dao.upsertByUserAndDate(next);
    return next;
  }

  Future<void> _syncDailyScheduleScore(
    DatabaseExecutor db,
    LifestyleScheduleItemEntity item, {
    required DateTime nowDate,
  }) async {
    final userId = item.userId;
    if (userId == null || userId.isEmpty) return;

    final items = await LifestyleScheduleItemsDao(db).getByDate(
      userId: userId,
      scheduleDate: item.scheduleDate,
    );
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
    final current = existing ??
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
        'Ngày hoặc giờ của nhiệm vụ chưa hợp lệ nên Nabi đã tạm khóa thao tác này.',
      );
    }
    final status = item.completionStatusAt(now);
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


  void _validateStandaloneInput(DailyHealthCheckInInput input) {
    if (input.waterDeltaMl != 0 &&
        (input.waterDeltaMl < 50 || input.waterDeltaMl > 2000)) {
      throw const FormatException('Chọn lượng nước từ 50 đến 2000 ml.');
    }
    if (input.sleepHours != null &&
        (input.sleepHours! < 0 || input.sleepHours! > 24)) {
      throw const FormatException(
        'Thời lượng ngủ cần nằm trong khoảng 0–24 giờ.',
      );
    }
    if (input.weightKg != null &&
        (input.weightKg! < 20 || input.weightKg! > 500)) {
      throw const FormatException('Cân nặng cần nằm trong khoảng 20–500 kg.');
    }
    if (input.mood != null || input.stressLevel != null) {
      const moods = {'very_good', 'good', 'neutral', 'tired', 'stressed'};
      if (!moods.contains(input.mood) ||
          input.stressLevel == null ||
          input.stressLevel! < 1 ||
          input.stressLevel! > 5) {
        throw const FormatException(
          'Hãy chọn cảm xúc và mức căng thẳng từ 1 đến 5.',
        );
      }
    }
  }

  void _validateInput(
    ScheduleHealthActionType action,
    DailyHealthCheckInInput input,
  ) {
    switch (action) {
      case ScheduleHealthActionType.photoProof:
        return;
      case ScheduleHealthActionType.quickComplete:
        return;
      case ScheduleHealthActionType.hydration:
        if (input.waterDeltaMl < 50 || input.waterDeltaMl > 2000) {
          throw const FormatException('Chọn lượng nước từ 50 đến 2000 ml.');
        }
        return;
      case ScheduleHealthActionType.moodStress:
        const moods = {'very_good', 'good', 'neutral', 'tired', 'stressed'};
        if (!moods.contains(input.mood) ||
            input.stressLevel == null ||
            input.stressLevel! < 1 ||
            input.stressLevel! > 5) {
          throw const FormatException('Hãy chọn cảm xúc và mức căng thẳng từ 1 đến 5.');
        }
        return;
      case ScheduleHealthActionType.sleepCheckIn:
        if (input.sleepHours == null ||
            input.sleepHours! < 0 ||
            input.sleepHours! > 24) {
          throw const FormatException('Thời lượng ngủ cần nằm trong khoảng 0–24 giờ.');
        }
        return;
      case ScheduleHealthActionType.weightCheckIn:
        if (input.weightKg == null ||
            input.weightKg! < 20 ||
            input.weightKg! > 500) {
          throw const FormatException('Cân nặng cần nằm trong khoảng 20–500 kg.');
        }
        return;
    }
  }

  DailyHealthSnapshotEntity _snapshot({
    required String userId,
    required String dateKey,
    required HealthTrackingLogModel? log,
  }) {
    return DailyHealthSnapshotEntity(
      userId: userId,
      logDate: dateKey,
      waterMl: log?.waterMl ?? 0,
      sleepHours: log?.sleepHours,
      stressLevel: log?.stressLevel,
      mood: log?.mood,
      weightKg: log?.weightKg,
      dailyScore: log?.dailyScore,
      updatedAt: log?.updatedAt,
    );
  }

  Future<Map<String, Object?>> _fetchLatestUser(Database db) async {
    final users = await db.query('users', orderBy: 'created_at DESC', limit: 1);
    if (users.isEmpty) {
      throw StateError('Nabi chưa tìm thấy hồ sơ phù hợp để mở lịch chăm sóc.');
    }
    return users.first;
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
