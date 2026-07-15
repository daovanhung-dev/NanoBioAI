import 'dart:convert';

import 'package:nano_app/core/storage/localdb/daos/survey_answers_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/survey_answer_model.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/daily_routine_preferences.dart';

class DailyRoutinePreferencesLocalDatasource {
  final Database? databaseOverride;
  final String? Function() currentUserId;
  final DateTime Function() now;

  const DailyRoutinePreferencesLocalDatasource({
    this.databaseOverride,
    String? Function()? currentUserId,
    DateTime Function()? now,
  }) : currentUserId = currentUserId ?? currentSupabaseUserIdOrNull,
       now = now ?? DateTime.now;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<DailyRoutinePreferences?> loadForUser(String userId) async {
    final db = await _db();
    final rows = await db.query(
      SurveyAnswersDao.tableName,
      where: 'user_id = ? AND question_code = ?',
      whereArgs: [userId.trim(), DailyRoutinePreferences.questionCode],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.first['answer_value']?.toString();
    if (value == null || value.trim().isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map) throw const FormatException('Invalid daily routine');
    final preferences = DailyRoutinePreferences.fromJson(
      Map<String, Object?>.from(decoded),
    );
    if (preferences.validate().isNotEmpty) {
      throw const FormatException('Invalid daily routine preferences');
    }
    return preferences;
  }

  Future<String?> resolveCurrentUserId() async {
    final authUserId = currentUserId()?.trim();
    if (authUserId != null && authUserId.isNotEmpty) return authUserId;
    final db = await _db();
    final rows = await db.query(
      'users',
      columns: const ['id'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    final value = rows.firstOrNull?['id']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveForUser(
    String userId,
    DailyRoutinePreferences preferences,
  ) async {
    final normalizedUserId = userId.trim();
    final errors = preferences.validate();
    if (normalizedUserId.isEmpty || errors.isNotEmpty) {
      throw FormatException(errors.firstOrNull ?? 'Missing routine user');
    }
    final db = await _db();
    final timestamp = now().toUtc().toIso8601String();
    await SurveyAnswersDao(db).insert(
      SurveyAnswerModel(
        id: 'daily_routine_v1:$normalizedUserId',
        userId: normalizedUserId,
        questionCode: DailyRoutinePreferences.questionCode,
        answerValue: jsonEncode(preferences.toJson()),
        createdAt: timestamp,
      ),
    );
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }
}
