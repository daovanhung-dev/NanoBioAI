import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:sqflite/sqflite.dart';

import '../models/lifestyle_schedule_item_model.dart';

class LifestyleScheduleItemsDao {
  final DatabaseExecutor db;

  const LifestyleScheduleItemsDao(this.db);

  Future<void> upsertMany(List<LifestyleScheduleItemModel> items) async {
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        LifestyleScheduleItemsTable.tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<LifestyleScheduleItemModel?> getById(String id) async {
    final maps = await db.query(
      LifestyleScheduleItemsTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LifestyleScheduleItemModel.fromMap(maps.first);
  }

  Future<List<LifestyleScheduleItemModel>> getByDate({
    required String userId,
    required String scheduleDate,
  }) async {
    final maps = await db.query(
      LifestyleScheduleItemsTable.tableName,
      where: 'user_id = ? AND schedule_date = ?',
      whereArgs: [userId, scheduleDate],
      orderBy: 'sort_order ASC, start_time ASC',
    );
    return maps.map(LifestyleScheduleItemModel.fromMap).toList();
  }

  Future<List<LifestyleScheduleItemModel>> getByDateRange({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    final maps = await db.query(
      LifestyleScheduleItemsTable.tableName,
      where: 'user_id = ? AND schedule_date >= ? AND schedule_date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'schedule_date ASC, sort_order ASC, start_time ASC',
    );
    return maps.map(LifestyleScheduleItemModel.fromMap).toList();
  }

  Future<List<LifestyleScheduleItemModel>> getAll() async {
    final maps = await db.query(
      LifestyleScheduleItemsTable.tableName,
      orderBy: 'schedule_date ASC, sort_order ASC, start_time ASC',
    );
    return maps.map(LifestyleScheduleItemModel.fromMap).toList();
  }

  Future<List<LifestyleScheduleItemModel>> getAllByUserId(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const [];

    final maps = await db.query(
      LifestyleScheduleItemsTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      orderBy: 'schedule_date ASC, sort_order ASC, start_time ASC',
    );
    return maps.map(LifestyleScheduleItemModel.fromMap).toList();
  }

  Future<void> update(LifestyleScheduleItemModel item) async {
    await db.update(
      LifestyleScheduleItemsTable.tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateCompletion({
    required String id,
    required bool isCompleted,
    required double currentValue,
    String? completionProofPath,
    String? completionProofCapturedAt,
    String? completedAt,
    required String updatedAt,
  }) async {
    await db.update(
      LifestyleScheduleItemsTable.tableName,
      {
        'is_completed': isCompleted ? 1 : 0,
        'current_value': currentValue,
        'completion_proof_path': completionProofPath,
        'completion_proof_captured_at': completionProofCapturedAt,
        'completed_at': completedAt,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByUserId(String userId) async {
    await db.delete(
      LifestyleScheduleItemsTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteByUserIdAndDateRange({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    await db.delete(
      LifestyleScheduleItemsTable.tableName,
      where: 'user_id = ? AND schedule_date >= ? AND schedule_date <= ?',
      whereArgs: [userId, startDate, endDate],
    );
  }
}
