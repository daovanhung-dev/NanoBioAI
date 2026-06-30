// lib/app_versions/v1/features/dashboard/data/datasource/dashboard_local_datasource.dart
import 'package:sqflite/sqflite.dart';
import 'package:nano_app/core/access/subject_access_context.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../../domain/entities/dashboard_entity.dart';

class DashboardLocalDatasource {
  final Database? database;

  const DashboardLocalDatasource({this.database});

  Future<Database> _db() async {
    return database ?? DatabaseService.database;
  }

  Future<void> saveMealPlan(List<MealPlanModel> mealPlans) async {
    final db = await _db();
    final daoMealPlans = MealPlansDao(db);
    final userId = mealPlans.isEmpty ? null : mealPlans.first.userId;
    final dates =
        mealPlans
            .map((meal) => meal.planDate)
            .where((date) => date.isNotEmpty)
            .toList()
          ..sort();

    if (userId != null && userId.isNotEmpty && dates.isNotEmpty) {
      await daoMealPlans.deleteByUserIdAndDateRange(
        userId: userId,
        startDate: dates.first,
        endDate: dates.last,
      );
    }

    await daoMealPlans.insertMany(mealPlans);
  }

  Future<DashboardEntity> fetchDashboard({
    SubjectAccessContext? subjectAccess,
  }) async {
    final db = await _db();

    final subjectUserId =
        subjectAccess?.resolveSubjectId() ?? currentSupabaseUserIdOrNull();
    final users = subjectUserId == null
        ? await db.query('users', orderBy: 'created_at DESC', limit: 1)
        : await db.query(
            'users',
            where: 'id = ?',
            whereArgs: [subjectUserId],
            limit: 1,
          );

    if (users.isEmpty) {
      throw Exception('Chưa có dữ liệu người dùng trong SQLite.');
    }

    final user = users.first;
    final userId = user['id'].toString();

    final profileRows = await db.query(
      'health_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final profile = profileRows.isNotEmpty
        ? profileRows.first
        : <String, Object?>{};

    final goalRows = await db.query(
      'health_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    final conditionRows = await db.query(
      'health_conditions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    final habitRows = await db.query(
      'lifestyle_habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final lifestyle = habitRows.isNotEmpty
        ? habitRows.first
        : <String, Object?>{};

    final allergyRows = await db.query(
      'food_allergies',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final allergy = allergyRows.isNotEmpty
        ? allergyRows.first
        : <String, Object?>{};

    final treatmentRows = await db.query(
      'medical_treatments',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final treatment = treatmentRows.isNotEmpty
        ? treatmentRows.first
        : <String, Object?>{};

    final surveyRows = await db.query(
      'survey_answers',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    final surveyAnswers = <String, String>{};
    for (final row in surveyRows) {
      final key = row['question_code']?.toString() ?? '';
      final value = row['answer_value']?.toString() ?? '';
      if (key.isNotEmpty) {
        surveyAnswers[key] = value;
      }
    }

    return DashboardEntity(
      userId: _readString(user, 'id'),
      fullName: _readString(user, 'full_name'),
      email: _readString(user, 'email'),
      phone: _readString(user, 'phone'),
      gender: _readString(user, 'gender'),
      birthYear: _readInt(user, 'birth_year'),
      subscriptionTier: _readString(user, 'subscription_tier').isEmpty
          ? 'free'
          : _readString(user, 'subscription_tier'),
      occupation: _readString(profile, 'occupation'),
      heightCm: _readDouble(profile, 'height_cm'),
      weightKg: _readDouble(profile, 'weight_kg'),
      bmi: _readDouble(profile, 'bmi'),
      goals: goalRows
          .map((e) => _readString(e, 'goal_name'))
          .where((e) => e.isNotEmpty)
          .toList(),
      conditions: conditionRows
          .map((e) => _readString(e, 'condition_name'))
          .where((e) => e.isNotEmpty)
          .toList(),
      habits: _readHabitsFromRow(lifestyle),
      sleepQuality: _readString(lifestyle, 'sleep_quality'),
      activityLevel: _readString(lifestyle, 'activity_level'),
      waterPerDay: _readString(lifestyle, 'water_per_day'),
      allergyName: _readString(allergy, 'allergy_name'),
      allergyNote: _readString(allergy, 'note'),
      treatmentName: _readString(treatment, 'treatment_name'),
      medicationName: _readString(treatment, 'medication_name'),
      treatmentNote: _readString(treatment, 'note'),
      concernText: surveyAnswers['concern_text'] ?? '',
      surveyAnswers: surveyAnswers,
    );
  }

  String _readString(Map<String, Object?> row, String key) {
    final value = row[key];
    return value?.toString() ?? '';
  }

  int _readInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDouble(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _readHabitsFromRow(Map<String, Object?> row) {
    final items = <String>[];

    if (_readBool(row, 'skip_breakfast')) items.add('skip_breakfast');
    if (_readBool(row, 'eat_late')) items.add('eat_late');
    if (_readBool(row, 'eat_sweet')) items.add('eat_sweet');
    if (_readBool(row, 'eat_oily')) items.add('eat_oily');
    if (_readBool(row, 'low_vegetable')) items.add('low_vegetable');
    if (_readBool(row, 'low_water')) items.add('low_water');
    if (_readBool(row, 'fast_food')) items.add('fast_food');
    if (_readBool(row, 'alcohol')) items.add('alcohol');
    if (_readBool(row, 'coffee_high')) items.add('coffee_high');

    return items;
  }

  bool _readBool(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes';
  }
}
