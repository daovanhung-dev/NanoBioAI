import 'package:nano_app/core/storage/localdb/models/ai_insight_model.dart';
import 'package:sqflite/sqflite.dart';

class AiInsightsDao {
  final Database db;

  AiInsightsDao(this.db);

  Future<void> insert(
    AIInsightModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<AIInsightModel>> getAll() async {
    return [];
  }

  Future<void> update(
    AIInsightModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}