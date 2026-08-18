import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/basic_health_calculator_models.dart';
import '../../domain/entities/body_metrics_health_snapshot.dart';
import '../../domain/entities/body_metrics_personal_context.dart';

typedef BodyMetricsDatabaseLoader = Future<Database> Function();

class BodyMetricsLocalDatasource {
  final BodyMetricsDatabaseLoader _databaseLoader;

  BodyMetricsLocalDatasource({BodyMetricsDatabaseLoader? databaseLoader})
      : _databaseLoader = databaseLoader ?? _loadDefaultDatabase;

  static Future<Database> _loadDefaultDatabase() => DatabaseService.database;

  /// Compatibility entry point for existing M04 consumers/tests.
  /// When no subject is supplied, it only resolves a local user when exactly
  /// one candidate exists; storage recency is never used as identity.
  Future<BodyMetricsPersonalContext?> loadPersonalContext({String? userId}) async {
    final snapshot = await loadHealthSnapshot(userId: userId);
    if (snapshot == null) return null;
    final nutrition30 = snapshot.nutritionWithinDays(30);
    final averageCalories = _average(
      nutrition30.map((row) => row.calories).whereType<double>(),
    );
    return BodyMetricsPersonalContext(
      userId: snapshot.userId,
      fullName: snapshot.fullName,
      heightCm: snapshot.heightCm,
      weightKg: snapshot.currentWeightKg,
      ageYears: snapshot.ageYears,
      sex: snapshot.sex,
      activityLevel: snapshot.activityLevel,
      averagePlannedCalories: averageCalories,
      plannedMealDays: nutrition30.length,
      plannedScheduleItems: snapshot.schedule.plannedTaskCount,
      plannedExerciseItems: snapshot.schedule.plannedExerciseCount,
      weightFromRecentTracking: snapshot.latestTrackedWeightKg != null,
    );
  }

  Future<BodyMetricsHealthSnapshot?> loadHealthSnapshot({String? userId}) async {
    final db = await _databaseLoader();
    final subjectId = await _resolveSubjectId(db, userId);
    if (subjectId == null) return null;

    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [subjectId],
      limit: 1,
    );
    if (users.isEmpty) return null;
    final user = users.first;

    final profiles = await db.query(
      'health_profiles',
      where: 'user_id = ?',
      whereArgs: [subjectId],
      orderBy: 'COALESCE(updated_at, created_at) DESC',
      limit: 1,
    );
    final profile = profiles.isEmpty ? const <String, Object?>{} : profiles.first;

    final now = DateTime.now();
    final start60 = _dateKey(now.subtract(const Duration(days: 59)));
    final start30 = _dateKey(now.subtract(const Duration(days: 29)));
    final today = _dateKey(now);

    final trackingRows = await db.query(
      'health_tracking_logs',
      columns: const [
        'weight_kg',
        'calories',
        'water_ml',
        'sleep_hours',
        'stress_level',
        'steps_count',
        'heart_rate_bpm',
        'oxygen_saturation',
        'daily_score',
        'mood',
        'log_date',
        'created_at',
        'updated_at',
      ],
      where: 'user_id = ? AND log_date >= ? AND log_date <= ?',
      whereArgs: [subjectId, start60, today],
      orderBy: 'log_date DESC, updated_at DESC',
    );

    final nutritionRows = await db.rawQuery(
      '''
      SELECT
        plan_date,
        SUM(calories) AS calories,
        SUM(protein) AS protein,
        SUM(carbs) AS carbs,
        SUM(fat) AS fat,
        SUM(fiber) AS fiber,
        SUM(water_ml) AS water_ml,
        SUM(sugar_g) AS sugar_g,
        SUM(saturated_fat_g) AS saturated_fat_g,
        SUM(sodium_mg) AS sodium_mg,
        SUM(cholesterol_mg) AS cholesterol_mg,
        SUM(potassium_mg) AS potassium_mg,
        SUM(calcium_mg) AS calcium_mg,
        SUM(iron_mg) AS iron_mg,
        AVG(CASE WHEN COALESCE(is_completed, 0) = 1 THEN 1.0 ELSE 0.0 END) AS completion_rate,
        COUNT(*) AS meal_count
      FROM meal_plans
      WHERE user_id = ? AND plan_date >= ? AND plan_date <= ?
      GROUP BY plan_date
      ORDER BY plan_date DESC
      ''',
      [subjectId, start30, today],
    );

    final habitRows = await db.query(
      'lifestyle_habits',
      where: 'user_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    final conditionRows = await db.query(
      'health_conditions',
      columns: const ['condition_code', 'condition_name', 'severity_level'],
      where: 'user_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    final allergyRows = await db.query(
      'food_allergies',
      columns: const ['allergy_name'],
      where: 'user_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    final treatmentRows = await db.query(
      'medical_treatments',
      columns: const ['treatment_name', 'medication_name'],
      where: 'user_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    final goalRows = await db.query(
      'health_goals',
      columns: const ['goal_code', 'goal_name'],
      where: 'user_id = ? AND COALESCE(is_active, 1) = 1',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    final scheduleRows = await db.query(
      'lifestyle_schedule_items',
      columns: const [
        'category',
        'source_type',
        'is_completed',
        'schedule_date',
        'completed_at',
        'updated_at',
      ],
      where: 'user_id = ? AND schedule_date >= ? AND schedule_date <= ?',
      whereArgs: [subjectId, start30, today],
      orderBy: 'schedule_date DESC, sort_order ASC',
    );

    return BodyMetricsHealthSnapshot(
      userId: subjectId,
      fullName: _string(user['full_name']),
      ageYears: _ageFromBirthYear(_int(user['birth_year']), now),
      sex: _sex(_string(user['gender'])),
      heightCm: _double(profile['height_cm']),
      profileWeightKg: _double(profile['weight_kg']),
      occupation: _string(profile['occupation']),
      bloodPressure: _string(profile['blood_pressure']),
      bloodSugar: _string(profile['blood_sugar']),
      profileUpdatedAt: _dateTime(profile['updated_at']) ?? _dateTime(profile['created_at']),
      tracking: trackingRows.map(_trackingPoint).whereType<BodyMetricsTrackingPoint>().toList(growable: false),
      nutrition: nutritionRows.map(_nutritionDay).whereType<BodyMetricsNutritionDay>().toList(growable: false),
      lifestyle: habitRows.isEmpty ? null : _lifestyle(habitRows.first),
      declaredConditions: conditionRows.map((row) {
        final code = _string(row['condition_code']);
        final name = _string(row['condition_name']) ?? code;
        if (code == null || name == null) return null;
        return BodyMetricsDeclaredCondition(
          code: code,
          name: name,
          severityLevel: _int(row['severity_level']),
        );
      }).whereType<BodyMetricsDeclaredCondition>().toList(growable: false),
      allergies: allergyRows.map((row) => _string(row['allergy_name'])).whereType<String>().toList(growable: false),
      treatments: treatmentRows.map((row) => BodyMetricsTreatmentContext(
        treatmentName: _string(row['treatment_name']),
        medicationName: _string(row['medication_name']),
      )).where((row) => row.treatmentName != null || row.medicationName != null).toList(growable: false),
      activeGoals: goalRows.map((row) {
        final code = _string(row['goal_code']);
        final name = _string(row['goal_name']) ?? code;
        if (code == null || name == null) return null;
        return BodyMetricsDeclaredGoal(code: code, name: name);
      }).whereType<BodyMetricsDeclaredGoal>().toList(growable: false),
      schedule: _scheduleSummary(scheduleRows),
      generatedAt: now,
      contextLoaded: true,
    );
  }

  Future<String?> _resolveSubjectId(Database db, String? supplied) async {
    final normalized = supplied?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    final candidates = await db.query('users', columns: const ['id'], limit: 2);
    if (candidates.length != 1) return null;
    return _string(candidates.single['id']);
  }

  static BodyMetricsTrackingPoint? _trackingPoint(Map<String, Object?> row) {
    final date = _dateTime(row['log_date']);
    if (date == null) return null;
    return BodyMetricsTrackingPoint(
      date: date,
      weightKg: _positive(_double(row['weight_kg'])),
      calories: _nonNegative(_double(row['calories'])),
      waterMl: _nonNegative(_double(row['water_ml'])),
      sleepHours: _nonNegative(_double(row['sleep_hours'])),
      stressLevel: _nonNegative(_double(row['stress_level'])),
      steps: _nonNegative(_double(row['steps_count'])),
      heartRateBpm: _positive(_double(row['heart_rate_bpm'])),
      oxygenSaturation: _positive(_double(row['oxygen_saturation'])),
      dailyScore: _nonNegative(_double(row['daily_score'])),
      mood: _string(row['mood']),
    );
  }

  static BodyMetricsNutritionDay? _nutritionDay(Map<String, Object?> row) {
    final date = _dateTime(row['plan_date']);
    if (date == null) return null;
    return BodyMetricsNutritionDay(
      date: date,
      calories: _nonNegative(_double(row['calories'])),
      proteinG: _nonNegative(_double(row['protein'])),
      carbsG: _nonNegative(_double(row['carbs'])),
      fatG: _nonNegative(_double(row['fat'])),
      fiberG: _nonNegative(_double(row['fiber'])),
      waterMl: _nonNegative(_double(row['water_ml'])),
      sugarG: _nonNegative(_double(row['sugar_g'])),
      saturatedFatG: _nonNegative(_double(row['saturated_fat_g'])),
      sodiumMg: _nonNegative(_double(row['sodium_mg'])),
      cholesterolMg: _nonNegative(_double(row['cholesterol_mg'])),
      potassiumMg: _nonNegative(_double(row['potassium_mg'])),
      calciumMg: _nonNegative(_double(row['calcium_mg'])),
      ironMg: _nonNegative(_double(row['iron_mg'])),
      mealCompletionRate: (_double(row['completion_rate']) ?? 0).clamp(0.0, 1.0).toDouble(),
      mealCount: _int(row['meal_count']) ?? 0,
    );
  }

  static BodyMetricsLifestyleContext _lifestyle(Map<String, Object?> row) {
    return BodyMetricsLifestyleContext(
      skipBreakfast: _bool(row['skip_breakfast']),
      eatLate: _bool(row['eat_late']),
      eatSweet: _bool(row['eat_sweet']),
      eatOily: _bool(row['eat_oily']),
      lowVegetable: _bool(row['low_vegetable']),
      lowWater: _bool(row['low_water']),
      fastFood: _bool(row['fast_food']),
      alcohol: _bool(row['alcohol']),
      coffeeHigh: _bool(row['coffee_high']),
      sleepQuality: _string(row['sleep_quality']),
      waterPerDay: _string(row['water_per_day']),
      activityLevel: _activity(_string(row['activity_level'])),
      updatedAt: _dateTime(row['created_at']),
    );
  }

  static BodyMetricsScheduleSummary _scheduleSummary(List<Map<String, Object?>> rows) {
    var completed = 0;
    var exercise = 0;
    var exerciseCompleted = 0;
    var hydration = 0;
    var hydrationCompleted = 0;
    var sleep = 0;
    var sleepCompleted = 0;
    DateTime? latest;
    for (final row in rows) {
      final done = _bool(row['is_completed']);
      if (done) completed++;
      final category = (_string(row['category']) ?? '').toLowerCase();
      final source = (_string(row['source_type']) ?? '').toLowerCase();
      final token = '$category $source';
      if (token.contains('exercise') || token.contains('workout') || category == 'body') {
        exercise++;
        if (done) exerciseCompleted++;
      }
      if (token.contains('water') || token.contains('hydrat')) {
        hydration++;
        if (done) hydrationCompleted++;
      }
      if (token.contains('sleep') || token.contains('rest')) {
        sleep++;
        if (done) sleepCompleted++;
      }
      final date = _dateTime(row['updated_at']) ?? _dateTime(row['completed_at']) ?? _dateTime(row['schedule_date']);
      if (date != null && (latest == null || date.isAfter(latest))) latest = date;
    }
    return BodyMetricsScheduleSummary(
      plannedTaskCount: rows.length,
      completedTaskCount: completed,
      plannedExerciseCount: exercise,
      completedExerciseCount: exerciseCompleted,
      plannedHydrationCount: hydration,
      completedHydrationCount: hydrationCompleted,
      plannedSleepCount: sleep,
      completedSleepCount: sleepCompleted,
      latestUpdatedAt: latest,
    );
  }

  static int? _ageFromBirthYear(int? birthYear, DateTime now) {
    if (birthYear == null) return null;
    final age = now.year - birthYear;
    return age >= 13 && age <= 120 ? age : null;
  }

  static BasicHealthSex? _sex(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'male' || normalized == 'nam' || normalized == 'm') return BasicHealthSex.male;
    if (normalized == 'female' || normalized == 'nu' || normalized == 'nữ' || normalized == 'f') return BasicHealthSex.female;
    return null;
  }

  static BasicHealthActivityLevel? _activity(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'sedentary' || 'low' || 'it_van_dong' || 'ít_vận_động' => BasicHealthActivityLevel.sedentary,
      'light' || 'lightly_active' || 'van_dong_nhe' || 'vận_động_nhẹ' => BasicHealthActivityLevel.light,
      'moderate' || 'medium' || 'moderately_active' || 'van_dong_vua' || 'vận_động_vừa' => BasicHealthActivityLevel.moderate,
      'active' || 'high' || 'very_active' || 'van_dong_cao' || 'vận_động_cao' => BasicHealthActivityLevel.active,
      _ => null,
    };
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String? _string(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static DateTime? _dateTime(Object? value) {
    final text = _string(value);
    return text == null ? null : DateTime.tryParse(text);
  }

  static double? _positive(double? value) => value != null && value > 0 ? value : null;
  static double? _nonNegative(double? value) => value != null && value >= 0 ? value : null;

  static double? _average(Iterable<double> values) {
    final list = values.where((value) => value.isFinite).toList(growable: false);
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
