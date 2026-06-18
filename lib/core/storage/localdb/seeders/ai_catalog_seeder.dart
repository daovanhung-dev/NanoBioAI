import 'package:sqflite/sqflite.dart';

import '../daos/ai_catalog_dao.dart';
import 'ai_catalog_seed_data.dart';

class AiCatalogSeeder {
  const AiCatalogSeeder._();

  static Future<void> seed(Database db) async {
    final dao = AiCatalogDao(db);
    await dao.upsertMeals(AiCatalogSeedData.meals);
    await dao.upsertExercises(AiCatalogSeedData.exercises);
    await dao.upsertScheduleTasks(AiCatalogSeedData.scheduleTasks);
  }
}
