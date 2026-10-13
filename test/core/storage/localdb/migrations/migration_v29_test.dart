import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v29.dart';
import 'package:nano_app/core/storage/localdb/seeders/source_meal_catalog_loader.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test('v29 restores all bundled meals and preserves source hashes', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(MealCatalogTable.createTable);
    await db.insert(MealCatalogTable.tableName, {
      'code': 'legacy_remote_meal',
      'meal_type': 'breakfast',
      'meal_name': 'Món cũ',
      'description': 'Mô tả cũ',
      'cooking_instructions': 'Hướng dẫn cũ',
    });

    final sourceMeals = await SourceMealCatalogLoader.load();
    await db.transaction(MigrationV29.run);
    await db.transaction(MigrationV29.run);

    final storedRows = await db.query(
      MealCatalogTable.tableName,
      columns: const ['code', 'source_hash', 'meal_type', 'is_active'],
      orderBy: 'code ASC',
    );
    expect(storedRows, hasLength(163));
    expect(
      storedRows.map((row) => row['code']),
      isNot(contains('legacy_remote_meal')),
    );
    expect(
      {for (final row in storedRows) row['code']: row['source_hash']},
      {for (final meal in sourceMeals) meal.code: meal.sourceHash},
    );
    expect(storedRows.every((row) => row['is_active'] == 1), isTrue);

    final metadataRows = await db.query(
      MealCatalogTable.tableName,
      columns: const [
        'meal_type',
        'is_plan_eligible',
        'metadata_status',
        'nutrition_status',
      ],
    );
    expect(metadataRows, hasLength(163));
    expect(
      metadataRows.every((row) => row['meal_type'] == 'unclassified'),
      isTrue,
    );
    expect(metadataRows.every((row) => row['is_plan_eligible'] == 0), isTrue);
    expect(
      metadataRows.every((row) => row['metadata_status'] == 'source_imported'),
      isTrue,
    );
    expect(DatabaseVersion.currentVersion, 31);
  });
}
