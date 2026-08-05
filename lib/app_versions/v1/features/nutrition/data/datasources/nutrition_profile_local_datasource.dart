import 'dart:math';

import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_profile_tables.dart';
import 'package:sqflite/sqflite.dart';

class NutritionProfileLocalDatasource {
  const NutritionProfileLocalDatasource({this.databaseOverride});

  final Database? databaseOverride;

  Future<Database> _database() async {
    final override = databaseOverride;
    if (override != null) return override;
    return DatabaseService.database;
  }

  Future<NutritionProfileEntity> load(String userId) async {
    final database = await _database();
    final profileRows = await database.query(
      NutritionProfileTables.nutritionProfiles,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final profile = profileRows.isEmpty
        ? NutritionProfileEntity.empty(userId)
        : _profileFromMap(profileRows.first);

    final restrictions = await _queryCollection(
      database,
      NutritionProfileTables.foodRestrictions,
      userId,
      (row) => FoodRestrictionEntity(
        id: _string(row['id']),
        type: _string(row['restriction_type']),
        itemName: _string(row['item_name']),
        severityLevel: _nullableInt(row['severity_level']),
        note: _string(row['note']),
        isActive: _bool(row['is_active'], fallback: true),
      ),
    );
    final symptoms = await _queryCollection(
      database,
      NutritionProfileTables.healthSymptoms,
      userId,
      (row) => HealthSymptomEntity(
        id: _string(row['id']),
        symptomType: _string(row['symptom_type']),
        bodyLocation: _string(row['body_location']),
        severityLevel: _nullableInt(row['severity_level']),
        startedAt: _date(row['started_at']),
        triggerNote: _string(row['trigger_note']),
        impactNote: _string(row['impact_note']),
        note: _string(row['note']),
        isActive: _bool(row['is_active'], fallback: true),
      ),
    );
    final medications = await _queryCollection(
      database,
      NutritionProfileTables.medicationRecords,
      userId,
      (row) => MedicationRecordEntity(
        id: _string(row['id']),
        name: _string(row['name']),
        productType: _stringOr(row['product_type'], 'medication'),
        usageSchedule: _string(row['usage_schedule']),
        prescriberConfirmed: _bool(row['prescriber_confirmed']),
        note: _string(row['note']),
        isActive: _bool(row['is_active'], fallback: true),
      ),
    );
    final labResults = await _queryCollection(
      database,
      NutritionProfileTables.labResults,
      userId,
      (row) => LabResultEntity(
        id: _string(row['id']),
        testCode: _string(row['test_code']),
        testName: _string(row['test_name']),
        valueText: _string(row['value_text']),
        unit: _string(row['unit']),
        measuredAt: _date(row['measured_at']),
        referenceNote: _string(row['reference_note']),
        note: _string(row['note']),
      ),
    );
    final goals = await _queryCollection(
      database,
      NutritionProfileTables.nutritionGoals,
      userId,
      (row) => NutritionGoalEntity(
        id: _string(row['id']),
        code: _string(row['goal_code']),
        name: _string(row['goal_name']),
        priority: _nullableInt(row['priority']) ?? 1,
        targetPeriod: _string(row['target_period']),
        targetDate: _date(row['target_date']),
        isActive: _bool(row['is_active'], fallback: true),
      ),
    );
    final mealPreferences = await _queryCollection(
      database,
      NutritionProfileTables.mealSchedulePreferences,
      userId,
      (row) => MealSchedulePreferenceEntity(
        id: _string(row['id']),
        mealType: _string(row['meal_type']),
        startTime: _string(row['start_time']),
        endTime: _string(row['end_time']),
        portionNote: _string(row['portion_note']),
        targetCalories: _nullableInt(row['target_calories']),
        note: _string(row['note']),
        isActive: _bool(row['is_active'], fallback: true),
      ),
    );
    final preferenceRules = await _queryCollection(
      database,
      NutritionProfileTables.nutritionPreferenceRules,
      userId,
      (row) => NutritionPreferenceRuleEntity(
        id: _string(row['id']),
        ruleType: _string(row['rule_type']),
        itemCode: _string(row['item_code']),
        itemName: _string(row['item_name']),
        preferenceLevel: _string(row['preference_level']),
        note: _string(row['note']),
        isActive: _bool(row['is_active'], fallback: true),
        schemaVersion: _nullableInt(row['schema_version']) ?? 1,
      ),
    );

    return profile.copyWith(
      restrictions: restrictions,
      symptoms: symptoms,
      medications: medications,
      labResults: labResults,
      goals: goals,
      mealPreferences: mealPreferences,
      preferenceRules: preferenceRules,
    );
  }

  Future<void> save(NutritionProfileEntity profile) async {
    if (profile.userId.trim().isEmpty) {
      throw const FormatException('Nutrition profile requires a user id.');
    }
    if (profile.goals.where((goal) => goal.isActive).length > 3) {
      throw const FormatException('Nutrition profile supports up to 3 goals.');
    }
    final database = await _database();
    final now = DateTime.now().toUtc().toIso8601String();

    await database.transaction((transaction) async {
      final profileId = profile.id.trim().isEmpty ? _uuidV4() : profile.id;
      await transaction.insert(
        NutritionProfileTables.nutritionProfiles,
        {
          'id': profileId,
          'user_id': profile.userId,
          'birth_date': profile.birthDate?.toIso8601String(),
          'waist_cm': profile.waistCm,
          'current_status': _nullableText(profile.currentStatus),
          'average_sleep_hours': profile.averageSleepHours,
          'smoking_status': profile.smokingStatus,
          'smoking_amount_note': _nullableText(profile.smokingAmountNote),
          'alcohol_frequency': profile.alcoholFrequency,
          'coffee_frequency': profile.coffeeFrequency,
          'target_weight_kg': profile.targetWeightKg,
          'target_weight_source': _nullableText(profile.targetWeightSource),
          'water_restriction': profile.waterRestriction ? 1 : 0,
          'water_restriction_note': _nullableText(
            profile.waterRestrictionNote,
          ),
          'nocturia_level': profile.nocturiaLevel,
          'schema_version': profile.schemaVersion,
          'created_at': profile.createdAt.trim().isEmpty
              ? now
              : profile.createdAt,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.foodRestrictions,
        userId: profile.userId,
        rows: profile.restrictions.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'restriction_type': item.type,
            'item_name': item.itemName.trim(),
            'severity_level': item.severityLevel,
            'note': _nullableText(item.note),
            'is_active': item.isActive ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.healthSymptoms,
        userId: profile.userId,
        rows: profile.symptoms.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'symptom_type': item.symptomType.trim(),
            'body_location': _nullableText(item.bodyLocation),
            'severity_level': item.severityLevel,
            'started_at': item.startedAt?.toIso8601String(),
            'trigger_note': _nullableText(item.triggerNote),
            'impact_note': _nullableText(item.impactNote),
            'note': _nullableText(item.note),
            'is_active': item.isActive ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.medicationRecords,
        userId: profile.userId,
        rows: profile.medications.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'name': item.name.trim(),
            'product_type': item.productType,
            'usage_schedule': _nullableText(item.usageSchedule),
            'prescriber_confirmed': item.prescriberConfirmed ? 1 : 0,
            'note': _nullableText(item.note),
            'is_active': item.isActive ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.labResults,
        userId: profile.userId,
        rows: profile.labResults.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'test_code': _nullableText(item.testCode),
            'test_name': item.testName.trim(),
            'value_text': item.valueText.trim(),
            'unit': _nullableText(item.unit),
            'measured_at': item.measuredAt?.toIso8601String(),
            'reference_note': _nullableText(item.referenceNote),
            'note': _nullableText(item.note),
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.nutritionGoals,
        userId: profile.userId,
        rows: profile.goals.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'goal_code': item.code,
            'goal_name': item.name,
            'priority': item.priority.clamp(1, 3),
            'target_period': _nullableText(item.targetPeriod),
            'target_date': item.targetDate?.toIso8601String(),
            'is_active': item.isActive ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.mealSchedulePreferences,
        userId: profile.userId,
        rows: profile.mealPreferences.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'meal_type': item.mealType,
            'start_time': _nullableText(item.startTime),
            'end_time': _nullableText(item.endTime),
            'portion_note': _nullableText(item.portionNote),
            'target_calories': item.targetCalories,
            'note': _nullableText(item.note),
            'is_active': item.isActive ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      await _replaceCollection(
        transaction,
        table: NutritionProfileTables.nutritionPreferenceRules,
        userId: profile.userId,
        rows: profile.preferenceRules.map(
          (item) => {
            'id': item.id.trim().isEmpty ? _uuidV4() : item.id,
            'user_id': profile.userId,
            'rule_type': item.ruleType,
            'item_code': _nullableText(item.itemCode),
            'item_name': item.itemName.trim(),
            'preference_level': item.preferenceLevel,
            'note': _nullableText(item.note),
            'schema_version': item.schemaVersion,
            'is_active': item.isActive ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
    });

    LocalUserDataSyncDispatcher.requestImmediateSync(database: database);
  }

  Future<List<T>> _queryCollection<T>(
    Database database,
    String table,
    String userId,
    T Function(Map<String, Object?> row) mapper,
  ) async {
    final rows = await database.query(
      table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(mapper).toList(growable: false);
  }

  Future<void> _replaceCollection(
    Transaction transaction, {
    required String table,
    required String userId,
    required Iterable<Map<String, Object?>> rows,
  }) async {
    await transaction.delete(table, where: 'user_id = ?', whereArgs: [userId]);
    for (final row in rows) {
      final hasRequiredName = switch (table) {
        NutritionProfileTables.foodRestrictions =>
          _string(row['item_name']).isNotEmpty,
        NutritionProfileTables.healthSymptoms =>
          _string(row['symptom_type']).isNotEmpty,
        NutritionProfileTables.medicationRecords =>
          _string(row['name']).isNotEmpty,
        NutritionProfileTables.labResults =>
          _string(row['test_name']).isNotEmpty &&
              _string(row['value_text']).isNotEmpty,
        NutritionProfileTables.nutritionGoals =>
          _string(row['goal_code']).isNotEmpty,
        NutritionProfileTables.mealSchedulePreferences =>
          _string(row['meal_type']).isNotEmpty,
        NutritionProfileTables.nutritionPreferenceRules =>
          _string(row['item_name']).isNotEmpty,
        _ => true,
      };
      if (!hasRequiredName) continue;
      await transaction.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  NutritionProfileEntity _profileFromMap(Map<String, Object?> row) {
    return NutritionProfileEntity(
      id: _string(row['id']),
      userId: _string(row['user_id']),
      birthDate: _date(row['birth_date']),
      waistCm: _nullableDouble(row['waist_cm']),
      currentStatus: _string(row['current_status']),
      averageSleepHours: _nullableDouble(row['average_sleep_hours']),
      smokingStatus: _stringOr(row['smoking_status'], 'not_provided'),
      smokingAmountNote: _string(row['smoking_amount_note']),
      alcoholFrequency: _stringOr(row['alcohol_frequency'], 'not_provided'),
      coffeeFrequency: _stringOr(row['coffee_frequency'], 'not_provided'),
      targetWeightKg: _nullableDouble(row['target_weight_kg']),
      targetWeightSource: _string(row['target_weight_source']),
      waterRestriction: _bool(row['water_restriction']),
      waterRestrictionNote: _string(row['water_restriction_note']),
      nocturiaLevel: _stringOr(row['nocturia_level'], 'not_provided'),
      schemaVersion: _nullableInt(row['schema_version']) ?? 1,
      createdAt: _string(row['created_at']),
      updatedAt: _string(row['updated_at']),
    );
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final text = bytes.map(hex).join();
    return '${text.substring(0, 8)}-${text.substring(8, 12)}-'
        '${text.substring(12, 16)}-${text.substring(16, 20)}-'
        '${text.substring(20)}';
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static String _stringOr(Object? value, String fallback) {
    final text = _string(value);
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static int? _nullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _nullableDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  static DateTime? _date(Object? value) {
    final text = _string(value);
    return text.isEmpty ? null : DateTime.tryParse(text);
  }
}
