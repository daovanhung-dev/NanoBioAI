import 'package:sqflite/sqflite.dart';

import '../models/nutrition_log_model.dart';

class NutritionLogsDao {
  static const tableName = 'nutrition_logs';

  final Database db;
  NutritionLogsDao(this.db);

  Future<void> insert(NutritionLogModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<NutritionLogModel> models) async {
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

  Future<List<NutritionLogModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(NutritionLogModel.fromMap).toList();
  }

  Future<NutritionLogModel?> getById(String id) async {
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return NutritionLogModel.fromMap(maps.first);
  }

  Future<List<NutritionLogModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(NutritionLogModel.fromMap).toList();
  }

  Future<NutritionLogModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return NutritionLogModel.fromMap(maps.first);
  }

  Future<List<NutritionLogModel>> getByUserAndDate({
    required String userId,
    required String date,
  }) async {
    final maps = await db.query(
      tableName,
      where: "user_id = ? AND (eaten_at = ? OR substr(eaten_at, 1, 10) = ?)",
      whereArgs: [userId, date, date],
      orderBy: defaultOrderBy,
    );
    return maps.map(NutritionLogModel.fromMap).toList();
  }

  Future<List<NutritionLogModel>> getByUserAndDateRange({
    required String userId,
    required String fromDate,
    required String toDate,
  }) async {
    final maps = await db.query(
      tableName,
      where: "user_id = ? AND substr(eaten_at, 1, 10) BETWEEN ? AND ?",
      whereArgs: [userId, fromDate, toDate],
      orderBy: defaultOrderBy,
    );
    return maps.map(NutritionLogModel.fromMap).toList();
  }

  Future<void> update(NutritionLogModel model) async {
    await db.update(
      tableName,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByUserId(String userId) async {
    await db.delete(tableName, where: 'user_id = ?', whereArgs: [userId]);
  }

  String get defaultOrderBy => 'eaten_at DESC';
}