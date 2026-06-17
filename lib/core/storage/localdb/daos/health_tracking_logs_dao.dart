import 'package:sqflite/sqflite.dart';

import 'package:nano_app/core/utils/logger/app_logger.dart';

import '../models/health_tracking_log_model.dart';

class HealthTrackingLogsDao {
  static const tableName = 'health_tracking_logs';
  static const _tag = 'HEALTH_TRACKING_LOGS_DAO';

  final Database db;

  HealthTrackingLogsDao(this.db);

  Future<void> insert(HealthTrackingLogModel model) async {
    AppLogger.database(_tag, 'Insert health log ${model.id}');
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<HealthTrackingLogModel> models) async {
    if (models.isEmpty) return;

    final batch = db.batch();
    for (final model in models) {
      batch.insert(
        tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertByUserAndDate(HealthTrackingLogModel model) async {
    AppLogger.database(
      _tag,
      'Upsert health log user=${model.userId} date=${model.logDate}',
    );
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HealthTrackingLogModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(HealthTrackingLogModel.fromMap).toList();
  }

  Future<HealthTrackingLogModel?> getById(String id) async {
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthTrackingLogModel.fromMap(maps.first);
  }

  Future<List<HealthTrackingLogModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(HealthTrackingLogModel.fromMap).toList();
  }

  Future<HealthTrackingLogModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthTrackingLogModel.fromMap(maps.first);
  }

  Future<HealthTrackingLogModel?> getByUserAndDate({
    required String userId,
    required String logDate,
  }) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND log_date = ?',
      whereArgs: [userId, logDate],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthTrackingLogModel.fromMap(maps.first);
  }

  Future<List<HealthTrackingLogModel>> getByUserAndDateRange({
    required String userId,
    required String fromDate,
    required String toDate,
  }) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND log_date BETWEEN ? AND ?',
      whereArgs: [userId, fromDate, toDate],
      orderBy: defaultOrderBy,
    );
    return maps.map(HealthTrackingLogModel.fromMap).toList();
  }

  Future<void> update(HealthTrackingLogModel model) async {
    AppLogger.database(_tag, 'Update health log ${model.id}');
    await db.update(
      tableName,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(String id) async {
    AppLogger.database(_tag, 'Delete health log $id');
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByUserId(String userId) async {
    await db.delete(tableName, where: 'user_id = ?', whereArgs: [userId]);
  }

  String get defaultOrderBy => 'log_date DESC, created_at DESC';
}
