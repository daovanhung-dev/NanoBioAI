import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../tables/exercise_planning_preferences_table.dart';
import '../tables/food_evidence_cache_table.dart';

class MigrationV30 {
  const MigrationV30._();

  static Future<void> run(DatabaseExecutor db) async {
    await _addColumn(
      db,
      'meal_catalog',
      'ingredient_quantities_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(db, 'meal_catalog', 'serving_quantity', 'REAL');
    await _addColumn(db, 'meal_catalog', 'serving_unit', 'TEXT');
    await _addColumn(db, 'meal_catalog', 'verified_nutrients_json', 'TEXT');
    await _addColumn(db, 'meal_catalog', 'nutrition_evidence_source', 'TEXT');
    await _addColumn(
      db,
      'meal_catalog',
      'nutrition_food_ids_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(db, 'meal_catalog', 'nutrition_evidence_date', 'TEXT');
    await _addColumn(db, 'meal_catalog', 'nutrition_evidence_version', 'TEXT');
    await _addColumn(
      db,
      'meal_catalog',
      'allergen_verification_status',
      "TEXT NOT NULL DEFAULT 'unknown'",
    );
    await _addColumn(db, 'meal_catalog', 'allergen_evidence_source', 'TEXT');

    await _addColumn(
      db,
      'exercise_catalog',
      'equipment_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'movement_areas_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'limitation_tags_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'condition_contraindications_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'safety_status',
      "TEXT NOT NULL DEFAULT 'unreviewed'",
    );
    await _addColumn(db, 'exercise_catalog', 'safety_source', 'TEXT');
    await _addColumn(db, 'exercise_catalog', 'safety_verified_at', 'TEXT');

    await db.execute(FoodEvidenceCacheTable.createTable);
    await db.execute(FoodEvidenceCacheTable.createRetrievedIndex);
    await db.execute(ExercisePlanningPreferencesTable.createTable);

    // Existing blank tags never meant "verified safe".
    await db.execute('''
      UPDATE meal_catalog
      SET allergen_verification_status = 'unknown'
      WHERE allergen_verification_status IS NULL
         OR TRIM(allergen_verification_status) = ''
    ''');
    await db.execute('''
      UPDATE exercise_catalog
      SET safety_status = 'unreviewed'
      WHERE safety_status IS NULL OR TRIM(safety_status) = ''
    ''');
    await seedBootstrapExerciseMetadata(db);
  }

  static Future<void> seedBootstrapExerciseMetadata(DatabaseExecutor db) async {
    const metadata = <String, ({List<String> equipment, List<String> areas})>{
      'ex_walk_relaxed': (equipment: [], areas: ['leg', 'balance', 'cardio']),
      'ex_mobility_shoulder': (
        equipment: [],
        areas: ['shoulder', 'neck', 'mobility'],
      ),
      'ex_chair_squat': (
        equipment: ['chair'],
        areas: ['knee', 'hip', 'leg', 'strength'],
      ),
      'ex_breathing_stretch': (
        equipment: [],
        areas: ['shoulder', 'upper_body', 'mobility'],
      ),
      'ex_wall_push': (
        equipment: ['wall'],
        areas: ['shoulder', 'wrist', 'strength'],
      ),
      'ex_calf_raise': (
        equipment: [],
        areas: ['ankle', 'leg', 'balance', 'strength'],
      ),
      'ex_yoga_cat_cow': (
        equipment: ['mat'],
        areas: ['back', 'wrist', 'hip', 'mobility'],
      ),
      'ex_step_march': (
        equipment: [],
        areas: ['knee', 'hip', 'leg', 'balance', 'cardio'],
      ),
      'ex_neck_release': (
        equipment: [],
        areas: ['neck', 'shoulder', 'mobility'],
      ),
      'ex_hip_open': (equipment: [], areas: ['hip', 'mobility']),
      'ex_core_breath': (equipment: [], areas: ['back', 'core', 'strength']),
      'ex_balance_stand': (
        equipment: ['wall'],
        areas: ['ankle', 'leg', 'balance'],
      ),
      'ex_light_dance': (equipment: [], areas: ['leg', 'balance', 'cardio']),
      'ex_stair_slow': (
        equipment: ['stairs'],
        areas: ['knee', 'hip', 'ankle', 'balance', 'cardio', 'strength'],
      ),
      'ex_back_stretch': (
        equipment: ['chair'],
        areas: ['back', 'hip', 'mobility'],
      ),
      'ex_tai_chi': (
        equipment: [],
        areas: ['leg', 'balance', 'shoulder', 'cardio', 'mobility'],
      ),
    };
    final batch = db.batch();
    for (final entry in metadata.entries) {
      batch.update(
        'exercise_catalog',
        {
          'equipment_json': _jsonList(entry.value.equipment),
          'movement_areas_json': _jsonList(entry.value.areas),
          'safety_status': 'general_wellness_unreviewed',
        },
        where: 'code = ? AND safety_status = ?',
        whereArgs: [entry.key, 'unreviewed'],
      );
    }
    await batch.commit(noResult: true);
  }

  static String _jsonList(List<String> values) => jsonEncode(values);

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    final mealColumns = await _columns(db, 'meal_catalog');
    final exerciseColumns = await _columns(db, 'exercise_catalog');
    const mealRequired = {
      'ingredient_quantities_json',
      'serving_quantity',
      'serving_unit',
      'verified_nutrients_json',
      'nutrition_evidence_source',
      'nutrition_food_ids_json',
      'nutrition_evidence_date',
      'nutrition_evidence_version',
      'allergen_verification_status',
      'allergen_evidence_source',
    };
    const exerciseRequired = {
      'equipment_json',
      'movement_areas_json',
      'limitation_tags_json',
      'condition_contraindications_json',
      'safety_status',
      'safety_source',
      'safety_verified_at',
    };
    if ((mealColumns.isNotEmpty && !mealColumns.containsAll(mealRequired)) ||
        (exerciseColumns.isNotEmpty &&
            !exerciseColumns.containsAll(exerciseRequired))) {
      await run(db);
      return;
    }
    await db.execute(FoodEvidenceCacheTable.createTable);
    await db.execute(FoodEvidenceCacheTable.createRetrievedIndex);
    await db.execute(ExercisePlanningPreferencesTable.createTable);
  }

  static Future<Set<String>> _columns(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((row) => row['name']?.toString() ?? '').toSet();
  }

  static Future<void> _addColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    if (!(await _columns(db, table)).contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
