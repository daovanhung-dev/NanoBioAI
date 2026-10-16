import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal catalog seeds from the bundled source on create and upgrade', () {
    final databaseService = File(
      'lib/core/storage/localdb/database_service.dart',
    ).readAsStringSync();
    final migration = File(
      'lib/core/storage/localdb/migrations/migration_v29.dart',
    ).readAsStringSync();
    final seeder = File(
      'lib/core/storage/localdb/seeders/meal_catalog_seeder.dart',
    ).readAsStringSync();
    final migrationV36 = File(
      'lib/core/storage/localdb/migrations/migration_v36.dart',
    ).readAsStringSync();

    expect(databaseService, contains('MealCatalogSeeder.seed(db)'));
    expect(databaseService, contains('MigrationV29.run(db)'));
    expect(migration, contains('MealCatalogSeeder.seedLegacy(db)'));
    expect(seeder, contains('SourceMealCatalogLoader.load'));
    expect(
      seeder,
      contains(
        'expectedMealCount =\n      expectedLegacyMealCount + expectedCandidateMealCount',
      ),
    );
    expect(seeder, contains('UnreviewedWellnessMealCatalogLoader.load'));
    expect(seeder, contains("['code', 'source_hash']"));
    expect(migrationV36, contains('expectedCandidateMealCount = 3000'));
    expect(
      migrationV36,
      contains('Migration v36 changed existing catalog row'),
    );
  });

  test('app runtime no longer refreshes meal catalog from Supabase', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final controllerSource = File(
      'lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart',
    ).readAsStringSync();

    expect(mainSource, isNot(contains('MealCatalogCacheRefreshService')));
    expect(controllerSource, isNot(contains('MealCatalogCacheRefreshService')));
    expect(
      File(
        'lib/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart',
      ).existsSync(),
      isFalse,
    );
    expect(mainSource, contains('_startCloudSync()'));
  });
}
