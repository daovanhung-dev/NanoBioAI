import 'package:nano_app/core/storage/localdb/models/ai_recommendation_model.dart';
import 'package:sqflite/sqflite.dart';


class AiRecommendationsDao {
  final Database db;

  AiRecommendationsDao(this.db);

  Future<void> insert(
    AIRecommendationModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<AIRecommendationModel>> getAll() async {
    return [];
  }

  Future<void> update(
    AIRecommendationModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}