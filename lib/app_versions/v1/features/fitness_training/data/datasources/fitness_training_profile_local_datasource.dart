import 'dart:convert';

import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/fitness_training_profile.dart';

class FitnessTrainingProfileLocalDatasource {
  const FitnessTrainingProfileLocalDatasource({
    this.databaseOverride,
    this.nutritionProfileDatasource = const NutritionProfileLocalDatasource(),
  });

  final Database? databaseOverride;
  final NutritionProfileLocalDatasource nutritionProfileDatasource;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<FitnessTrainingProfileSnapshot> load(
    String? authenticatedUserId,
  ) async {
    final db = await _db();
    final userRows = authenticatedUserId == null
        ? await db.query('users', orderBy: 'created_at DESC', limit: 1)
        : await db.query(
            'users',
            where: 'id = ?',
            whereArgs: [authenticatedUserId],
            limit: 1,
          );
    if (userRows.isEmpty) {
      throw StateError('Hồ sơ chưa sẵn sàng. Hãy hoàn tất các bước ban đầu.');
    }
    final user = userRows.first;
    final userId = user['id']?.toString() ?? '';
    if (userId.isEmpty) throw StateError('Hồ sơ chưa có mã người dùng.');

    final healthRows = await db.query(
      'health_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final habitRows = await db.query(
      'lifestyle_habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final goalRows = await db.query(
      'health_goals',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    final conditionRows = await db.query(
      'health_conditions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    final allergyRows = await db.query(
      'food_allergies',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    final nutrition = await nutritionProfileDatasource.load(userId);
    final routine = await _routine(db, userId);
    final health = healthRows.isEmpty
        ? const <String, Object?>{}
        : healthRows.first;
    final habits = habitRows.isEmpty
        ? const <String, Object?>{}
        : habitRows.first;

    return FitnessTrainingProfileSnapshot(
      userId: userId,
      fullName: user['full_name']?.toString().trim() ?? '',
      birthDate: nutrition.birthDate,
      goals:
          [
                ...goalRows.map((row) => row['goal_name']?.toString() ?? ''),
                ...nutrition.goals
                    .where((goal) => goal.isActive)
                    .map((goal) => goal.name),
              ]
              .where((value) => value.trim().isNotEmpty)
              .toSet()
              .toList(growable: false),
      conditions: conditionRows
          .map((row) => row['condition_name']?.toString() ?? '')
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      foodRestrictions: {
        ...allergyRows.map((row) => row['allergy_name']?.toString() ?? ''),
        ...nutrition.restrictions
            .where((restriction) => restriction.isActive)
            .map((restriction) => restriction.itemName),
      }.where((value) => value.trim().isNotEmpty).toList(growable: false),
      heightCm: _number(health['height_cm']),
      weightKg: _number(health['weight_kg']),
      gender: user['gender']?.toString() ?? '',
      activityLevel: habits['activity_level']?.toString() ?? '',
      sleepTime: routine.weekday.sleepTime,
      wakeTime: routine.weekday.wakeTime,
      mealTimes: routine.weekday.mealTimes.length == 5
          ? routine.weekday.mealTimes
          : DailyRoutinePreferences.defaultValue.weekday.mealTimes,
      workoutTime: routine.weekday.workoutRanges.isNotEmpty
          ? routine.weekday.workoutRanges.first.start
          : '17:30',
    );
  }

  Future<void> saveBirthDate({
    required String userId,
    required DateTime birthDate,
  }) async {
    final profile = await nutritionProfileDatasource.load(userId);
    await nutritionProfileDatasource.save(
      profile.copyWith(
        birthDate: DateTime(birthDate.year, birthDate.month, birthDate.day),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  Future<DailyRoutinePreferences> _routine(Database db, String userId) async {
    final rows = await db.query(
      'survey_answers',
      columns: ['answer_value'],
      where: 'user_id = ? AND question_code = ?',
      whereArgs: [userId, DailyRoutinePreferences.questionCode],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return DailyRoutinePreferences.defaultValue;
    try {
      final value = jsonDecode(rows.first['answer_value']?.toString() ?? '');
      if (value is Map) {
        return DailyRoutinePreferences.fromJson(
          Map<String, Object?>.from(value),
        );
      }
    } catch (_) {
      // Keep the established routine defaults when older survey rows differ.
    }
    return DailyRoutinePreferences.defaultValue;
  }

  double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
