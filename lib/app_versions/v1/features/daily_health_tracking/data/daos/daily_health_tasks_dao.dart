import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_health_task_model.dart';

class DailyHealthTasksDao {
  static const _tag = 'DAILY_TRACKING_DAO';

  final DatabaseExecutor db;

  const DailyHealthTasksDao(this.db);

  Future<void> upsertMany(List<DailyHealthTaskModel> tasks) async {
    AppLogger.database(_tag, 'Upsert ${tasks.length} daily health task(s)');
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        DailyHealthTasksTable.tableName,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<DailyHealthTaskModel>> getByUserAndDate({
    required String userId,
    required String taskDate,
  }) async {
    AppLogger.database(_tag, 'Query tasks user=$userId date=$taskDate');
    final maps = await db.query(
      DailyHealthTasksTable.tableName,
      where: 'user_id = ? AND task_date = ?',
      whereArgs: [userId, taskDate],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return maps.map(DailyHealthTaskModel.fromMap).toList();
  }

  Future<List<DailyHealthTaskModel>> getAll() async {
    AppLogger.database(_tag, 'Query all daily health tasks');
    final maps = await db.query(
      DailyHealthTasksTable.tableName,
      orderBy: 'task_date ASC, sort_order ASC, created_at ASC',
    );
    return maps.map(DailyHealthTaskModel.fromMap).toList();
  }

  Future<DailyHealthTaskModel?> getById(String id) async {
    AppLogger.database(_tag, 'Query task id=$id');
    final maps = await db.query(
      DailyHealthTasksTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DailyHealthTaskModel.fromMap(maps.first);
  }

  Future<void> updateTask(DailyHealthTaskModel task) async {
    AppLogger.database(_tag, 'Update task ${task.taskCode}');
    await db.update(
      DailyHealthTasksTable.tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteByUserAndDate({
    required String userId,
    required String taskDate,
  }) async {
    AppLogger.database(_tag, 'Delete tasks user=$userId date=$taskDate');
    await db.delete(
      DailyHealthTasksTable.tableName,
      where: 'user_id = ? AND task_date = ?',
      whereArgs: [userId, taskDate],
    );
  }
}
