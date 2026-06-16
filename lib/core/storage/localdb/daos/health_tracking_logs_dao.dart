import 'package:sqflite/sqflite.dart';

import 'package:nano_app/core/utils/logger/app_logger.dart';

import '../models/health_tracking_log_model.dart';

class HealthTrackingLogsDao {
  static const _tag = 'DAILY_TRACKING_DAO';

  final Database db;

  HealthTrackingLogsDao(this.db);

  Future<void> insert(HealthTrackingLogModel model) async {
    AppLogger.database(_tag, 'Insert health log ${model.id}');
    await db.insert(
      'health_tracking_logs',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertByUserAndDate(HealthTrackingLogModel model) async {
    AppLogger.database(
      _tag,
      'Upsert health log user=${model.userId} date=${model.logDate}',
    );
    await db.insert(
      'health_tracking_logs',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HealthTrackingLogModel>> getAll() async {
    final maps = await db.query(
      'health_tracking_logs',
      orderBy: 'log_date DESC, created_at DESC',
    );
    return maps.map(HealthTrackingLogModel.fromMap).toList();
  }

  Future<HealthTrackingLogModel?> getByUserAndDate({
    required String userId,
    required String logDate,
  }) async {
    final maps = await db.query(
      'health_tracking_logs',
      where: 'user_id = ? AND log_date = ?',
      whereArgs: [userId, logDate],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthTrackingLogModel.fromMap(maps.first);
  }

  Future<void> update(HealthTrackingLogModel model) async {
    AppLogger.database(_tag, 'Update health log ${model.id}');
    await db.update(
      'health_tracking_logs',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(String id) async {
    AppLogger.database(_tag, 'Delete health log $id');
    await db.delete('health_tracking_logs', where: 'id = ?', whereArgs: [id]);
  }
}
