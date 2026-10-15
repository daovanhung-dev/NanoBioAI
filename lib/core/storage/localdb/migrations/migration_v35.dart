import 'package:nano_app/core/storage/localdb/seeders/source_meal_catalog_loader.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV35 {
  const MigrationV35._();

  static const expectedMealCount = 163;

  static Future<void> run(DatabaseExecutor db) async {
    final descriptions = await SourceMealCatalogLoader.loadDescriptions();
    if (descriptions.length != expectedMealCount) {
      throw StateError(
        'Expected $expectedMealCount bundled meal descriptions, '
        'got ${descriptions.length}.',
      );
    }

    final storedRows = await db.query(
      MealCatalogTable.tableName,
      columns: const ['code'],
    );
    if (storedRows.length != expectedMealCount) {
      throw StateError(
        'Expected $expectedMealCount stored meals for migration v35, '
        'got ${storedRows.length}.',
      );
    }
    final storedCodes = storedRows
        .map((row) => row['code']?.toString() ?? '')
        .toSet();
    if (storedCodes.length != expectedMealCount ||
        !storedCodes.containsAll(descriptions.keys)) {
      throw StateError(
        'Stored meal codes do not match the bundled v35 descriptions.',
      );
    }

    var updatedCount = 0;
    for (final entry in descriptions.entries) {
      updatedCount += await db.update(
        MealCatalogTable.tableName,
        {'description': entry.value},
        where: 'code = ?',
        whereArgs: [entry.key],
      );
    }
    if (updatedCount != expectedMealCount) {
      throw StateError(
        'Expected to update $expectedMealCount meal descriptions, '
        'updated $updatedCount.',
      );
    }
  }
}
