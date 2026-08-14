import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/basic_health_calculator_models.dart';
import '../../domain/entities/body_metrics_personal_context.dart';

typedef BodyMetricsDatabaseLoader = Future<Database> Function();

class BodyMetricsLocalDatasource {
  final BodyMetricsDatabaseLoader _databaseLoader;

  BodyMetricsLocalDatasource({BodyMetricsDatabaseLoader? databaseLoader})
      : _databaseLoader = databaseLoader ?? _loadDefaultDatabase;

  static Future<Database> _loadDefaultDatabase() => DatabaseService.database;

  Future<BodyMetricsPersonalContext?> loadPersonalContext() async {
    final db = await _databaseLoader();
    final users = await db.query(
      'users',
      orderBy: 'COALESCE(updated_at, created_at) DESC',
      limit: 1,
    );
    if (users.isEmpty) return null;

    final user = users.first;
    final userId = _string(user['id']);
    if (userId == null) return null;

    final profiles = await db.query(
      'health_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'COALESCE(updated_at, created_at) DESC',
      limit: 1,
    );
    final profile = profiles.isEmpty ? const <String, Object?>{} : profiles.first;

    final tracking = await db.query(
      'health_tracking_logs',
      columns: ['weight_kg', 'log_date', 'updated_at'],
      where: 'user_id = ? AND weight_kg IS NOT NULL AND weight_kg > 0',
      whereArgs: [userId],
      orderBy: 'log_date DESC, updated_at DESC',
      limit: 1,
    );

    final habits = await db.query(
      'lifestyle_habits',
      columns: ['activity_level'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    final today = DateTime.now();
    final startDate = _dateKey(today);
    final endDate = _dateKey(today.add(const Duration(days: 30)));

    final mealRows = await db.rawQuery(
      '''
      SELECT plan_date, SUM(COALESCE(calories, 0)) AS daily_calories
      FROM meal_plans
      WHERE user_id = ? AND plan_date >= ? AND plan_date < ?
      GROUP BY plan_date
      HAVING COUNT(*) >= 3
      ORDER BY plan_date
      ''',
      [userId, startDate, endDate],
    );

    final scheduleRows = await db.rawQuery(
      '''
      SELECT category, source_type
      FROM lifestyle_schedule_items
      WHERE user_id = ? AND schedule_date >= ? AND schedule_date < ?
      ''',
      [userId, startDate, endDate],
    );

    final profileWeight = _double(profile['weight_kg']);
    final trackedWeight = tracking.isEmpty ? null : _double(tracking.first['weight_kg']);
    final profileUpdatedAt = _dateTime(profile['updated_at']) ?? _dateTime(profile['created_at']);
    final trackingUpdatedAt = tracking.isEmpty
        ? null
        : _dateTime(tracking.first['updated_at']) ?? _dateTime(tracking.first['log_date']);
    final useTrackedWeight = trackedWeight != null &&
        (profileUpdatedAt == null ||
            (trackingUpdatedAt != null && trackingUpdatedAt.isAfter(profileUpdatedAt)));
    final weightKg = useTrackedWeight ? trackedWeight : profileWeight ?? trackedWeight;
    final plannedCalories = mealRows.isEmpty
        ? null
        : mealRows
                  .map((row) => _double(row['daily_calories']) ?? 0)
                  .fold<double>(0, (sum, value) => sum + value) /
              mealRows.length;

    final exerciseCount = scheduleRows.where((row) {
      final category = _string(row['category'])?.toLowerCase() ?? '';
      final sourceType = _string(row['source_type'])?.toLowerCase() ?? '';
      return category == 'body' ||
          category.contains('exercise') ||
          sourceType.contains('exercise');
    }).length;

    return BodyMetricsPersonalContext(
      userId: userId,
      fullName: _string(user['full_name']),
      heightCm: _double(profile['height_cm']),
      weightKg: weightKg,
      ageYears: _ageFromBirthYear(_int(user['birth_year']), today),
      sex: _sex(_string(user['gender'])),
      activityLevel: _activity(
        habits.isEmpty ? null : _string(habits.first['activity_level']),
      ),
      averagePlannedCalories: plannedCalories,
      plannedMealDays: mealRows.length,
      plannedScheduleItems: scheduleRows.length,
      plannedExerciseItems: exerciseCount,
      weightFromRecentTracking: useTrackedWeight,
    );
  }

  static int? _ageFromBirthYear(int? birthYear, DateTime now) {
    if (birthYear == null) return null;
    final age = now.year - birthYear;
    return age >= 13 && age <= 120 ? age : null;
  }

  static BasicHealthSex? _sex(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null) return null;
    if (normalized == 'male' || normalized == 'nam' || normalized == 'm') {
      return BasicHealthSex.male;
    }
    if (normalized == 'female' || normalized == 'nu' || normalized == 'nữ' || normalized == 'f') {
      return BasicHealthSex.female;
    }
    return null;
  }

  static BasicHealthActivityLevel? _activity(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'sedentary' || 'low' || 'it_van_dong' || 'ít_vận_động' =>
        BasicHealthActivityLevel.sedentary,
      'light' || 'lightly_active' || 'van_dong_nhe' || 'vận_động_nhẹ' =>
        BasicHealthActivityLevel.light,
      'moderate' || 'medium' || 'moderately_active' || 'van_dong_vua' || 'vận_động_vừa' =>
        BasicHealthActivityLevel.moderate,
      'active' || 'high' || 'very_active' || 'van_dong_cao' || 'vận_động_cao' =>
        BasicHealthActivityLevel.active,
      _ => null,
    };
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String? _string(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _dateTime(Object? value) {
    final text = _string(value);
    return text == null ? null : DateTime.tryParse(text);
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
