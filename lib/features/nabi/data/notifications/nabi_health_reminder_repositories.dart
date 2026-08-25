import 'dart:convert';
import 'dart:math';

import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/nabi_notification_tables.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/notifications/nabi_health_reminder_preferences.dart';
import '../../domain/notifications/nabi_health_reminder_repositories.dart';

class SqliteNabiHealthReminderPreferencesRepository
    implements NabiHealthReminderPreferencesRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  const SqliteNabiHealthReminderPreferencesRepository({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Database> get _database async {
    final db = databaseOverride ?? await DatabaseService.database;
    await NabiNotificationTables.ensureHealthReminderSchema(db);
    return db;
  }

  @override
  Future<NabiHealthReminderPreferences> loadOrCreate({
    required String actorKey,
    required bool legacyPushEnabled,
  }) async {
    final normalizedActor = actorKey.trim();
    if (normalizedActor.isEmpty) {
      throw const FormatException('Missing notification actor');
    }
    final db = await _database;
    final rows = await db.query(
      NabiNotificationTables.carePreferences,
      where: 'actor_key = ?',
      whereArgs: [normalizedActor],
      limit: 1,
    );
    if (rows.isNotEmpty) return _fromRow(rows.first);

    final value = NabiHealthReminderPreferences.defaults(
      actorKey: normalizedActor,
      legacyPushEnabled: legacyPushEnabled,
      now: now(),
    );
    await save(value);
    return value;
  }

  @override
  Future<void> save(NabiHealthReminderPreferences preferences) async {
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    await db.insert(
      NabiNotificationTables.carePreferences,
      {
        'actor_key': preferences.actorKey,
        'master_enabled': _bool(preferences.masterEnabled),
        'schedule_enabled': _bool(preferences.scheduleEnabled),
        'health_check_in_enabled': _bool(preferences.healthCheckInEnabled),
        'health_check_in_interval_minutes':
            preferences.healthCheckInIntervalMinutes,
        'health_check_in_start_minutes': preferences.healthCheckInStartMinutes,
        'health_check_in_end_minutes': preferences.healthCheckInEndMinutes,
        'goal_review_enabled': _bool(preferences.goalReviewEnabled),
        'goal_review_minutes': preferences.goalReviewMinutes,
        'profile_review_enabled': _bool(preferences.profileReviewEnabled),
        'profile_review_interval_days': preferences.profileReviewIntervalDays,
        'profile_review_minutes': preferences.profileReviewMinutes,
        'water_reminder_enabled': _bool(preferences.waterReminderEnabled),
        'water_reminder_interval_minutes': preferences.waterReminderIntervalMinutes,
        'water_reminder_start_minutes': preferences.waterReminderStartMinutes,
        'water_reminder_end_minutes': preferences.waterReminderEndMinutes,
        'voice_enabled': _bool(preferences.voiceEnabled),
        'use_personal_quiet_hours': _bool(preferences.usePersonalQuietHours),
        'fallback_quiet_start_minutes': preferences.fallbackQuietStartMinutes,
        'fallback_quiet_end_minutes': preferences.fallbackQuietEndMinutes,
        'last_goal_review_period': preferences.lastGoalReviewPeriod,
        'last_profile_reviewed_at':
            preferences.lastProfileReviewedAt?.toUtc().toIso8601String(),
        'last_health_check_in_at':
            preferences.lastHealthCheckInAt?.toUtc().toIso8601String(),
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markHealthCheckIn(String actorKey, DateTime at) {
    return _markReviewValue(
      actorKey: actorKey,
      column: 'last_health_check_in_at',
      value: at.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> markGoalReview(String actorKey, String periodKey) {
    return _markReviewValue(
      actorKey: actorKey,
      column: 'last_goal_review_period',
      value: periodKey,
    );
  }

  @override
  Future<void> markProfileReview(String actorKey, DateTime at) {
    return _markReviewValue(
      actorKey: actorKey,
      column: 'last_profile_reviewed_at',
      value: at.toUtc().toIso8601String(),
    );
  }

  Future<void> _markReviewValue({
    required String actorKey,
    required String column,
    required String value,
  }) async {
    final db = await _database;
    await db.update(
      NabiNotificationTables.carePreferences,
      {column: value, 'updated_at': now().toUtc().toIso8601String()},
      where: 'actor_key = ?',
      whereArgs: [actorKey],
    );
  }

  NabiHealthReminderPreferences _fromRow(Map<String, Object?> row) {
    return NabiHealthReminderPreferences(
      actorKey: row['actor_key']?.toString() ?? '',
      masterEnabled: _readBool(row['master_enabled']),
      scheduleEnabled: _readBool(row['schedule_enabled'], fallback: true),
      healthCheckInEnabled: _readBool(row['health_check_in_enabled']),
      healthCheckInIntervalMinutes:
          _readInt(row['health_check_in_interval_minutes'], 60),
      healthCheckInStartMinutes:
          _readInt(row['health_check_in_start_minutes'], 480),
      healthCheckInEndMinutes:
          _readInt(row['health_check_in_end_minutes'], 1260),
      goalReviewEnabled: _readBool(row['goal_review_enabled']),
      goalReviewMinutes: _readInt(row['goal_review_minutes'], 540),
      profileReviewEnabled: _readBool(row['profile_review_enabled']),
      profileReviewIntervalDays: _readInt(row['profile_review_interval_days'], 30),
      profileReviewMinutes: _readInt(row['profile_review_minutes'], 540),
      waterReminderEnabled: _readBool(row['water_reminder_enabled']),
      waterReminderIntervalMinutes:
          _readInt(row['water_reminder_interval_minutes'], 120),
      waterReminderStartMinutes:
          _readInt(row['water_reminder_start_minutes'], 480),
      waterReminderEndMinutes:
          _readInt(row['water_reminder_end_minutes'], 1200),
      voiceEnabled: _readBool(row['voice_enabled']),
      usePersonalQuietHours:
          _readBool(row['use_personal_quiet_hours'], fallback: true),
      fallbackQuietStartMinutes:
          _readInt(row['fallback_quiet_start_minutes'], 1260),
      fallbackQuietEndMinutes:
          _readInt(row['fallback_quiet_end_minutes'], 420),
      lastGoalReviewPeriod: _nonEmpty(row['last_goal_review_period']),
      lastProfileReviewedAt: _date(row['last_profile_reviewed_at']),
      lastHealthCheckInAt: _date(row['last_health_check_in_at']),
      updatedAt: _date(row['updated_at']) ?? now(),
    );
  }

  int _bool(bool value) => value ? 1 : 0;

  bool _readBool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }

  int _readInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime? _date(Object? value) {
    final text = _nonEmpty(value);
    return text == null ? null : DateTime.tryParse(text)?.toLocal();
  }

  String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class SqliteNabiHealthReminderScheduleRepository
    implements NabiHealthReminderScheduleRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  const SqliteNabiHealthReminderScheduleRepository({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  static final Random _random = Random.secure();

  Future<Database> get _database async {
    final db = databaseOverride ?? await DatabaseService.database;
    await NabiNotificationTables.ensureHealthReminderSchema(db);
    return db;
  }

  @override
  Future<List<NabiScheduledHealthReminderRecord>> loadPendingForActor(
    String actorKey,
  ) {
    return _loadPending(where: 'actor_key = ?', whereArgs: [actorKey]);
  }

  @override
  Future<List<NabiScheduledHealthReminderRecord>> loadPendingForOtherActors(
    String actorKey,
  ) {
    return _loadPending(where: 'actor_key <> ?', whereArgs: [actorKey]);
  }

  Future<List<NabiScheduledHealthReminderRecord>> _loadPending({
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await _database;
    final rows = await db.query(
      NabiNotificationTables.careSchedules,
      where: '$where AND status = ?',
      whereArgs: [...whereArgs, 'queued'],
      orderBy: 'scheduled_at ASC',
    );
    return rows
        .map(_recordFromRow)
        .whereType<NabiScheduledHealthReminderRecord>()
        .toList(growable: false);
  }

  @override
  Future<NabiScheduledHealthReminderRecord> savePlanned({
    required String actorKey,
    required NabiPlannedHealthReminder reminder,
    required int nativeNotificationId,
  }) async {
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    final existing = await db.query(
      NabiNotificationTables.careSchedules,
      where: 'actor_key = ? AND category = ? AND source_event_id = ?',
      whereArgs: [actorKey, reminder.category.payloadValue, reminder.sourceEventId],
      limit: 1,
    );
    final occurrenceId = existing.isEmpty
        ? _uuidV4()
        : existing.first['occurrence_id']?.toString() ?? _uuidV4();
    await db.insert(
      NabiNotificationTables.careSchedules,
      {
        'occurrence_id': occurrenceId,
        'actor_key': actorKey,
        'category': reminder.category.payloadValue,
        'source_event_id': reminder.sourceEventId,
        'native_notification_id': nativeNotificationId,
        'scheduled_at': reminder.scheduledAt.toUtc().toIso8601String(),
        'status': 'queued',
        'deferred_until': null,
        'created_at': existing.isEmpty
            ? timestamp
            : existing.first['created_at']?.toString() ?? timestamp,
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return NabiScheduledHealthReminderRecord(
      occurrenceId: occurrenceId,
      actorKey: actorKey,
      category: reminder.category,
      nativeNotificationId: nativeNotificationId,
      scheduledAt: reminder.scheduledAt,
    );
  }

  @override
  Future<void> markCancelled(String occurrenceId) {
    return _mark(
      occurrenceId,
      values: {'status': 'cancelled', 'updated_at': _timestamp()},
    );
  }

  @override
  Future<void> markOpened(String occurrenceId) {
    final timestamp = _timestamp();
    return _mark(
      occurrenceId,
      values: {
        'status': 'opened',
        'updated_at': timestamp,
      },
    );
  }

  @override
  Future<void> markDeferred({
    required String occurrenceId,
    required DateTime deferredUntil,
  }) {
    final timestamp = _timestamp();
    return _mark(
      occurrenceId,
      values: {
        'status': 'deferred',
        'deferred_until': deferredUntil.toUtc().toIso8601String(),
        'updated_at': timestamp,
      },
    );
  }

  Future<void> _mark(
    String occurrenceId, {
    required Map<String, Object?> values,
  }) async {
    final db = await _database;
    await db.update(
      NabiNotificationTables.careSchedules,
      values,
      where: 'occurrence_id = ?',
      whereArgs: [occurrenceId],
    );
  }

  @override
  Future<DateTime?> loadHealthProfileUpdatedAt(String actorKey) async {
    final db = await _database;
    final rows = await db.query(
      'health_profiles',
      columns: ['updated_at', 'created_at'],
      where: 'user_id = ?',
      whereArgs: [actorKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.first['updated_at'] ?? rows.first['created_at'];
    return DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  }

  @override
  Future<bool> isWaterGoalCompletedToday({
    required String actorKey,
    required DateTime now,
  }) async {
    final db = await _database;
    final rows = await db.query(
      'daily_health_tasks',
      columns: ['current_value', 'target_value', 'is_completed'],
      where: 'user_id = ? AND task_date = ? AND lower(task_code) LIKE ?',
      whereArgs: [actorKey, _dateKey(now), '%water%'],
    );
    for (final row in rows) {
      final completed = _readBool(row['is_completed']);
      final current = _readDouble(row['current_value']);
      final target = _readDouble(row['target_value']);
      if (completed || (target > 0 && current >= target)) return true;
    }
    return false;
  }

  @override
  Future<NabiQuietHours?> loadPersonalQuietHours({
    required String actorKey,
    required DateTime now,
  }) async {
    final db = await _database;
    final rows = await db.query(
      'survey_answers',
      columns: ['answer_value'],
      where: 'user_id = ? AND question_code = ?',
      whereArgs: [actorKey, DailyRoutinePreferences.questionCode],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['answer_value']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final routine = DailyRoutinePreferences.fromJson(
        Map<String, Object?>.from(decoded),
      );
      final template = routine.templateFor(now);
      final sleep = _minutes(template.sleepTime);
      final wake = _minutes(template.wakeTime);
      if (sleep == null || wake == null) return null;
      return NabiQuietHours(startMinutes: sleep, endMinutes: wake);
    } catch (_) {
      return null;
    }
  }

  NabiScheduledHealthReminderRecord? _recordFromRow(
    Map<String, Object?> row,
  ) {
    final category = nabiHealthReminderCategoryFromValue(
      row['category']?.toString() ?? '',
    );
    final nativeId = _readInt(row['native_notification_id']);
    final scheduledAt = DateTime.tryParse(row['scheduled_at']?.toString() ?? '');
    if (category == null || nativeId == null || scheduledAt == null) return null;
    return NabiScheduledHealthReminderRecord(
      occurrenceId: row['occurrence_id']?.toString() ?? '',
      actorKey: row['actor_key']?.toString() ?? '',
      category: category,
      nativeNotificationId: nativeId,
      scheduledAt: scheduledAt.toLocal(),
    );
  }

  String _timestamp() => now().toUtc().toIso8601String();

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }

  double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
