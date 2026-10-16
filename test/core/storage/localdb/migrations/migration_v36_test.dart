import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v36.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/meal_catalog_seeder.dart';
import 'package:nano_app/core/storage/localdb/seeders/source_meal_catalog_loader.dart';
import 'package:nano_app/core/storage/localdb/seeders/unreviewed_wellness_meal_catalog_loader.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test('fresh seeder adds 163 legacy and 3000 candidate meals', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(MealCatalogTable.createTable);

    final seeded = await MealCatalogSeeder.seed(db);
    final rows = await db.query(MealCatalogTable.tableName);
    final parsed = rows.map(MealCatalogItemModel.fromMap).toList();

    expect(seeded, 3163);
    expect(rows, hasLength(3163));
    expect(rows.map((row) => row['code']).toSet(), hasLength(3163));
    expect(
      parsed.where((meal) => meal.code.startsWith('src_')),
      hasLength(163),
    );
    final candidates = parsed
        .where((meal) => meal.code.startsWith('nabi_vn_'))
        .toList(growable: false);
    expect(candidates, hasLength(3000));
    expect(
      candidates.every((meal) => meal.isUnreviewedWellnessScheduleCandidate),
      isTrue,
    );
    expect(candidates.every((meal) => !meal.isPlanEligible), isTrue);
    expect(
      candidates.every(
        (meal) => meal.metadataStatus == 'ai_generated_needs_review',
      ),
      isTrue,
    );
    expect(
      candidates.every(
        (meal) => meal.nutritionStatus == 'estimated_unverified',
      ),
      isTrue,
    );
    expect(
      candidates.every(
        (meal) =>
            meal.constraintMetadataStatus == 'awaiting_professional_review',
      ),
      isTrue,
    );
  });

  test(
    'v35 migration adds candidates and preserves existing rows and user data',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(MealCatalogTable.createTable);
      await db.execute(
        'CREATE TABLE user_owned_fixture (id TEXT PRIMARY KEY, note TEXT NOT NULL)',
      );
      await db.insert('user_owned_fixture', {
        'id': 'kept',
        'note': 'Local user data',
      });

      final legacyMeals = await SourceMealCatalogLoader.load();
      final batch = db.batch();
      for (final meal in legacyMeals) {
        batch.insert(MealCatalogTable.tableName, meal.toMap());
      }
      await batch.commit(noResult: true);
      final legacyBefore = {
        for (final row in await db.query(
          MealCatalogTable.tableName,
          columns: const ['code', 'source_hash', 'meal_name', 'description'],
        ))
          row['code']!.toString(): row,
      };

      final insertedCount = await MigrationV36.run(db);
      final candidateMeals = await UnreviewedWellnessMealCatalogLoader.load();
      final storedRows = await db.query(
        MealCatalogTable.tableName,
        columns: const [
          'code',
          'source_hash',
          'meal_name',
          'description',
          'is_plan_eligible',
          'metadata_status',
          'nutrition_status',
        ],
      );
      final storedByCode = {
        for (final row in storedRows) row['code']!.toString(): row,
      };

      expect(insertedCount, 3000);
      expect(storedRows, hasLength(3163));
      expect(storedByCode, hasLength(3163));
      for (final entry in legacyBefore.entries) {
        expect(
          storedByCode[entry.key]?['source_hash'],
          entry.value['source_hash'],
        );
        expect(storedByCode[entry.key]?['meal_name'], entry.value['meal_name']);
        expect(
          storedByCode[entry.key]?['description'],
          entry.value['description'],
        );
      }
      for (final meal in candidateMeals) {
        final stored = storedByCode[meal.code]!;
        expect(stored['source_hash'], meal.sourceHash);
        expect(stored['is_plan_eligible'], 0);
        expect(stored['metadata_status'], 'ai_generated_needs_review');
        expect(stored['nutrition_status'], 'estimated_unverified');
      }
      expect(await MigrationV36.run(db), 0);
      expect(await db.query('user_owned_fixture'), [
        {'id': 'kept', 'note': 'Local user data'},
      ]);
    },
  );
}
