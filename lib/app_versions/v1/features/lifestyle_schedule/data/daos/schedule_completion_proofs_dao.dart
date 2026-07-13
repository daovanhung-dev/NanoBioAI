import 'package:nano_app/core/storage/localdb/tables/schedule_completion_proofs_table.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../models/schedule_completion_proof_model.dart';

class ScheduleCompletionProofsDao {
  final DatabaseExecutor db;

  const ScheduleCompletionProofsDao(this.db);

  Future<void> insert(ScheduleCompletionProofModel proof) async {
    await db.insert(
      ScheduleCompletionProofsTable.tableName,
      proof.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<ScheduleCompletionProofModel>> getByUser(String userId) async {
    final rows = await db.query(
      ScheduleCompletionProofsTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'captured_at DESC, created_at DESC',
    );
    return rows.map(ScheduleCompletionProofModel.fromMap).toList();
  }

  Future<ScheduleCompletionProofModel?> getById(String id) async {
    final rows = await db.query(
      ScheduleCompletionProofsTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScheduleCompletionProofModel.fromMap(rows.first);
  }

  Future<ScheduleCompletionProofModel?> getByAttemptId(String attemptId) async {
    final rows = await db.query(
      ScheduleCompletionProofsTable.tableName,
      where: 'completion_attempt_id = ?',
      whereArgs: [attemptId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScheduleCompletionProofModel.fromMap(rows.first);
  }

  Future<ScheduleCompletionProofModel?> getLatestActiveForSchedule(
    String scheduleItemId,
  ) async {
    final rows = await db.query(
      ScheduleCompletionProofsTable.tableName,
      where: 'schedule_item_id = ? AND status = ?',
      whereArgs: [scheduleItemId, ScheduleCompletionProofStatuses.active],
      orderBy: 'captured_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScheduleCompletionProofModel.fromMap(rows.first);
  }

  Future<void> markReversed({
    required String id,
    required String reversedAt,
  }) async {
    await db.update(
      ScheduleCompletionProofsTable.tableName,
      {
        'status': ScheduleCompletionProofStatuses.reversed,
        'reward_status': ScheduleProofRewardStatuses.reversed,
        'reversed_at': reversedAt,
        'updated_at': reversedAt,
      },
      where: 'id = ? AND status = ?',
      whereArgs: [id, ScheduleCompletionProofStatuses.active],
    );
  }

  Future<void> updateRemoteState({
    required String id,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? cloudObjectPath,
    String? uploadStatus,
    String? rewardStatus,
    required String updatedAt,
  }) async {
    final values = <String, Object?>{'updated_at': updatedAt};
    if (rewardEligibilityId != null) {
      values['reward_eligibility_id'] = rewardEligibilityId;
    }
    if (completionAttemptId != null) {
      values['completion_attempt_id'] = completionAttemptId;
    }
    if (cloudObjectPath != null) {
      values['cloud_object_path'] = cloudObjectPath;
    }
    if (uploadStatus != null) values['upload_status'] = uploadStatus;
    if (rewardStatus != null) values['reward_status'] = rewardStatus;
    await db.update(
      ScheduleCompletionProofsTable.tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
