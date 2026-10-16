import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ai_catalog_models.dart';
import '../tables/meal_catalog_table.dart';
import 'source_meal_catalog_loader.dart';
import 'unreviewed_wellness_meal_catalog_loader.dart';

class MealCatalogSeeder {
  const MealCatalogSeeder._();

  static const expectedLegacyMealCount = 163;
  static const expectedCandidateMealCount = 3000;
  static const expectedMealCount =
      expectedLegacyMealCount + expectedCandidateMealCount;

  static Future<List<MealCatalogItemModel>> loadLegacy({
    AssetBundle? bundle,
  }) async {
    final meals = await SourceMealCatalogLoader.load(bundle: bundle);
    if (meals.length != expectedLegacyMealCount) {
      throw StateError(
        'Expected $expectedLegacyMealCount bundled legacy meals, '
        'got ${meals.length}.',
      );
    }
    _validateSource(
      meals,
      expectedMealCount: expectedLegacyMealCount,
      expectedCandidateCount: 0,
    );
    return meals;
  }

  static Future<List<MealCatalogItemModel>> loadAll({
    AssetBundle? bundle,
  }) async {
    final legacyMeals = await loadLegacy(bundle: bundle);
    final candidateMeals = await UnreviewedWellnessMealCatalogLoader.load(
      bundle: bundle,
    );
    if (legacyMeals.length != expectedLegacyMealCount ||
        candidateMeals.length != expectedCandidateMealCount) {
      throw StateError(
        'Bundled meal catalog counts do not match the contract.',
      );
    }
    final meals = [...legacyMeals, ...candidateMeals];
    _validateSource(
      meals,
      expectedMealCount: expectedMealCount,
      expectedCandidateCount: expectedCandidateMealCount,
    );
    return meals;
  }

  /// Replaces the shared meal catalog from the bundled source asset.
  ///
  /// Call from SQLite create/upgrade transactions so a failed seed leaves the
  /// previous database state intact.
  static Future<int> seed(DatabaseExecutor db, {AssetBundle? bundle}) async {
    final meals = await loadAll(bundle: bundle);
    return _replaceCatalog(db, meals, expectedMealCount);
  }

  /// Keeps the historical v29 migration output at 163 legacy source rows.
  static Future<int> seedLegacy(
    DatabaseExecutor db, {
    AssetBundle? bundle,
  }) async {
    final meals = await loadLegacy(bundle: bundle);
    return _replaceCatalog(db, meals, expectedLegacyMealCount);
  }

  static Future<int> _replaceCatalog(
    DatabaseExecutor db,
    List<MealCatalogItemModel> meals,
    int expectedCount,
  ) async {
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
    if (storedRows.length != expectedCount ||
        storedHashes.length != expectedCount ||
        !_sameHashes(storedHashes, sourceHashes)) {
      throw StateError('SQLite meal catalog verification failed.');
    }

    return meals.length;
  }

  static void _validateSource(
    List<MealCatalogItemModel> meals, {
    required int expectedMealCount,
    required int expectedCandidateCount,
  }) {
    if (meals.length != expectedMealCount) {
      throw StateError(
        'Expected $expectedMealCount bundled meals, got ${meals.length}.',
      );
    }

    final codes = <String>{};
    var candidateCount = 0;
    for (final meal in meals) {
      if (meal.code.trim().isEmpty || meal.sourceHash.trim().isEmpty) {
        throw StateError('Bundled meal code and source hash are required.');
      }
      if (!codes.add(meal.code)) {
        throw StateError('Duplicate bundled meal code: ${meal.code}.');
      }
      if (meal.isUnreviewedWellnessScheduleCandidate) candidateCount++;
    }
    if (candidateCount != expectedCandidateCount ||
        meals.length - candidateCount !=
            expectedMealCount - expectedCandidateCount) {
      throw StateError(
        'Bundled meal catalog sources do not match the contract.',
      );
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
