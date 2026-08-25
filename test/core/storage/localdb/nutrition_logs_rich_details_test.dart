import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/nutrition_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('rich nutrition details survive a legacy replace', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');
    await db.execute('''
CREATE TABLE nutrition_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  food_name TEXT,
  calories INTEGER,
  protein REAL,
  carbs REAL,
  fat REAL,
  meal_type TEXT,
  eaten_at TEXT
)
''');
    await db.execute('''
CREATE TABLE nutrition_log_details (
  nutrition_log_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  serving_quantity REAL,
  serving_unit TEXT,
  nutrition_json TEXT NOT NULL,
  nutrition_source TEXT,
  nutrition_confidence REAL,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    await db.insert('users', {'id': 'user-1'});

    final dao = NutritionLogsDao(db);
    await dao.insert(
      const NutritionLogModel(
        id: 'log-1',
        userId: 'user-1',
        foodName: 'Cơm',
        calories: 500,
        eatenAt: '2026-08-24T12:00:00Z',
        nutrition: {'fiber_g': 6, 'sodium_mg': 500},
        nutritionSource: 'food_scan',
        nutritionConfidence: .9,
      ),
    );

    await db.insert('nutrition_logs', {
      'id': 'log-1',
      'user_id': 'user-1',
      'food_name': 'Cơm cập nhật',
      'calories': 520,
      'eaten_at': '2026-08-24T12:00:00Z',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final loaded = await dao.getById('log-1');
    expect(loaded, isNotNull);
    expect(loaded!.foodName, 'Cơm cập nhật');
    expect(loaded.nutrition['fiber_g'], 6);
    expect(loaded.nutritionSource, 'food_scan');
  });
}
