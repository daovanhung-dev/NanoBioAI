import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v18.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await _createV17Tables(database);
  });

  tearDown(() => database.close());

  test('database version is 18', () {
    expect(DatabaseVersion.currentVersion, 18);
  });

  test('V18 schema is idempotent and preserves existing meal rows', () async {
    await database.insert('meal_catalog', <String, Object?>{
      'code': 'meal-1',
      'meal_type': 'breakfast',
      'meal_name': 'Cháo cũ',
      'description': '',
      'cooking_instructions': '',
      'calories': 280,
      'protein': 8.0,
      'carbs': 48.0,
      'fat': 6.0,
      'fiber': 5.0,
      'water_ml': 0,
    });
    await database.insert('meal_plans', <String, Object?>{
      'id': 'plan-1',
      'meal_name': 'Cháo cũ',
      'calories': 280,
    });

    await MigrationV18.ensureSchema(database);
    await MigrationV18.ensureSchema(database);

    for (final table in const <String>['meal_catalog', 'meal_plans']) {
      final columns = await database.rawQuery('PRAGMA table_info($table)');
      final names = columns.map((row) => row['name']).toList();
      expect(
        names,
        containsAll(<String>[
          'sugar_g',
          'saturated_fat_g',
          'sodium_mg',
          'cholesterol_mg',
          'potassium_mg',
          'calcium_mg',
          'iron_mg',
          'nutrition_status',
        ]),
      );
      expect(names.where((name) => name == 'sodium_mg'), hasLength(1));
    }

    final catalog = await database.query(
      'meal_catalog',
      where: 'code = ?',
      whereArgs: const <Object?>['meal-1'],
    );
    final plan = await database.query(
      'meal_plans',
      where: 'id = ?',
      whereArgs: const <Object?>['plan-1'],
    );
    expect(catalog.single['meal_name'], 'Cháo cũ');
    expect(catalog.single['calories'], 280);
    expect(plan.single['meal_name'], 'Cháo cũ');
  });
}

Future<void> _createV17Tables(Database database) async {
  await database.execute('''
CREATE TABLE meal_catalog (
  code TEXT PRIMARY KEY,
  meal_type TEXT NOT NULL,
  meal_name TEXT NOT NULL,
  description TEXT NOT NULL,
  cooking_instructions TEXT NOT NULL,
  calories INTEGER NOT NULL DEFAULT 0,
  protein REAL NOT NULL DEFAULT 0,
  carbs REAL NOT NULL DEFAULT 0,
  fat REAL NOT NULL DEFAULT 0,
  fiber REAL NOT NULL DEFAULT 0,
  water_ml INTEGER NOT NULL DEFAULT 0
)
''');
  await database.execute('''
CREATE TABLE meal_plans (
  id TEXT PRIMARY KEY,
  meal_name TEXT,
  calories INTEGER
)
''');
}
