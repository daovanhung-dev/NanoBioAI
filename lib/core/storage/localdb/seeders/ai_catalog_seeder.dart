import 'package:sqflite/sqflite.dart';

import '../daos/ai_catalog_dao.dart';
import 'ai_catalog_seed_data.dart';
import 'source_meal_catalog_loader.dart';

class AiCatalogSeeder {
  const AiCatalogSeeder._();

  static Future<void> seed(Database db) async {
    final dao = AiCatalogDao(db);
    await dao.upsertMeals(AiCatalogSeedData.meals);
    try {
      final sourceRecipes = await SourceMealCatalogLoader.load();
      await dao.upsertMeals(sourceRecipes);
    } catch (_) {
      // Keep the approved built-in catalog available when an asset cannot be
      // loaded in a test harness or a damaged installation. No source content
      // or user data is logged here.
    }
    await dao.upsertExercises(AiCatalogSeedData.exercises);
    await dao.upsertScheduleTasks(AiCatalogSeedData.scheduleTasks);
  }
}
