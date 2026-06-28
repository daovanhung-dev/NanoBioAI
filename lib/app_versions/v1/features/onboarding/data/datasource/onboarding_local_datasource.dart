import 'dart:convert';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:sqflite/sqflite.dart';

import 'package:nano_app/core/storage/localdb/database_service.dart';

import '../../domain/entities/onboarding_entity.dart';
import '../models/onboarding_model.dart';

class OnboardingLocalDatasource {
  static const _tag = 'ONBOARDING';

  final Database? database;

  const OnboardingLocalDatasource({this.database});

  Future<Database> _db() async {
    return database ?? DatabaseService.database;
  }

  Future<String> saveOnboarding(
    OnboardingEntity entity, {
    String? userIdOverride,
  }) async {
    AppLogger.database(_tag, 'Start saving onboarding to SQLite');
    AppLogger.info(_tag, 'Converting entity to model');

    final model = OnboardingModel.fromEntity(entity);

    final db = await _db();
    AppLogger.database(_tag, 'Database connection acquired');

    final now = DateTime.now().toIso8601String();

    late final String userId;

    try {
      await db.transaction((txn) async {
        AppLogger.database(_tag, 'Transaction started');

        /// =========================
        /// USER
        /// =========================
        AppLogger.database(_tag, 'Querying existing user');

        final users = userIdOverride != null
            ? await txn.query(
                'users',
                where: 'id = ?',
                whereArgs: [userIdOverride],
                limit: 1,
              )
            : await txn.query(
                'users',
                where: 'email = ? OR phone = ?',
                whereArgs: [model.email, model.phone],
                limit: 1,
              );

        if (users.isNotEmpty) {
          userId = users.first['id'] as String;
          AppLogger.database(_tag, 'Existing onboarding user found');
          AppLogger.database(_tag, 'Updating user record');

          await txn.update(
            'users',
            {
              'email': model.email,
              'phone': model.phone,
              'full_name': model.fullName,
              'gender': model.gender,
              'birth_year': model.birthYear,
              'onboarding_status':
                  users.first['onboarding_status'] == 'completed'
                  ? 'completed'
                  : 'in_progress',
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [userId],
          );

          AppLogger.success(_tag, 'User record updated successfully');
        } else {
          final generatedId =
              userIdOverride ??
              DateTime.now().millisecondsSinceEpoch.toString();
          AppLogger.database(_tag, 'New onboarding user, generating local ID');

          await txn.insert('users', {
            'id': generatedId,
            'email': model.email.isEmpty ? null : model.email,
            'phone': model.phone.isEmpty ? null : model.phone,
            'full_name': model.fullName,
            'gender': model.gender,
            'birth_year': model.birthYear,
            'product_access_status': userIdOverride == null ? 'guest' : 'free',
            'onboarding_status': 'in_progress',
            'created_at': now,
            'updated_at': now,
          });

          userId = generatedId;
          AppLogger.success(_tag, 'New user record inserted');
        }

        AppLogger.info(_tag, 'Onboarding local user resolved');

        /// =========================
        /// DELETE OLD
        /// =========================
        AppLogger.database(_tag, 'Deleting old health data for user');

        await txn.delete(
          'health_profiles',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.delete(
          'health_goals',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.delete(
          'health_conditions',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.delete(
          'lifestyle_habits',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.delete(
          'food_allergies',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.delete(
          'medical_treatments',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.delete(
          'survey_answers',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        AppLogger.success(_tag, 'Old health data deleted');

        /// =========================
        /// HEALTH PROFILE
        /// =========================
        AppLogger.database(_tag, 'Insert health_profiles');

        await txn.insert(
          'health_profiles',
          _healthProfileRow(model, userId, now),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        AppLogger.success(_tag, 'Health profile inserted');

        /// =========================
        /// GOALS
        /// =========================
        final goalRows = _goalRows(model, userId, now);
        AppLogger.database(_tag, 'Insert ${goalRows.length} health_goals');

        for (final row in goalRows) {
          await txn.insert(
            'health_goals',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        AppLogger.success(_tag, '${goalRows.length} goals inserted');

        /// =========================
        /// CONDITIONS
        /// =========================
        final conditionRows = _conditionRows(model, userId, now);
        AppLogger.database(
          _tag,
          'Insert ${conditionRows.length} health_conditions',
        );

        for (final row in conditionRows) {
          await txn.insert(
            'health_conditions',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        AppLogger.success(_tag, '${conditionRows.length} conditions inserted');

        /// =========================
        /// LIFESTYLE
        /// =========================
        AppLogger.database(_tag, 'Insert lifestyle_habits');

        await txn.insert(
          'lifestyle_habits',
          _lifestyleRow(model, userId, now),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        AppLogger.success(_tag, 'Lifestyle habits inserted');

        /// =========================
        /// ALLERGY
        /// =========================

        if (model.hasAllergy) {
          AppLogger.database(_tag, 'Insert food_allergies');

          await txn.insert(
            'food_allergies',
            _allergyRow(model, userId, now),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          AppLogger.success(_tag, 'Food allergy inserted');
        } else {
          AppLogger.info(_tag, 'No allergy data to insert');
        }

        /// =========================
        /// TREATMENT
        /// =========================

        if (model.hasTreatment) {
          AppLogger.database(_tag, 'Insert medical_treatments');

          await txn.insert(
            'medical_treatments',
            _treatmentRow(model, userId, now),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          AppLogger.success(_tag, 'Medical treatment inserted');
        } else {
          AppLogger.info(_tag, 'No treatment data to insert');
        }

        /// =========================
        /// SURVEY
        /// =========================
        final surveyRows = _surveyRows(model, userId, now);
        AppLogger.database(_tag, 'Insert ${surveyRows.length} survey_answers');

        for (final row in surveyRows) {
          await txn.insert(
            'survey_answers',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        AppLogger.success(_tag, '${surveyRows.length} survey answers inserted');
        AppLogger.database(_tag, 'Transaction completed successfully');
      });

      AppLogger.success(_tag, 'Onboarding data saved to SQLite successfully');
      AppLogger.info(_tag, 'Onboarding local data committed');
      return userId;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to save onboarding to SQLite', e, st);
      rethrow;
    }
  }

  Future<void> markOnboardingCompleted(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final db = await _db();
    await db.update(
      'users',
      {
        'onboarding_status': 'completed',
        'onboarding_completed_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [normalizedUserId],
    );
  }

  Map<String, Object?> _healthProfileRow(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    return {
      'user_id': userId,
      'occupation': model.occupation,
      'height_cm': model.heightCm,
      'weight_kg': model.weightKg,
      'bmi': model.bmi,
      'blood_pressure': null,
      'blood_sugar': null,
      'created_at': now,
      'updated_at': now,
    };
  }

  List<Map<String, Object?>> _goalRows(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    final rows = <Map<String, Object?>>[
      ...model.goals.map((goal) {
        return {
          'user_id': userId,
          'goal_code': goal,
          'goal_name': _goalLabel(goal),
          'is_active': 1,
          'created_at': now,
        };
      }),
    ];

    if (model.otherGoal.trim().isNotEmpty) {
      rows.add({
        'user_id': userId,
        'goal_code': 'other_goal',
        'goal_name': model.otherGoal.trim(),
        'is_active': 1,
        'created_at': now,
      });
    }

    return rows;
  }

  List<Map<String, Object?>> _conditionRows(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    final rows = <Map<String, Object?>>[
      ...model.conditions.map((condition) {
        return {
          'user_id': userId,
          'condition_code': condition,
          'condition_name': _conditionLabel(condition),
          'severity_level': 1,
          'created_at': now,
        };
      }),
    ];

    if (model.otherCondition.trim().isNotEmpty) {
      rows.add({
        'user_id': userId,
        'condition_code': 'other_condition',
        'condition_name': model.otherCondition.trim(),
        'severity_level': 1,
        'created_at': now,
      });
    }

    return rows;
  }

  Map<String, Object?> _lifestyleRow(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    bool has(String code) {
      return model.habits.contains(code);
    }

    return {
      'user_id': userId,
      'skip_breakfast': has('skip_breakfast') ? 1 : 0,

      'eat_late': has('eat_late') ? 1 : 0,

      'eat_sweet': has('eat_sweet') ? 1 : 0,

      'eat_oily': has('eat_oily') ? 1 : 0,

      'low_vegetable': has('low_vegetable') ? 1 : 0,

      'low_water': has('low_water') ? 1 : 0,

      'fast_food': has('fast_food') ? 1 : 0,

      'alcohol': has('alcohol') ? 1 : 0,

      'coffee_high': has('coffee_high') ? 1 : 0,

      'sleep_quality': model.sleepQuality,

      'activity_level': model.activityLevel,

      'water_per_day': model.waterPerDay,

      'created_at': now,
    };
  }

  Map<String, Object?> _allergyRow(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    return {
      'user_id': userId,
      'allergy_name': model.allergyName.trim(),

      'note': model.allergyNote.trim().isEmpty
          ? null
          : model.allergyNote.trim(),

      'created_at': now,
    };
  }

  Map<String, Object?> _treatmentRow(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    final note = [
      model.treatmentNote.trim(),

      if (model.medicationName.trim().isNotEmpty)
        'Thuốc: ${model.medicationName.trim()}',
    ].where((e) => e.isNotEmpty).join(' | ');

    return {
      'user_id': userId,

      'treatment_name': model.treatmentName.trim().isEmpty
          ? 'Đang điều trị'
          : model.treatmentName.trim(),

      'medication_name': model.medicationName.trim().isEmpty
          ? null
          : model.medicationName.trim(),

      'note': note.isEmpty ? null : note,

      'created_at': now,
    };
  }

  List<Map<String, Object?>> _surveyRows(
    OnboardingModel model,
    String userId,
    String now,
  ) {
    return [
      {
        'user_id': userId,
        'question_code': 'full_name',
        'answer_value': model.fullName,
        'created_at': now,
      },

      {
        'user_id': userId,
        'question_code': 'email',
        'answer_value': model.email,
        'created_at': now,
      },

      {
        'user_id': userId,
        'question_code': 'phone',
        'answer_value': model.phone,
        'created_at': now,
      },

      {
        'user_id': userId,
        'question_code': 'gender',
        'answer_value': model.gender,
        'created_at': now,
      },

      {
        'user_id': userId,
        'question_code': 'birth_year',
        'answer_value': model.birthYear.toString(),
        'created_at': now,
      },

      {
        'user_id': userId,
        'question_code': 'concern_text',
        'answer_value': model.concernText,
        'created_at': now,
      },
      {
        'user_id': userId,
        'question_code': 'occupation_code',
        'answer_value': model.occupation,
        'created_at': now,
      },
      {
        'user_id': userId,
        'question_code': 'lifestyle_habit_codes',
        'answer_value': jsonEncode(model.habits),
        'created_at': now,
      },
      {
        'user_id': userId,
        'question_code': 'sleep_quality',
        'answer_value': model.sleepQuality,
        'created_at': now,
      },
      {
        'user_id': userId,
        'question_code': 'activity_level',
        'answer_value': model.activityLevel,
        'created_at': now,
      },
      {
        'user_id': userId,
        'question_code': 'water_per_day',
        'answer_value': model.waterPerDay,
        'created_at': now,
      },
    ];
  }

  String _goalLabel(String code) {
    return OnboardingCatalog.labelOf(
      OnboardingCatalog.goals,
      code,
      fallback: code,
    );
  }

  String _conditionLabel(String code) {
    return OnboardingCatalog.labelOf(
      OnboardingCatalog.conditions,
      code,
      fallback: code,
    );
  }
}
