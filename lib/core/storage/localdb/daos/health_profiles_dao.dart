import 'package:sqflite/sqflite.dart';

import '../models/health_profile_model.dart';

class HealthProfilesDao {
  static const tableName = 'health_profiles';

  final Database db;
  HealthProfilesDao(this.db);

  Future<void> insert(HealthProfileModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<HealthProfileModel> models) async {
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

  Future<List<HealthProfileModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(HealthProfileModel.fromMap).toList();
  }

  Future<HealthProfileModel?> getById(String id) async {
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return HealthProfileModel.fromMap(maps.first);
  }

  Future<List<HealthProfileModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(HealthProfileModel.fromMap).toList();
  }

  Future<HealthProfileModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthProfileModel.fromMap(maps.first);
  }

  Future<void> update(HealthProfileModel model) async {
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

  String get defaultOrderBy => 'updated_at DESC, created_at DESC';
}