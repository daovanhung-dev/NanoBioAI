import 'package:sqflite/sqflite.dart';

import '../models/health_tracking_log_model.dart';

class HealthTrackingLogsDao {
  final Database db;

  HealthTrackingLogsDao(this.db);

  Future<void> insert(
    HealthTrackingLogModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<HealthTrackingLogModel>> getAll() async {
    return [];
  }

  Future<void> update(
    HealthTrackingLogModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}