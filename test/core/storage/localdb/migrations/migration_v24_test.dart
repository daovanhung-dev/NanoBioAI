import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v24.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('migration v24 removes bundled meal rows', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(MealCatalogTable.createTable);
    await db.insert(MealCatalogTable.tableName, {
      'code': 'br_legacy_app_meal',
      'meal_type': 'breakfast',
      'meal_name': 'Món cũ trong app',
      'description': 'Dữ liệu cũ',
      'cooking_instructions': 'Dữ liệu cũ',
    });

    await MigrationV24.run(db);

    expect(await db.query(MealCatalogTable.tableName), isEmpty);
  });
}
