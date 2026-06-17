import 'package:sqflite/sqflite.dart';

import '../models/health_goal_model.dart';

class HealthGoalsDao {
  static const tableName = 'health_goals';

  final Database db;
  HealthGoalsDao(this.db);

  Future<void> insert(HealthGoalModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<HealthGoalModel> models) async {
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

  Future<List<HealthGoalModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(HealthGoalModel.fromMap).toList();
  }

  Future<HealthGoalModel?> getById(String id) async {
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return HealthGoalModel.fromMap(maps.first);
  }

  Future<List<HealthGoalModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(HealthGoalModel.fromMap).toList();
  }

  Future<HealthGoalModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthGoalModel.fromMap(maps.first);
  }

  Future<List<HealthGoalModel>> getActiveByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND is_active = ?',
      whereArgs: [userId, 1],
      orderBy: defaultOrderBy,
    );
    return maps.map(HealthGoalModel.fromMap).toList();
  }

  Future<void> update(HealthGoalModel model) async {
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

  String get defaultOrderBy => 'created_at DESC';
}