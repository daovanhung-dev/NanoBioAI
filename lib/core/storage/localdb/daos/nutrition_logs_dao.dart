import 'package:sqflite/sqflite.dart';

import '../models/nutrition_log_model.dart';

class NutritionLogsDao {
  final Database db;

  NutritionLogsDao(this.db);

  Future<void> insert(
    NutritionLogModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<NutritionLogModel>> getAll() async {
    return [];
  }

  Future<void> update(
    NutritionLogModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}