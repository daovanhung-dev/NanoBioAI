import 'dart:async';
import 'dart:convert';

import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/sqlite_user_data_sync_local_datasource.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/supabase_user_data_sync_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_tables.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef SyncMutationPusher = Future<void> Function(SyncOutboxMutation mutation);
typedef SyncSnapshotPusher =
    Future<void> Function(String userId, Database database);

class SyncOutboxMutation {
  final String id;
  final String userId;
  final String tableName;
  final String recordId;
  final String operation;
  final Map<String, Object?> payload;
  final String updatedAt;
  final int attemptCount;

  const SyncOutboxMutation({
    required this.id,
    required this.userId,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.updatedAt,
    this.attemptCount = 0,
  });
}

/// Makes SQLite user-data writes durable first, then mirrors them to Supabase.
///
/// Version 12 installs SQLite triggers for every user-owned table. A trigger
/// places a dirty marker in [sync_outbox] inside the same transaction as the
/// original write. The default drain uses one complete snapshot per user so
/// all related data is uploaded consistently and deleted records are reflected
/// as well. Network failure never rolls back the local action; it schedules a
/// retry instead.
class UserDataSyncOutbox {
  static const _tag = 'SYNC_OUTBOX';
  static const _pendingStatuses = ['pending', 'failed', 'syncing'];

  static final shared = UserDataSyncOutbox();

  final Database? databaseOverride;
  final String? Function() currentUserId;
  final DateTime Function() now;
  final SyncMutationPusher? mutationPusher;
  final SyncSnapshotPusher? snapshotPusher;
  final bool drainImmediately;

  bool _isDraining = false;

  UserDataSyncOutbox({
    this.databaseOverride,
    String? Function()? currentUserId,
    DateTime Function()? now,
    this.mutationPusher,
    this.snapshotPusher,
    this.drainImmediately = true,
  }) : currentUserId = currentUserId ?? currentSupabaseUserIdOrNull,
       now = now ?? DateTime.now;

  static Future<void> enqueueUpsertForCurrentUser({
    required String tableName,
    required String recordId,
    Database? database,
  }) {
    return shared.enqueueUpsert(
      tableName: tableName,
      recordId: recordId,
      database: database,
    );
  }

  static Future<void> tryEnqueueUpsertForCurrentUser({
    required String tableName,
    required String recordId,
    Database? database,
  }) async {
    try {
      await enqueueUpsertForCurrentUser(
        tableName: tableName,
        recordId: recordId,
        database: database,
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        _tag,
        'Skipped enqueue for $tableName/$recordId: $error',
      );
      AppLogger.error(
        _tag,
        'Failed to enqueue local mutation',
        error,
        stackTrace,
      );
    }
  }

  static Future<int> drainForCurrentUser({Database? database}) {
    return shared.drainPending(database: database);
  }

  /// Requests an immediate, non-blocking snapshot drain after a committed
  /// user-owned SQLite write. The SQLite outbox remains the source of
  /// durability: when the user is signed out or the network is unavailable,
  /// the dirty marker stays queued for the refresher/retry path.
  static void requestImmediateDrain({Database? database}) {
    unawaited(shared.drainPending(database: database));
  }

  /// Backward-compatible API for code paths that explicitly enqueue a write.
  /// Most application writes are now enqueued by SQLite triggers automatically.
  Future<void> enqueueUpsert({
    required String tableName,
    required String recordId,
    Database? database,
  }) async {
    final userId = currentUserId();
    if (userId == null || userId.isEmpty || !_isSupportedTable(tableName)) {
      return;
    }

    final db = database ?? await _db();
    final localRow = await _readLocalRow(
      db,
      userId: userId,
      tableName: tableName,
      recordId: recordId,
    );
    if (localRow == null) return;

    await _enqueue(
      db,
      userId: userId,
      tableName: tableName,
      recordId: recordId,
      operation: 'upsert',
      payload: _cloudPayload(tableName, localRow, userId, recordId),
    );

    if (drainImmediately) {
      unawaited(drainPending(database: db));
    }
  }

  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
    Database? database,
  }) async {
    final userId = currentUserId();
    if (userId == null || userId.isEmpty || !_isSupportedTable(tableName)) {
      return;
    }

    final db = database ?? await _db();
    await _enqueue(
      db,
      userId: userId,
      tableName: tableName,
      recordId: recordId,
      operation: 'delete',
      payload: const {},
    );

    if (drainImmediately) {
      unawaited(drainPending(database: db));
    }
  }


  Future<int> pendingCountForCurrentUser({Database? database}) async {
    final userId = currentUserId();
    if (userId == null || userId.isEmpty) return 0;
    final db = database ?? await _db();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${SyncOutboxSchema.outboxTable} '
      'WHERE user_id = ? AND status IN (?, ?, ?)',
      [userId, ..._pendingStatuses],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> makeRetriesDueForCurrentUser({Database? database}) async {
    final userId = currentUserId();
    if (userId == null || userId.isEmpty) return;
    final db = database ?? await _db();
    await db.update(
      SyncOutboxSchema.outboxTable,
      {'status': 'pending', 'next_retry_at': null},
      where: 'user_id = ? AND status IN (?, ?)',
      whereArgs: [userId, 'failed', 'syncing'],
    );
  }

  Future<int> drainPending({Database? database, int limit = 100}) async {
    if (_isDraining) return 0;

    final userId = currentUserId();
    if (userId == null || userId.isEmpty) return 0;

    _isDraining = true;
    try {
      final db = database ?? await _db();
      final rows = await _pendingRows(db, userId, limit);
      final mutations = rows
          .map(_mutationFromRow)
          .whereType<SyncOutboxMutation>()
          .toList();
      if (mutations.isEmpty) return 0;

      if (mutationPusher != null) {
        return _drainMutationsIndividually(db, mutations);
      }

      try {
        await _pushFullSnapshot(userId, db);
        var drained = 0;
        for (final mutation in mutations) {
          // A write that happened while the RPC was in-flight has a newer
          // updated_at and must remain queued for the next complete snapshot.
          drained += await db.delete(
            SyncOutboxSchema.outboxTable,
            where: 'id = ? AND updated_at = ?',
            whereArgs: [mutation.id, mutation.updatedAt],
          );
        }
        return drained;
      } catch (error, stackTrace) {
        for (final mutation in mutations) {
          await _markFailed(db, mutation, error);
        }
        AppLogger.warning(_tag, 'Full snapshot retry queued: $error');
        AppLogger.error(
          _tag,
          'Failed to push full local snapshot',
          error,
          stackTrace,
        );
        return 0;
      }
    } finally {
      _isDraining = false;
    }
  }

  Future<List<Map<String, Object?>>> _pendingRows(
    Database db,
    String userId,
    int limit,
  ) {
    final dueAt = now().toUtc().toIso8601String();
    return db.query(
      SyncOutboxSchema.outboxTable,
      where:
          'user_id = ? AND status IN (?, ?, ?) '
          'AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: [userId, ..._pendingStatuses, dueAt],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<int> _drainMutationsIndividually(
    Database db,
    List<SyncOutboxMutation> mutations,
  ) async {
    var drained = 0;
    for (final mutation in mutations) {
      final syncingUpdatedAt = now().toUtc().toIso8601String();
      final claimed = await db.update(
        SyncOutboxSchema.outboxTable,
        {'status': 'syncing', 'updated_at': syncingUpdatedAt},
        // Do not claim a mutation that has been replaced by a newer local
        // write after this drain read it.
        where: 'id = ? AND updated_at = ?',
        whereArgs: [mutation.id, mutation.updatedAt],
      );
      if (claimed == 0) continue;

      final syncingMutation = SyncOutboxMutation(
        id: mutation.id,
        userId: mutation.userId,
        tableName: mutation.tableName,
        recordId: mutation.recordId,
        operation: mutation.operation,
        payload: mutation.payload,
        updatedAt: syncingUpdatedAt,
        attemptCount: mutation.attemptCount,
      );

      try {
        await mutationPusher!(syncingMutation);
        // A local write may have occurred while the remote operation was in
        // flight. Delete only the exact version acknowledged by the pusher.
        final deleted = await db.delete(
          SyncOutboxSchema.outboxTable,
          where: 'id = ? AND updated_at = ?',
          whereArgs: [syncingMutation.id, syncingMutation.updatedAt],
        );
        if (deleted > 0) drained++;
      } catch (error, stackTrace) {
        await _markFailed(db, syncingMutation, error);
        AppLogger.warning(_tag, 'Mutation retry queued: $error');
        AppLogger.error(
          _tag,
          'Failed to drain ${syncingMutation.tableName}/${syncingMutation.recordId}',
          error,
          stackTrace,
        );
      }
    }
    return drained;
  }

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<void> _pushFullSnapshot(String userId, Database db) async {
    final pusher = snapshotPusher;
    if (pusher != null) {
      await pusher(userId, db);
      return;
    }

    final remote = const SupabaseUserDataSyncRemoteDatasource();
    if (remote.currentUserId != userId) {
      throw const AuthException(
        'Cloud sync session does not match local data.',
      );
    }

    final snapshot = await SqliteUserDataSyncLocalDatasource(
      databaseOverride: db,
    ).readSnapshot(userId);
    if (snapshot == null || !snapshot.hasUser) {
      // Never acknowledge and delete dirty markers unless the exact local
      // snapshot that produced them can be reconstructed. Keeping the outbox
      // row allows a later repair/retry instead of silently losing a change.
      throw StateError('Local user snapshot is unavailable for cloud sync.');
    }

    await remote.replaceCloudWithLocalSnapshot(snapshot, userId);
  }

  Future<Map<String, Object?>?> _readLocalRow(
    Database db, {
    required String userId,
    required String tableName,
    required String recordId,
  }) async {
    if (tableName == 'users') {
      final rows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
    }

    final primaryKey = tableName == 'personal_schedule_ai_requests'
        ? 'request_id'
        : 'id';
    final rows = await db.query(
      tableName,
      where: '$primaryKey = ? AND user_id = ?',
      whereArgs: [recordId, userId],
      limit: 1,
    );

    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<void> _enqueue(
    Database db, {
    required String userId,
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    final timestamp = now().toUtc().toIso8601String();
    final id = '$userId:$tableName:$recordId:$operation';

    await db.insert(SyncOutboxSchema.outboxTable, {
      'id': id,
      'user_id': userId,
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'attempt_count': 0,
      'last_error': null,
      'next_retry_at': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _markFailed(
    Database db,
    SyncOutboxMutation mutation,
    Object error,
  ) async {
    final attempts = mutation.attemptCount + 1;
    final delayMinutes = attempts < 5 ? attempts * 2 : 15;
    final timestamp = now().toUtc();

    await db.update(
      SyncOutboxSchema.outboxTable,
      {
        'status': 'failed',
        'attempt_count': attempts,
        'last_error': 'Không thể đồng bộ lúc này. Dữ liệu vẫn được giữ trên thiết bị.',
        'next_retry_at': timestamp
            .add(Duration(minutes: delayMinutes))
            .toIso8601String(),
        'updated_at': timestamp.toIso8601String(),
      },
      // Do not turn a newer local write into a delayed retry when an older
      // in-flight attempt fails.
      where: 'id = ? AND updated_at = ?',
      whereArgs: [mutation.id, mutation.updatedAt],
    );
  }

  SyncOutboxMutation? _mutationFromRow(Map<String, Object?> row) {
    final id = _readString(row['id']);
    final userId = _readString(row['user_id']);
    final tableName = _readString(row['table_name']);
    final recordId = _readString(row['record_id']);
    final operation = _readString(row['operation']);
    final updatedAt = _readString(row['updated_at']);
    if (id == null ||
        userId == null ||
        tableName == null ||
        recordId == null ||
        operation == null ||
        updatedAt == null) {
      return null;
    }

    return SyncOutboxMutation(
      id: id,
      userId: userId,
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      payload: _decodePayload(row['payload']),
      updatedAt: updatedAt,
      attemptCount: _readInt(row['attempt_count']),
    );
  }

  Map<String, Object?> _cloudPayload(
    String tableName,
    Map<String, Object?> source,
    String userId,
    String recordId,
  ) {
    final allowedColumns = UserDataSyncTables.cloudColumnsByTable[tableName];
    if (allowedColumns == null) return const {};

    final row = <String, Object?>{};
    for (final entry in source.entries) {
      final column = entry.key;
      if (!allowedColumns.contains(column)) continue;
      if (column == 'subject_id') continue;
      if (column == 'user_id') {
        row[column] = userId;
        continue;
      }
      if (column == 'id' || column == 'request_id') {
        row[column] = recordId;
        continue;
      }
      row[column] = _cloudValue(column, entry.value);
    }
    return row;
  }

  Object? _cloudValue(String column, Object? value) {
    if (value == null) return null;
    if (UserDataSyncTables.booleanColumns.contains(column)) {
      return _asBool(value);
    }
    if (column == 'payload') {
      return _decodeAnyJson(value);
    }
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  Map<String, Object?> _decodePayload(Object? value) {
    if (value is! String || value.trim().isEmpty) return const {};
    final decoded = jsonDecode(value);
    if (decoded is! Map) return const {};
    return decoded.map((key, item) => MapEntry(key.toString(), item));
  }

  Object? _decodeAnyJson(Object value) {
    if (value is! String) return value;
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  bool _isSupportedTable(String tableName) {
    return tableName == 'users' ||
        UserDataSyncTables.localUserOwnedTables.contains(tableName);
  }

  String? _readString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _asBool(Object value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }
}
