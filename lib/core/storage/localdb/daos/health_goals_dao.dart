import 'package:sqflite/sqflite.dart';

import '../models/health_goal_model.dart';

class HealthGoalsDao {
  final Database db;

  HealthGoalsDao(this.db);

  Future<void> insert(
    HealthGoalModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<HealthGoalModel>> getAll() async {
    return [];
  }

  Future<void> update(
    HealthGoalModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}