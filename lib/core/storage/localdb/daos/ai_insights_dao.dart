import 'package:sqflite/sqflite.dart';

import '../models/ai_insight_model.dart';

class AiInsightsDao {
  static const tableName = 'ai_insights';

  final Database db;
  AiInsightsDao(this.db);

  Future<void> insert(AIInsightModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<AIInsightModel> models) async {
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

  Future<List<AIInsightModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(AIInsightModel.fromMap).toList();
  }

  Future<AIInsightModel?> getById(String id) async {
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return AIInsightModel.fromMap(maps.first);
  }

  Future<List<AIInsightModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(AIInsightModel.fromMap).toList();
  }

  Future<AIInsightModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AIInsightModel.fromMap(maps.first);
  }

  Future<void> update(AIInsightModel model) async {
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