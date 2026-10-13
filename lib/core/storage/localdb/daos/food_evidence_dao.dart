import 'package:sqflite/sqflite.dart';

import '../models/ai_catalog_models.dart';
import '../tables/food_evidence_cache_table.dart';

class FoodEvidenceDao {
  const FoodEvidenceDao(this.db);

  final DatabaseExecutor db;

  Future<Map<String, FoodIngredientEvidence>> getByNames(
    Iterable<String> names,
  ) async {
    final normalized = names
        .map(normalizeFoodEvidenceName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalized.isEmpty) return const {};

    final rows = <Map<String, Object?>>[];
    for (var offset = 0; offset < normalized.length; offset += 900) {
      final chunk = normalized.skip(offset).take(900).toList(growable: false);
      rows.addAll(
        await db.query(
          FoodEvidenceCacheTable.tableName,
          where:
              'normalized_name IN (${List.filled(chunk.length, '?').join(',')})',
          whereArgs: chunk,
        ),
      );
    }
    return {
      for (final row in rows)
        row['normalized_name']?.toString() ?? '':
            FoodIngredientEvidence.fromMap(row),
    };
  }

  Future<void> upsertMany(Iterable<FoodIngredientEvidence> evidence) async {
    final batch = db.batch();
    for (final item in evidence) {
      batch.insert(
        FoodEvidenceCacheTable.tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
