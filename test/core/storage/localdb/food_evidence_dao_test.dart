import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/food_evidence_dao.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/tables/food_evidence_cache_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'SQLite evidence cache preserves values, source, and unknown nulls',
    () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, version) async {
            await database.execute(FoodEvidenceCacheTable.createTable);
          },
        ),
      );
      addTearDown(db.close);

      const evidence = FoodIngredientEvidence(
        normalizedName: 'yến mạch',
        queriedName: 'Yến mạch',
        sourceFoodId: 'fdc-123',
        description: 'Oats',
        dataType: 'Foundation',
        nutrients: {'energy_kcal_per_100g': 389.0, 'sodium_mg_per_100g': null},
        sourceName: 'USDA FoodData Central',
        sourceUrl: 'https://fdc.nal.usda.gov/food/fdc-123',
        datasetVersion: '2026-01-01',
        retrievedAt: '2026-10-13T00:00:00.000Z',
        evidenceStatus: 'source_match',
      );
      final dao = FoodEvidenceDao(db);

      await dao.upsertMany([evidence]);
      final cached = await dao.getByNames(['  YẾN   MẠCH ']);

      expect(cached.keys, contains('yến mạch'));
      expect(cached['yến mạch']?.sourceFoodId, 'fdc-123');
      expect(cached['yến mạch']?.sourceName, 'USDA FoodData Central');
      expect(cached['yến mạch']?.nutrients?['energy_kcal_per_100g'], 389.0);
      expect(cached['yến mạch']?.nutrients?['sodium_mg_per_100g'], isNull);
    },
  );
}
