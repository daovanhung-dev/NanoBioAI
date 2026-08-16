import 'package:sqflite/sqflite.dart';

import '../seeders/ai_catalog_seeder.dart';
import '../tables/meal_catalog_table.dart';
import '../tables/meal_plans_table.dart';

class MigrationV18 {
  const MigrationV18._();

  static const _nutritionColumns = <String, String>{
    'sugar_g': 'REAL',
    'saturated_fat_g': 'REAL',
    'sodium_mg': 'REAL',
    'cholesterol_mg': 'REAL',
    'potassium_mg': 'REAL',
    'calcium_mg': 'REAL',
    'iron_mg': 'REAL',
    'nutrition_status': 'TEXT',
  };

  static Future<void> run(Database db) async {
    await ensureSchema(db);
    // Re-seed source recipes after the columns exist. The source loader enriches
    // recipes that still carry nutrition_status=missing_source_data.
    await AiCatalogSeeder.seed(db);
  }

  static Future<void> ensureSchema(Database db) async {
    await _ensureColumns(db, MealCatalogTable.tableName);
    await _ensureColumns(db, MealPlansTable.tableName);
  }

  static Future<void> _ensureColumns(Database db, String tableName) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final existing = columns.map((row) => row['name']?.toString()).toSet();
    for (final entry in _nutritionColumns.entries) {
      if (existing.contains(entry.key)) continue;
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
  }
}
