import 'dart:convert';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/exercise_planning_preferences_table.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/exercise_planning_preferences.dart';

class ExercisePlanningPreferencesLocalDatasource {
  final Database? databaseOverride;
  final DateTime Function() now;

  const ExercisePlanningPreferencesLocalDatasource({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<ExercisePlanningPreferences> loadForUser(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const FormatException('Missing exercise planning user');
    }
    final db = await _db();
    final rows = await db.query(
      ExercisePlanningPreferencesTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      limit: 1,
    );
    if (rows.isEmpty) return const ExercisePlanningPreferences();
    final row = rows.first;
    return ExercisePlanningPreferences(
      availableEquipment: _decodeList(row['equipment_json']),
      mobilityLimitations: _decodeList(row['limitation_tags_json']),
    );
  }

  Future<void> saveForUser(
    String userId,
    ExercisePlanningPreferences preferences,
  ) async {
    final normalizedUserId = userId.trim();
    final errors = preferences.validate();
    if (normalizedUserId.isEmpty || errors.isNotEmpty) {
      throw FormatException(
        errors.firstOrNull ?? 'Missing exercise planning user',
      );
    }
    final db = await _db();
    final timestamp = now().toUtc().toIso8601String();
    await db.insert(ExercisePlanningPreferencesTable.tableName, {
      'user_id': normalizedUserId,
      'equipment_json': jsonEncode(preferences.availableEquipment),
      'limitation_tags_json': jsonEncode(preferences.mobilityLimitations),
      'updated_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  List<String> _decodeList(Object? value) {
    if (value is! String || value.trim().isEmpty) return const [];
    final decoded = jsonDecode(value);
    if (decoded is! List) return const [];
    return decoded
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
