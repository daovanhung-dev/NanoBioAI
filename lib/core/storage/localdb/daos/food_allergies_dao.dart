import 'package:sqflite/sqflite.dart';

import '../models/food_allergy_model.dart';

class FoodAllergiesDao {
  final Database db;

  FoodAllergiesDao(this.db);

  Future<void> insert(
    FoodAllergyModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<FoodAllergyModel>> getAll() async {
    return [];
  }

  Future<void> update(
    FoodAllergyModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}