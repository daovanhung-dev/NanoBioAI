import 'package:sqflite/sqflite.dart';

import '../models/health_condition_model.dart';

class HealthConditionsDao {
  final Database db;

  HealthConditionsDao(this.db);

  Future<void> insert(
    HealthConditionModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<HealthConditionModel>> getAll() async {
    return [];
  }

  Future<void> update(
    HealthConditionModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}