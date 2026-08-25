import 'dart:convert';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/health_review/nabi_health_review_models.dart';
import '../../domain/health_review/nabi_health_review_repository.dart';

class SqliteNabiHealthReviewRepository implements NabiHealthReviewRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  const SqliteNabiHealthReviewRepository({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Database> get _database async =>
      databaseOverride ?? await DatabaseService.database;

  @override
  Future<List<NabiHealthConditionReviewItem>> loadConditions(
    String actorKey,
  ) async {
    final db = await _database;
    final rows = await db.query(
      'health_conditions',
      columns: ['id', 'condition_code', 'condition_name'],
      where: 'user_id = ?',
      whereArgs: [actorKey],
      orderBy: 'created_at ASC',
    );
    return rows
        .map(
          (row) => NabiHealthConditionReviewItem(
            id: row['id']?.toString() ?? '',
            code: row['condition_code']?.toString() ?? '',
            name: _conditionLabel(
              row['condition_code']?.toString() ?? '',
              row['condition_name']?.toString(),
            ),
          ),
        )
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> saveHealthCheckIn({
    required String actorKey,
    required String overallFeeling,
    required Map<String, String> conditionStatusById,
    required String note,
  }) async {
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    final normalizedNote = note.trim();
    await db.transaction((txn) async {
      final resolvedIds = conditionStatusById.entries
          .where((entry) => entry.value == 'resolved')
          .map((entry) => entry.key)
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
      for (final id in resolvedIds) {
        await txn.delete(
          'health_conditions',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, actorKey],
        );
      }

      await txn.insert(
        'survey_answers',
        {
          'id': 'health_check_in:$actorKey:${now().microsecondsSinceEpoch}',
          'user_id': actorKey,
          'question_code': 'health_check_in',
          'answer_value': jsonEncode({
            'overall_feeling': overallFeeling,
            'condition_statuses': conditionStatusById,
            if (normalizedNote.isNotEmpty) 'note': normalizedNote,
            'recorded_at': timestamp,
          }),
          'created_at': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  @override
  Future<NabiGoalReviewSnapshot> loadGoals(String actorKey) async {
    final db = await _database;
    final knownCodes = OnboardingCatalog.goals.map((item) => item.code).toSet();
    final rows = await db.query(
      'health_goals',
      columns: ['goal_code', 'is_active'],
      where: 'user_id = ?',
      whereArgs: [actorKey],
    );
    final selected = rows
        .where((row) => _readBool(row['is_active'], fallback: true))
        .map((row) => row['goal_code']?.toString() ?? '')
        .where(knownCodes.contains)
        .toSet();
    return NabiGoalReviewSnapshot(onboardingGoalCodes: selected);
  }

  @override
  Future<void> replaceOnboardingGoals({
    required String actorKey,
    required Set<String> goalCodes,
  }) async {
    final allowed = OnboardingCatalog.goals.map((item) => item.code).toSet();
    final normalized = goalCodes.where(allowed.contains).toSet();
    if (normalized.isEmpty) {
      throw const FormatException('Choose at least one health goal');
    }
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    final placeholders = List.filled(allowed.length, '?').join(',');
    await db.transaction((txn) async {
      await txn.delete(
        'health_goals',
        where: 'user_id = ? AND goal_code IN ($placeholders)',
        whereArgs: [actorKey, ...allowed],
      );
      for (final code in normalized) {
        await txn.insert(
          'health_goals',
          {
            'id': 'goal:$actorKey:$code',
            'user_id': actorKey,
            'goal_code': code,
            'goal_name': OnboardingCatalog.labelOf(
              OnboardingCatalog.goals,
              code,
              fallback: code,
            ),
            'is_active': 1,
            'created_at': timestamp,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  @override
  Future<NabiMutableProfileSnapshot> loadMutableProfile(String actorKey) async {
    final db = await _database;
    final profileRows = await db.query(
      'health_profiles',
      columns: ['occupation', 'height_cm', 'weight_kg'],
      where: 'user_id = ?',
      whereArgs: [actorKey],
      limit: 1,
    );
    final habitRows = await db.query(
      'lifestyle_habits',
      columns: ['sleep_quality', 'activity_level', 'water_per_day'],
      where: 'user_id = ?',
      whereArgs: [actorKey],
      limit: 1,
    );
    final profile = profileRows.isEmpty
        ? const <String, Object?>{}
        : profileRows.first;
    final habits = habitRows.isEmpty
        ? const <String, Object?>{}
        : habitRows.first;
    return NabiMutableProfileSnapshot(
      occupation: profile['occupation']?.toString() ?? '',
      heightCm: _readDoubleOrNull(profile['height_cm']),
      weightKg: _readDoubleOrNull(profile['weight_kg']),
      sleepQuality: habits['sleep_quality']?.toString() ?? '',
      activityLevel: habits['activity_level']?.toString() ?? '',
      waterPerDay: habits['water_per_day']?.toString() ?? '',
    );
  }

  @override
  Future<void> updateMutableProfile({
    required String actorKey,
    required NabiMutableProfileSnapshot profile,
  }) async {
    final height = profile.heightCm;
    final weight = profile.weightKg;
    if (height == null || height < 80 || height > 250) {
      throw const FormatException('Invalid height');
    }
    if (weight == null || weight < 20 || weight > 350) {
      throw const FormatException('Invalid weight');
    }
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final profileCount = await txn.update(
        'health_profiles',
        {
          'occupation': profile.occupation.trim(),
          'height_cm': height,
          'weight_kg': weight,
          'bmi': bmi,
          'updated_at': timestamp,
        },
        where: 'user_id = ?',
        whereArgs: [actorKey],
      );
      if (profileCount == 0) {
        await txn.insert(
          'health_profiles',
          {
            'id': 'health_profile:$actorKey',
            'user_id': actorKey,
            'occupation': profile.occupation.trim(),
            'height_cm': height,
            'weight_kg': weight,
            'bmi': bmi,
            'created_at': timestamp,
            'updated_at': timestamp,
          },
        );
      }

      final habitCount = await txn.update(
        'lifestyle_habits',
        {
          'sleep_quality': profile.sleepQuality,
          'activity_level': profile.activityLevel,
          'water_per_day': profile.waterPerDay,
        },
        where: 'user_id = ?',
        whereArgs: [actorKey],
      );
      if (habitCount == 0) {
        await txn.insert(
          'lifestyle_habits',
          {
            'id': 'lifestyle:$actorKey',
            'user_id': actorKey,
            'sleep_quality': profile.sleepQuality,
            'activity_level': profile.activityLevel,
            'water_per_day': profile.waterPerDay,
            'created_at': timestamp,
          },
        );
      }
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  String _conditionLabel(String code, String? storedName) {
    final normalizedStored = storedName?.trim();
    if (normalizedStored != null && normalizedStored.isNotEmpty) {
      return normalizedStored;
    }
    return OnboardingCatalog.labelOf(
      OnboardingCatalog.conditions,
      code,
      fallback: code,
    );
  }

  bool _readBool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }

  double? _readDoubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
