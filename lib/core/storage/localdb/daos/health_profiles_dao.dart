import 'package:sqflite/sqflite.dart';

import '../models/health_profile_model.dart';

class HealthProfilesDao {
  final Database db;

  HealthProfilesDao(this.db);

  Future<void> insert(
    HealthProfileModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<HealthProfileModel>> getAll() async {
    return [];
  }

  Future<void> update(
    HealthProfileModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}