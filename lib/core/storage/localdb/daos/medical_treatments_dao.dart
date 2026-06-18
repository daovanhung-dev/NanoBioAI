import 'package:sqflite/sqflite.dart';

import '../models/medical_treatment_model.dart';

class MedicalTreatmentsDao {
  static const tableName = 'medical_treatments';

  final Database db;
  MedicalTreatmentsDao(this.db);

  Future<void> insert(MedicalTreatmentModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<MedicalTreatmentModel> models) async {
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

  Future<List<MedicalTreatmentModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(MedicalTreatmentModel.fromMap).toList();
  }

  Future<MedicalTreatmentModel?> getById(String id) async {
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MedicalTreatmentModel.fromMap(maps.first);
  }

  Future<List<MedicalTreatmentModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(MedicalTreatmentModel.fromMap).toList();
  }

  Future<MedicalTreatmentModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MedicalTreatmentModel.fromMap(maps.first);
  }

  Future<void> update(MedicalTreatmentModel model) async {
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
