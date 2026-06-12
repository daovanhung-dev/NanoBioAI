import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:nano_app/core/storage/localdb/database_service.dart';

import '../../domain/entities/onboarding_entity.dart';
import '../models/onboarding_model.dart';

class OnboardingLocalDatasource {
  const OnboardingLocalDatasource();

  Future<Database> _db() async {
    return DatabaseService.database;
  }

  Future<void> saveOnboarding(OnboardingEntity entity) async {
    final model = OnboardingModel.fromEntity(entity);

    final db = await _db();

    final now = DateTime.now().toIso8601String();

    late final String userId;

    await db.transaction((txn) async {
      /// =========================
      /// USER
      /// =========================

      final users = await txn.query(
        'users',
        where: 'email = ? OR phone = ?',
        whereArgs: [model.email, model.phone],
        limit: 1,
      );

      if (users.isNotEmpty) {
        userId = users.first['id'] as String;

        await txn.update(
          'users',
          {
            'email': model.email,
            'phone': model.phone,
            'full_name': model.fullName,
            'gender': model.gender,
            'birth_year': model.birthYear,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [userId],
        );
      } else {
        // Generate a text primary key (timestamp-based) to match table schema (TEXT PK)
        final generatedId = DateTime.now().millisecondsSinceEpoch.toString();

        await txn.insert('users', {
          'id': generatedId,
          'email': model.email.isEmpty ? null : model.email,
          'phone': model.phone.isEmpty ? null : model.phone,
          'full_name': model.fullName,
          'gender': model.gender,
          'birth_year': model.birthYear,
          'created_at': now,
          'updated_at': now,
        });

        userId = generatedId;
      }

      debugPrint('🔥 USER ID: $userId');

      /// =========================
      /// DELETE OLD
      /// =========================

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

      /// =========================
      /// HEALTH PROFILE
      /// =========================

      await txn.insert(
        'health_profiles',
        _healthProfileRow(model, userId, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      /// =========================
      /// GOALS
      /// =========================

      for (final row in _goalRows(model, userId, now)) {
        await txn.insert(
          'health_goals',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      /// =========================
      /// CONDITIONS
      /// =========================

      for (final row in _conditionRows(model, userId, now)) {
        await txn.insert(
          'health_conditions',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      /// =========================
      /// LIFESTYLE
      /// =========================

      await txn.insert(
        'lifestyle_habits',
        _lifestyleRow(model, userId, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      /// =========================
      /// ALLERGY
      /// =========================

      if (model.hasAllergy) {
        await txn.insert(
          'food_allergies',
          _allergyRow(model, userId, now),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      /// =========================
      /// TREATMENT
      /// =========================

      if (model.hasTreatment) {
        await txn.insert(
          'medical_treatments',
          _treatmentRow(model, userId, now),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      /// =========================
      /// SURVEY
      /// =========================

      for (final row in _surveyRows(model, userId, now)) {
        await txn.insert(
          'survey_answers',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    /// =========================
    /// DEBUG LOG
    /// =========================

    final snapshot = <String, Object?>{
      'users': await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      ),

      'health_profiles': await db.query(
        'health_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),

      'health_goals': await db.query(
        'health_goals',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),

      'health_conditions': await db.query(
        'health_conditions',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),

      'lifestyle_habits': await db.query(
        'lifestyle_habits',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),

      'food_allergies': await db.query(
        'food_allergies',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),

      'medical_treatments': await db.query(
        'medical_treatments',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),

      'survey_answers': await db.query(
        'survey_answers',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),
    };

    debugPrint('╔══════════════════════════════════════════════');

    debugPrint('║ ONBOARDING SAVED TO SQLITE');

    debugPrint('╟─ userId: $userId');

    debugPrint(const JsonEncoder.withIndent('  ').convert(snapshot));

    debugPrint('╚══════════════════════════════════════════════');
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
    ];
  }

  String _goalLabel(String code) {
    const labels = {
      'lose_weight': 'Giảm cân',

      'gain_weight': 'Tăng cân',

      'lose_belly_fat': 'Giảm mỡ bụng',

      'gain_muscle': 'Tăng cơ',

      'improve_digestion': 'Cải thiện tiêu hóa',

      'sleep_better': 'Ngủ ngon hơn',

      'reduce_fatigue': 'Giảm mệt mỏi',

      'increase_energy': 'Tăng năng lượng',

      'beautify_skin': 'Làm đẹp da',

      'immune_boost': 'Tăng đề kháng',

      'stable_blood_sugar': 'Ổn định đường huyết',

      'stable_blood_pressure': 'Ổn định huyết áp',

      'joint_health': 'Cải thiện xương khớp',

      'detox_body': 'Thanh lọc cơ thể',

      'overall_health': 'Cải thiện sức khỏe tổng thể',
    };

    return labels[code] ?? code;
  }

  String _conditionLabel(String code) {
    const labels = {
      'stomach_pain': 'Đau dạ dày',

      'constipation': 'Táo bón',

      'bloating': 'Đầy hơi, khó tiêu',

      'insomnia': 'Mất ngủ',

      'stress': 'Stress, căng thẳng',

      'joint_pain': 'Đau nhức xương khớp',

      'high_blood_sugar': 'Đường huyết cao',

      'blood_pressure_issue': 'Huyết áp cao/thấp',

      'high_cholesterol': 'Mỡ máu cao',

      'fatty_liver': 'Gan nhiễm mỡ',

      'tired_always': 'Hay mệt mỏi',

      'overweight': 'Thừa cân/béo phì',

      'underweight': 'Gầy yếu, khó hấp thu',

      'no_special_issue': 'Không có vấn đề đặc biệt',
    };

    return labels[code] ?? code;
  }
}
