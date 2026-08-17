import 'package:nano_app/core/storage/localdb/tables/schedule_health_checkin_outbox_table.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/schedule_health_reward_attempt_entity.dart';
import '../models/schedule_health_reward_attempt_model.dart';

class ScheduleHealthRewardAttemptsDao {
  final DatabaseExecutor db;

  const ScheduleHealthRewardAttemptsDao(this.db);

  Future<void> insert(ScheduleHealthRewardAttemptModel model) async {
    await db.insert(
      ScheduleHealthCheckInOutboxTable.tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ScheduleHealthRewardAttemptModel?> latestForScheduleItem(
    String scheduleItemId,
  ) async {
    final rows = await db.query(
      ScheduleHealthCheckInOutboxTable.tableName,
      where: 'schedule_item_id = ?',
      whereArgs: [scheduleItemId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScheduleHealthRewardAttemptModel.fromMap(rows.first);
  }

  Future<List<ScheduleHealthRewardAttemptModel>> getPending({
    int limit = 20,
  }) async {
    final rows = await db.query(
      ScheduleHealthCheckInOutboxTable.tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [
        ScheduleHealthRewardAttemptStatuses.pending,
        ScheduleHealthRewardAttemptStatuses.undoPending,
      ],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows
        .map(ScheduleHealthRewardAttemptModel.fromMap)
        .toList(growable: false);
  }

  Future<void> updateResult({
    required String id,
    required String syncStatus,
    String? rewardStatus,
    int? pointsDelta,
    String? lastErrorCode,
    required String updatedAt,
  }) async {
    await db.update(
      ScheduleHealthCheckInOutboxTable.tableName,
      {
        'sync_status': syncStatus,
        'reward_status': rewardStatus,
        if (pointsDelta != null) 'points_delta': pointsDelta,
        'last_error_code': lastErrorCode,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
