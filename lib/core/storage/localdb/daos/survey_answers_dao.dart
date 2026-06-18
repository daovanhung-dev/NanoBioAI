import 'package:sqflite/sqflite.dart';

import '../models/survey_answer_model.dart';

class SurveyAnswersDao {
  static const tableName = 'survey_answers';

  final Database db;
  SurveyAnswersDao(this.db);

  Future<void> insert(SurveyAnswerModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<SurveyAnswerModel> models) async {
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

  Future<List<SurveyAnswerModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(SurveyAnswerModel.fromMap).toList();
  }

  Future<SurveyAnswerModel?> getById(String id) async {
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SurveyAnswerModel.fromMap(maps.first);
  }

  Future<List<SurveyAnswerModel>> getByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
    return maps.map(SurveyAnswerModel.fromMap).toList();
  }

  Future<SurveyAnswerModel?> getLatestByUserId(String userId) async {
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SurveyAnswerModel.fromMap(maps.first);
  }

  Future<Map<String, String>> getAnswerMapByUserId(String userId) async {
    final rows = await db.query(
      tableName,
      columns: ['question_code', 'answer_value'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return {
      for (final row in rows)
        if (row['question_code'] != null)
          row['question_code'].toString():
              row['answer_value']?.toString() ?? '',
    };
  }

  Future<void> update(SurveyAnswerModel model) async {
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
