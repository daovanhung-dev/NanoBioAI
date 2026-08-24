import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

class FoodScanHealthContextDatasource {
  final Database? databaseOverride;

  const FoodScanHealthContextDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<Map<String, Object?>> load(String userId) async {
    final db = await _db();
    final user = await _single(db, 'users', userId, idColumn: 'id');
    final profile = await _single(db, 'health_profiles', userId);
    final lifestyle = await _single(db, 'lifestyle_habits', userId);
    final nutritionProfile = await _single(db, 'nutrition_profiles', userId);

    final today = _dateKey(DateTime.now());
    final todayLogs = await _safeQuery(
      db,
      'nutrition_logs',
      where: "user_id = ? AND substr(eaten_at, 1, 10) = ?",
      whereArgs: [userId, today],
      limit: 100,
    );
    final todayMeals = await _safeQuery(
      db,
      'meal_plans',
      where: 'user_id = ? AND plan_date = ?',
      whereArgs: [userId, today],
      limit: 30,
    );

    final existingTotals = <String, Object?>{
      'calories_kcal': _sumNum(todayLogs, 'calories'),
      'protein_g': _sumNum(todayLogs, 'protein'),
      'carbohydrates_g': _sumNum(todayLogs, 'carbs'),
      'fat_g': _sumNum(todayLogs, 'fat'),
      'planned_calories_kcal': _sumNum(todayMeals, 'calories'),
    };

    return <String, Object?>{
      'user_basic': _select(user, const ['gender', 'birth_year']),
      'health_profile': _select(
        profile,
        const [
          'occupation',
          'height_cm',
          'weight_kg',
          'bmi',
          'blood_pressure',
          'blood_sugar',
        ],
      ),
      'lifestyle_habits': _select(
        lifestyle,
        const [
          'skip_breakfast',
          'eat_late',
          'eat_sweet',
          'eat_oily',
          'low_vegetable',
          'low_water',
          'fast_food',
          'alcohol',
          'coffee_high',
          'sleep_quality',
          'activity_level',
          'water_per_day',
        ],
      ),
      'nutrition_profile': _select(
        nutritionProfile,
        const [
          'birth_date',
          'waist_cm',
          'current_status',
          'average_sleep_hours',
          'smoking_status',
          'alcohol_frequency',
          'coffee_frequency',
          'target_weight_kg',
          'water_restriction',
          'water_restriction_note',
        ],
      ),
      'health_conditions': await _collection(
        db,
        'health_conditions',
        userId,
        const ['condition_code', 'condition_name', 'severity_level'],
        limit: 30,
      ),
      'food_allergies': await _collection(
        db,
        'food_allergies',
        userId,
        const ['allergy_name', 'note'],
        limit: 30,
      ),
      'medical_treatments': await _collection(
        db,
        'medical_treatments',
        userId,
        const ['treatment_name', 'medication_name', 'note'],
        limit: 30,
      ),
      'health_symptoms': await _collection(
        db,
        'health_symptoms',
        userId,
        const [
          'symptom_type',
          'body_location',
          'severity_level',
          'started_at',
          'trigger_note',
          'impact_note',
          'note',
        ],
        whereExtra: 'is_active = 1',
        limit: 30,
      ),
      'medication_records': await _collection(
        db,
        'medication_records',
        userId,
        const [
          'name',
          'product_type',
          'usage_schedule',
          'prescriber_confirmed',
          'note',
        ],
        whereExtra: 'is_active = 1',
        limit: 30,
      ),
      'food_restrictions': await _collection(
        db,
        'food_restrictions',
        userId,
        const ['restriction_type', 'item_name', 'severity_level', 'note'],
        whereExtra: 'is_active = 1',
        limit: 50,
      ),
      'lab_results': await _collection(
        db,
        'lab_results',
        userId,
        const [
          'test_code',
          'test_name',
          'value_text',
          'unit',
          'measured_at',
          'reference_note',
        ],
        orderBy: 'measured_at DESC',
        limit: 15,
      ),
      'health_goals': await _collection(
        db,
        'health_goals',
        userId,
        const ['goal_code', 'goal_name', 'is_active'],
        whereExtra: 'is_active = 1',
        limit: 20,
      ),
      'nutrition_goals': await _collection(
        db,
        'nutrition_goals',
        userId,
        const ['goal_code', 'goal_name', 'priority', 'target_period', 'target_date'],
        whereExtra: 'is_active = 1',
        orderBy: 'priority ASC',
        limit: 10,
      ),
      'nutrition_preference_rules': await _collection(
        db,
        'nutrition_preference_rules',
        userId,
        const ['rule_type', 'item_code', 'item_name', 'preference_level', 'note'],
        whereExtra: 'is_active = 1',
        limit: 50,
      ),
      'today_context': existingTotals,
    };
  }

  Future<Map<String, Object?>> _single(
    Database db,
    String table,
    String userId, {
    String idColumn = 'user_id',
  }) async {
    final rows = await _safeQuery(
      db,
      table,
      where: '$idColumn = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? <String, Object?>{} : rows.first;
  }

  Future<List<Map<String, Object?>>> _collection(
    Database db,
    String table,
    String userId,
    List<String> fields, {
    String? whereExtra,
    String? orderBy,
    required int limit,
  }) async {
    final where = whereExtra == null
        ? 'user_id = ?'
        : 'user_id = ? AND $whereExtra';
    final rows = await _safeQuery(
      db,
      table,
      where: where,
      whereArgs: [userId],
      orderBy: orderBy,
      limit: limit,
    );
    return rows.map((row) => _select(row, fields)).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _safeQuery(
    Database db,
    String table, {
    required String where,
    required List<Object?> whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    try {
      final rows = await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
      return rows.map((row) => Map<String, Object?>.from(row)).toList();
    } on DatabaseException {
      return const [];
    }
  }

  Map<String, Object?> _select(
    Map<String, Object?> source,
    List<String> fields,
  ) {
    final result = <String, Object?>{};
    for (final field in fields) {
      final value = source[field];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      result[field] = value;
    }
    return result;
  }

  double _sumNum(List<Map<String, Object?>> rows, String key) {
    var total = 0.0;
    for (final row in rows) {
      final value = row[key];
      if (value is num) total += value.toDouble();
    }
    return total;
  }

  String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
