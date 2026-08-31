import 'package:sqflite/sqflite.dart';

import '../tables/meal_catalog_table.dart';

/// Removes meal rows that were bundled by older app versions.
///
/// Meal catalog rows are now a mirror of Supabase only. Existing generated
/// meal plans retain their own catalog snapshots and are not affected.
class MigrationV24 {
  const MigrationV24._();

  static Future<void> run(Database db) async {
    await db.delete(MealCatalogTable.tableName);
  }
}
