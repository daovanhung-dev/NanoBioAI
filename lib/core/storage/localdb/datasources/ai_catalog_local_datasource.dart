import 'package:sqflite/sqflite.dart';

import '../daos/ai_catalog_dao.dart';
import '../daos/food_evidence_dao.dart';
import '../database_service.dart';
import '../models/ai_catalog_models.dart';

class AiCatalogLocalDatasource {
  final Database? databaseOverride;

  const AiCatalogLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<AiCatalogBundle> loadActiveBundle() async {
    final db = await _db();
    final bundle = await AiCatalogDao(db).loadActiveBundle();
    final ingredientNames = bundle.meals
        .expand((meal) => meal.ingredientQuantities)
        .map((ingredient) => ingredient.name)
        .toSet();
    final evidence = await FoodEvidenceDao(db).getByNames(ingredientNames);
    return AiCatalogBundle(
      meals: bundle.meals,
      exercises: bundle.exercises,
      scheduleTasks: bundle.scheduleTasks,
      ingredientEvidenceByName: evidence,
    );
  }

  /// Returns the complete local meal and exercise catalogs for schedule AI.
  /// The AI schedule prompt uses only catalog codes and names.
  Future<AiCatalogBundle> loadScheduleCatalogBundle() async {
    final db = await _db();
    return AiCatalogDao(db).loadScheduleCatalogBundle();
  }

  Future<void> cacheFoodEvidence(
    Iterable<FoodIngredientEvidence> evidence,
  ) async {
    final db = await _db();
    await db.transaction((txn) => FoodEvidenceDao(txn).upsertMany(evidence));
  }
}
