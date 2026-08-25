import 'dart:convert';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_models.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite adapter for NaBi Care.
///
/// The adapter intentionally reuses the current database schema. Optional
/// health modules are discovered at runtime so an older local database does
/// not crash NaBi Care merely because a newer health table is absent.
class SqliteNabiCareRepository implements NabiCareRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  SqliteNabiCareRepository({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Database> get _database async =>
      databaseOverride ?? DatabaseService.database;

  static const _contextTables = <String>[
    'health_profiles',
    'health_conditions',
    'health_symptoms',
    'health_goals',
    'lifestyle_habits',
    'health_tracking_logs',
    'nutrition_profiles',
    'nutrition_logs',
    'nutrition_goals',
    'medication_records',
    'lab_results',
    'daily_health_tasks',
    'lifestyle_schedule_items',
  ];

  @override
  Future<NabiCareRawContext> loadRawContext({String? subjectId}) async {
    final db = await _database;
    final actorKey = await _resolveActorKey(db, subjectId);
    final rowsByTable = <String, List<Map<String, Object?>>>{};

    final users = await _safeScopedQuery(
      db,
      table: 'users',
      actorKey: actorKey,
      maxRows: 1,
    );
    rowsByTable['users'] = users;

    for (final table in _contextTables) {
      rowsByTable[table] = await _safeScopedQuery(
        db,
        table: table,
        actorKey: actorKey,
        maxRows: _rowLimit(table),
      );
    }

    return NabiCareRawContext(
      actorKey: actorKey,
      rowsByTable: rowsByTable,
    );
  }

  @override
  Future<NabiCareCachedAnalysis?> loadLatestCachedAnalysis(
    String actorKey,
  ) async {
    final db = await _database;
    if (!await _tableExists(db, 'ai_insights')) return null;

    final rows = await db.query(
      'ai_insights',
      columns: const ['content', 'created_at'],
      where: 'user_id = ? AND insight_type = ?',
      whereArgs: [actorKey, 'nabi_care'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    try {
      final payload = jsonDecode(rows.first['content']?.toString() ?? '');
      if (payload is! Map) return null;
      final map = Map<String, Object?>.from(payload);
      final fingerprint = map['fingerprint']?.toString().trim();
      final analysisRaw = map['analysis'];
      if (fingerprint == null ||
          fingerprint.isEmpty ||
          analysisRaw is! Map) {
        return null;
      }
      final createdAt = DateTime.tryParse(
            rows.first['created_at']?.toString() ?? '',
          ) ??
          now();
      return NabiCareCachedAnalysis(
        fingerprint: fingerprint,
        analysis: NabiCareAnalysis.fromJson(
          Map<String, Object?>.from(analysisRaw),
        ),
        createdAt: createdAt,
      );
    } catch (_) {
      // Corrupt legacy cache should never block a fresh care analysis.
      return null;
    }
  }

  @override
  Future<void> saveAnalysis({
    required String actorKey,
    required String fingerprint,
    required NabiCareAnalysis analysis,
  }) async {
    final db = await _database;
    if (!await _tableExists(db, 'ai_insights')) return;
    if (!await _actorExists(db, actorKey)) return;

    final timestamp = now().toUtc().toIso8601String();
    final analysisId = _id('care', fingerprint);
    final payload = jsonEncode({
      'schema_version': 1,
      'fingerprint': fingerprint,
      'analysis': analysis.toJson(),
    });

    await db.insert(
      'ai_insights',
      {
        'id': analysisId,
        'user_id': actorKey,
        'insight_type': 'nabi_care',
        'title': 'NaBi Care',
        'content': payload,
        'risk_level': analysis.overallStatus.name,
        'created_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!await _tableExists(db, 'ai_recommendations')) return;
    for (var index = 0; index < analysis.actions.length; index++) {
      final action = analysis.actions[index];
      await db.insert(
        'ai_recommendations',
        {
          'id': '${analysisId}_action_$index',
          'user_id': actorKey,
          'recommendation_type': 'nabi_care_action',
          'title': action.title,
          'description': jsonEncode({
            'fingerprint': fingerprint,
            'action': action.toJson(),
          }),
          'action_text': action.id,
          'is_read': 0,
          'created_at': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<void> saveFeedback({
    required String actorKey,
    required String fingerprint,
    required NabiCareFeedbackType feedback,
    String? actionId,
  }) async {
    final db = await _database;
    if (!await _tableExists(db, 'ai_recommendations')) return;
    if (!await _actorExists(db, actorKey)) return;

    final timestamp = now().toUtc().toIso8601String();
    await db.insert(
      'ai_recommendations',
      {
        'id': _id('feedback', '$fingerprint:${feedback.name}:${actionId ?? ''}'),
        'user_id': actorKey,
        'recommendation_type': 'nabi_care_feedback',
        'title': feedback.name,
        'description': jsonEncode({
          'fingerprint': fingerprint,
          'feedback': feedback.name,
          if (actionId != null) 'action_id': actionId,
        }),
        'action_text': actionId,
        'is_read': 1,
        'created_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> _resolveActorKey(Database db, String? subjectId) async {
    final explicit = subjectId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    if (!await _tableExists(db, 'users')) return 'guest:local';
    final columns = await _columns(db, 'users');
    final orderBy = columns.contains('updated_at')
        ? 'updated_at DESC'
        : columns.contains('created_at')
            ? 'created_at DESC'
            : null;
    final rows = await db.query(
      'users',
      columns: const ['id'],
      orderBy: orderBy,
      limit: 1,
    );
    final id = rows.isEmpty ? null : rows.first['id']?.toString().trim();
    return id == null || id.isEmpty ? 'guest:local' : id;
  }

  Future<List<Map<String, Object?>>> _safeScopedQuery(
    Database db, {
    required String table,
    required String actorKey,
    required int maxRows,
  }) async {
    if (!await _tableExists(db, table)) return const [];
    final columns = await _columns(db, table);

    String? where;
    List<Object?>? args;
    if (table == 'users' && columns.contains('id')) {
      where = 'id = ?';
      args = [actorKey];
    } else {
      final actorColumn = _actorColumn(columns);
      if (actorColumn == null) {
        // Do not read an unscoped optional table: on a FamilyPlus device that
        // could blend data belonging to another subject.
        return const [];
      }
      where = '$actorColumn = ?';
      args = [actorKey];
    }

    final orderBy = _bestOrderBy(columns);
    try {
      return await db.query(
        table,
        where: where,
        whereArgs: args,
        orderBy: orderBy,
        limit: maxRows,
      );
    } catch (_) {
      return const [];
    }
  }

  String? _actorColumn(Set<String> columns) {
    for (final name in const [
      'subject_id',
      'subject_user_id',
      'user_id',
      'member_user_id',
      'owner_user_id',
    ]) {
      if (columns.contains(name)) return name;
    }
    return null;
  }

  String? _bestOrderBy(Set<String> columns) {
    for (final name in const [
      'log_date',
      'measured_at',
      'schedule_date',
      'task_date',
      'updated_at',
      'created_at',
    ]) {
      if (columns.contains(name)) return '$name DESC';
    }
    return null;
  }

  int _rowLimit(String table) {
    return switch (table) {
      'health_tracking_logs' => 45,
      'daily_health_tasks' || 'lifestyle_schedule_items' => 120,
      'nutrition_logs' => 60,
      _ => 30,
    };
  }

  Future<bool> _actorExists(Database db, String actorKey) async {
    if (!await _tableExists(db, 'users')) return false;
    final rows = await db.query(
      'users',
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [actorKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      ['table', table],
    );
    return rows.isNotEmpty;
  }

  Future<Set<String>> _columns(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info("$table")');
    return rows
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();
  }

  String _id(String prefix, String seed) {
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'nabi_${prefix}_${now().microsecondsSinceEpoch}_${hash.toRadixString(16)}';
  }
}
