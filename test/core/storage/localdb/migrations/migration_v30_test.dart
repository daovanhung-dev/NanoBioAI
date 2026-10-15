import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v29.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v30.dart';
import 'package:nano_app/core/storage/localdb/seeders/source_meal_catalog_loader.dart';
import 'package:nano_app/core/storage/localdb/tables/exercise_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test(
    'v30 adds safety evidence columns without changing existing records',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(_legacyV29MealTable);
      await db.execute(_legacyV29ExerciseTable);
      await db.insert('meal_catalog', {
        'code': 'legacy-meal',
        'meal_type': 'unclassified',
        'meal_name': 'Món cũ',
        'description': 'Nội dung nguồn',
        'cooking_instructions': 'Cách chế biến',
        'ingredients_json': '["gạo"]',
        'nutrition_status': 'missing_source_data',
        'constraint_metadata_status': 'awaiting_professional_review',
        'metadata_status': 'source_imported',
        'is_plan_eligible': 0,
        'source_name': 'Nguồn món',
        'source_hash': 'sha256-legacy',
        'is_active': 1,
      });
      await db.insert('exercise_catalog', {
        'code': 'legacy-exercise',
        'category': 'cardio',
        'title': 'Đi bộ',
        'description': '',
        'unit': 'phút',
        'encouragement': '',
        'min_target': 5,
        'max_target': 30,
        'default_target': 10,
        'intensity_level': 'light',
        'is_active': 1,
      });

      await db.transaction(MigrationV30.run);
      await db.transaction(MigrationV30.run);

      final meal = (await db.query('meal_catalog')).single;
      expect(meal['code'], 'legacy-meal');
      expect(meal['meal_name'], 'Món cũ');
      expect(meal['source_name'], 'Nguồn món');
      expect(meal['source_hash'], 'sha256-legacy');
      expect(meal['nutrition_status'], 'missing_source_data');
      expect(
        meal['constraint_metadata_status'],
        'awaiting_professional_review',
      );
      expect(meal['is_active'], 1);
      expect(meal['verified_nutrients_json'], isNull);
      expect(meal['serving_quantity'], isNull);
      expect(meal['allergen_verification_status'], 'unknown');
      expect(meal['ingredient_quantities_json'], '[]');

      final exercise = (await db.query('exercise_catalog')).single;
      expect(exercise['code'], 'legacy-exercise');
      expect(exercise['safety_status'], 'unreviewed');
      expect(exercise['equipment_json'], '[]');
      expect(exercise['condition_contraindications_json'], '[]');

      final tableNames = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((row) => row['name']);
      expect(tableNames, contains('food_ingredient_evidence'));
      expect(tableNames, contains('exercise_planning_preferences'));
    },
  );

  test('v30 keeps all 163 v29 meals, hashes, and unverified values', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(MealCatalogTable.createTable);
    await db.execute(ExerciseCatalogTable.createTable);
    await db.transaction(MigrationV29.run);

    final before = await db.query(
      'meal_catalog',
      columns: const [
        'code',
        'meal_name',
        'meal_type',
        'source_hash',
        'source_name',
        'source_page',
        'source_chapter',
        'nutrition_status',
        'constraint_metadata_status',
        'metadata_status',
        'is_plan_eligible',
        'is_active',
      ],
      orderBy: 'code ASC',
    );

    await db.transaction(MigrationV30.run);
    final after = await db.query(
      'meal_catalog',
      columns: const [
        'code',
        'meal_name',
        'meal_type',
        'source_hash',
        'source_name',
        'source_page',
        'source_chapter',
        'nutrition_status',
        'constraint_metadata_status',
        'metadata_status',
        'is_plan_eligible',
        'is_active',
      ],
      orderBy: 'code ASC',
    );
    final sourceMeals = await SourceMealCatalogLoader.load();

    expect(DatabaseVersion.currentVersion, greaterThanOrEqualTo(31));
    expect(after, hasLength(163));
    expect(after, before);
    expect(
      {for (final row in after) row['code']: row['source_hash']},
      {for (final meal in sourceMeals) meal.code: meal.sourceHash},
    );
    final missingDataRows = await db.query(
      'meal_catalog',
      columns: const [
        'verified_nutrients_json',
        'serving_quantity',
        'allergen_verification_status',
      ],
    );
    expect(
      missingDataRows.every((row) => row['verified_nutrients_json'] == null),
      isTrue,
    );
    expect(
      missingDataRows.every((row) => row['serving_quantity'] == null),
      isTrue,
    );
    expect(
      missingDataRows.every(
        (row) => row['allergen_verification_status'] == 'unknown',
      ),
      isTrue,
    );
  });
}

const _legacyV29MealTable = '''
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
  water_ml INTEGER NOT NULL DEFAULT 0,
  sugar_g REAL,
  saturated_fat_g REAL,
  sodium_mg REAL,
  cholesterol_mg REAL,
  potassium_mg REAL,
  calcium_mg REAL,
  iron_mg REAL,
  health_topic_code TEXT,
  health_topic_name TEXT,
  health_topic_description TEXT,
  chapter_number INTEGER,
  chapter_name TEXT,
  ingredients_json TEXT NOT NULL DEFAULT '[]',
  cooking_steps_json TEXT NOT NULL DEFAULT '[]',
  benefits TEXT,
  serving_size TEXT,
  allergen_tags_json TEXT NOT NULL DEFAULT '[]',
  avoid_condition_tags_json TEXT NOT NULL DEFAULT '[]',
  nutrition_status TEXT NOT NULL DEFAULT 'approved',
  constraint_metadata_status TEXT NOT NULL DEFAULT 'approved',
  metadata_status TEXT NOT NULL DEFAULT 'approved',
  is_plan_eligible INTEGER NOT NULL DEFAULT 1,
  source_name TEXT,
  source_page INTEGER,
  source_chapter TEXT,
  source_topic TEXT,
  source_recipe_order INTEGER,
  source_hash TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  is_active INTEGER DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
)
''';

const _legacyV29ExerciseTable = '''
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
  is_active INTEGER DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
)
''';
