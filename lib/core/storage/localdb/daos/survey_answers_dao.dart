import 'package:sqflite/sqflite.dart';

import '../models/survey_answer_model.dart';

class SurveyAnswersDao {
  final Database db;

  SurveyAnswersDao(this.db);

  Future<void> insert(
    SurveyAnswerModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<SurveyAnswerModel>> getAll() async {
    return [];
  }

  Future<void> update(
    SurveyAnswerModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}