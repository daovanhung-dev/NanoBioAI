import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_manager.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_profile_tables.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await _createV16CatalogTables(database);
  });

  tearDown(() => database.close());

  test('V16 to V17 preserves meal data and adds the new schema once', () async {
    await database.insert('meal_plans', <String, Object?>{
      'id': 'meal-1',
      'user_id': 'user-1',
      'meal_type': 'breakfast',
      'meal_name': 'Cháo cũ',
      'is_completed': 0,
    });

    await MigrationManager.runMigrations(database, 16, 17);
    await MigrationManager.runMigrations(database, 16, 17);

    final mealColumns = await database.rawQuery('PRAGMA table_info(meal_plans)');
    final mealColumnNames = mealColumns.map((row) => row['name']).toList();
    expect(
      mealColumnNames,
      containsAll(<String>[
        'catalog_code',
        'ingredients_json',
        'cooking_steps_json',
        'source_name',
        'source_hash',
        'snapshot_schema_version',
        'replacement_count',
      ]),
    );
    expect(
      mealColumnNames.where((name) => name == 'source_hash'),
      hasLength(1),
    );

    final preserved = await database.query(
      'meal_plans',
      where: 'id = ?',
      whereArgs: const <Object?>['meal-1'],
    );
    expect(preserved.single['meal_name'], 'Cháo cũ');

    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name']).toSet();
    expect(names, containsAll(NutritionProfileTables.userOwnedTables));

    final catalogCount = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM meal_catalog'),
    );
    expect(catalogCount, greaterThanOrEqualTo(40));
  });
}

Future<void> _createV16CatalogTables(Database database) async {
  await database.execute('''
CREATE TABLE meal_plans (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  plan_date TEXT,
  meal_type TEXT,
  meal_name TEXT,
  description TEXT,
  calories INTEGER,
  protein REAL,
  carbs REAL,
  fat REAL,
  fiber REAL,
  water_ml INTEGER,
  meal_order INTEGER,
  start_time TEXT,
  end_time TEXT,
  cooking_instructions TEXT,
  is_completed INTEGER,
  ai_generated INTEGER,
  created_at TEXT,
  updated_at TEXT
)
''');
  await database.execute('''
CREATE TABLE meal_catalog (
  code TEXT PRIMARY KEY,
  meal_type TEXT NOT NULL,
  meal_name TEXT NOT NULL,
  description TEXT NOT NULL,
  cooking_instructions TEXT NOT NULL,
  calories INTEGER NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  fiber REAL NOT NULL,
  water_ml INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  await database.execute('''
CREATE TABLE exercise_catalog (
  code TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  unit TEXT NOT NULL,
  encouragement TEXT NOT NULL,
  min_target REAL NOT NULL,
  max_target REAL NOT NULL,
  default_target REAL NOT NULL,
  intensity_level TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  await database.execute('''
CREATE TABLE schedule_task_catalog (
  code TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  target_value REAL NOT NULL,
  unit TEXT NOT NULL,
  encouragement TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
}
