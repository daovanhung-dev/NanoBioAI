import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ai_catalog_models.dart';
import '../tables/meal_catalog_table.dart';
import 'source_meal_catalog_loader.dart';

class MealCatalogSeeder {
  const MealCatalogSeeder._();

  static const expectedMealCount = 163;

  /// Replaces the shared meal catalog from the bundled source asset.
  ///
  /// Call from SQLite create/upgrade transactions so a failed seed leaves the
  /// previous database state intact.
  static Future<int> seed(DatabaseExecutor db, {AssetBundle? bundle}) async {
    final meals = await SourceMealCatalogLoader.load(bundle: bundle);
    _validateSource(meals);

    await db.delete(MealCatalogTable.tableName);
    final batch = db.batch();
    for (final meal in meals) {
      batch.insert(MealCatalogTable.tableName, meal.toMap());
    }
    await batch.commit(noResult: true);

    final storedRows = await db.query(
      MealCatalogTable.tableName,
      columns: const ['code', 'source_hash'],
    );
    final storedHashes = {
      for (final row in storedRows)
        row['code']?.toString() ?? '': row['source_hash']?.toString() ?? '',
    };
    final sourceHashes = {for (final meal in meals) meal.code: meal.sourceHash};
    if (storedRows.length != expectedMealCount ||
        storedHashes.length != expectedMealCount ||
        !_sameHashes(storedHashes, sourceHashes)) {
      throw StateError('SQLite meal catalog verification failed.');
    }

    return meals.length;
  }

  static void _validateSource(List<MealCatalogItemModel> meals) {
    if (meals.length != expectedMealCount) {
      throw StateError(
        'Expected $expectedMealCount bundled meals, got ${meals.length}.',
      );
    }

    final codes = <String>{};
    for (final meal in meals) {
      if (meal.code.trim().isEmpty || meal.sourceHash.trim().isEmpty) {
        throw StateError('Bundled meal code and source hash are required.');
      }
      if (!codes.add(meal.code)) {
        throw StateError('Duplicate bundled meal code: ${meal.code}.');
      }
    }
  }

  static bool _sameHashes(
    Map<String, String> stored,
    Map<String, String> source,
  ) {
    if (stored.length != source.length) return false;
    for (final entry in source.entries) {
      if (stored[entry.key] != entry.value) return false;
    }
    return true;
  }
}
