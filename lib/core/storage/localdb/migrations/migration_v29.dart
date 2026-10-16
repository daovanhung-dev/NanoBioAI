import 'package:sqflite/sqflite.dart';

import '../seeders/meal_catalog_seeder.dart';

class MigrationV29 {
  const MigrationV29._();

  static Future<void> run(DatabaseExecutor db) async {
    await MealCatalogSeeder.seedLegacy(db);
  }
}
