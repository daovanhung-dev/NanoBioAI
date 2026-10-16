import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../seeders/source_meal_catalog_loader.dart';
import '../seeders/unreviewed_wellness_meal_catalog_loader.dart';
import '../tables/meal_catalog_table.dart';

class MigrationV36 {
  const MigrationV36._();

  static const expectedLegacyMealCount = 163;
  static const expectedCandidateMealCount = 3000;

  static Future<int> run(DatabaseExecutor db, {AssetBundle? bundle}) async {
    final legacyMeals = await SourceMealCatalogLoader.load(bundle: bundle);
    final candidateMeals = await UnreviewedWellnessMealCatalogLoader.load(
      bundle: bundle,
    );
    if (legacyMeals.length != expectedLegacyMealCount ||
        candidateMeals.length != expectedCandidateMealCount) {
      throw StateError('Migration v36 bundled catalog counts are invalid.');
    }

    final existingRows = await db.query(
      MealCatalogTable.tableName,
      columns: const ['code', 'source_hash'],
    );
    final existingByCode = {
      for (final row in existingRows)
        row['code']?.toString() ?? '': row['source_hash']?.toString() ?? '',
    };
    final legacyCodes = legacyMeals.map((meal) => meal.code).toSet();
    if (legacyCodes.length != expectedLegacyMealCount ||
        !existingByCode.keys.toSet().containsAll(legacyCodes)) {
      throw StateError('Migration v36 cannot verify all 163 legacy meals.');
    }

    final batch = db.batch();
    var insertedCount = 0;
    for (final meal in candidateMeals) {
      final existingHash = existingByCode[meal.code];
      if (existingHash != null) {
        if (existingHash != meal.sourceHash) {
          throw StateError(
            'Migration v36 candidate hash conflicts for ${meal.code}.',
          );
        }
        continue;
      }
      batch.insert(MealCatalogTable.tableName, meal.toMap());
      insertedCount++;
    }
    if (insertedCount > 0) await batch.commit(noResult: true);

    final storedRows = await db.query(
      MealCatalogTable.tableName,
      columns: const ['code', 'source_hash'],
    );
    final storedHashes = {
      for (final row in storedRows)
        row['code']?.toString() ?? '': row['source_hash']?.toString() ?? '',
    };
    for (final meal in candidateMeals) {
      if (storedHashes[meal.code] != meal.sourceHash) {
        throw StateError(
          'Migration v36 failed to verify candidate ${meal.code}.',
        );
      }
    }
    for (final entry in existingByCode.entries) {
      if (storedHashes[entry.key] != entry.value) {
        throw StateError(
          'Migration v36 changed existing catalog row ${entry.key}.',
        );
      }
    }
    return insertedCount;
  }
}
