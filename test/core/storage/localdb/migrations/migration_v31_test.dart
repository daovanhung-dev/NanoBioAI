import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v31.dart';
import 'package:nano_app/core/storage/localdb/seeders/fitness_exercise_sqlite_seeder.dart';
import 'package:nano_app/core/storage/localdb/tables/exercise_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_staging_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test('v31 imports all M32 exercises as inactive pending review', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(ExerciseCatalogTable.createTable);
    await db.execute(PersonalScheduleAiRequestsTable.createTable);
    await db.insert('exercise_catalog', {
      'code': 'ex_walk_relaxed',
      'category': 'cardio',
      'title': 'Đi bộ nhẹ',
      'description': 'Bài tập hiện có',
      'unit': 'phút',
      'encouragement': '',
      'min_target': 5,
      'max_target': 30,
      'default_target': 15,
      'intensity_level': 'light',
      'is_active': 1,
    });

    await db.transaction(MigrationV31.run);
    await db.transaction(MigrationV31.run);

    final legacy = await db.query(
      'exercise_catalog',
      where: 'code = ?',
      whereArgs: const ['ex_walk_relaxed'],
    );
    expect(legacy, hasLength(1));
    expect(legacy.single['title'], 'Đi bộ nhẹ');
    expect(legacy.single['is_active'], 1);
    expect(legacy.single['source_catalog'], 'legacy_m02');

    final imported = await db.query(
      'exercise_catalog',
      where: 'source_catalog = ?',
      whereArgs: const ['m32_fitness_training'],
    );
    expect(
      imported,
      hasLength(FitnessExerciseSqliteSeeder.expectedExerciseCount),
    );
    expect(
      imported.every(
        (row) =>
            row['is_active'] == 0 &&
            row['review_status'] ==
                FitnessExerciseSqliteSeeder.pendingReviewStatus &&
            row['safety_status'] ==
                FitnessExerciseSqliteSeeder.pendingReviewStatus &&
            (row['source_hash']?.toString().isNotEmpty ?? false) &&
            (row['source_payload_json']?.toString().isNotEmpty ?? false),
      ),
      isTrue,
    );
    expect(imported.map((row) => row['code']).toSet(), hasLength(24));
    expect(DatabaseVersion.currentVersion, greaterThanOrEqualTo(32));

    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((row) => row['name']);
    expect(tables, contains(PersonalScheduleAiStagingTable.tableName));
  });
}
