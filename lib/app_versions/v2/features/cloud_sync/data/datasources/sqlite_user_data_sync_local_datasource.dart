import 'dart:convert';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_runtime_state.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_staging_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_completion_proofs_table.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/user_data_snapshot.dart';
import 'meal_plan_nutrition_sync_columns.dart';
import 'user_data_sync_datasource_contracts.dart';
import 'user_data_sync_tables.dart';

class SqliteUserDataSyncLocalDatasource implements UserDataSyncLocalDatasource {
  final Database? databaseOverride;

  const SqliteUserDataSyncLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  @override
  Future<UserDataSnapshot?> readSnapshot(String userId) async {
    final db = await _db();
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (users.isEmpty) return null;

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in UserDataSyncTables.localUserOwnedTables) {
      final rows = await db.query(
        table,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      tables[table] = rows.map(_copyRow).toList(growable: false);
    }

    return UserDataSnapshot(user: _copyRow(users.first), tables: tables);
  }

  @override
  Future<void> replaceFromCloud({
    required String userId,
    required UserDataSnapshot snapshot,
    String? removeLocalUserId,
  }) async {
    if (!snapshot.hasUser) return;

    final db = await _db();
    await db.transaction((txn) async {
      final pendingCount =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM ${SyncOutboxSchema.outboxTable} '
              'WHERE user_id = ?',
              [userId],
            ),
          ) ??
          0;
      if (pendingCount > 0) {
        throw LocalSyncPendingWriteException(pendingCount);
      }

      // An absent key means the remote omitted that table; an explicit empty
      // list still means cloud has no rows and should clear the local table.
      final preservedMissingCloudTables =
          <String, List<Map<String, Object?>>>{};
      for (final table in UserDataSyncTables.cloudPullTables) {
        if (snapshot.tables.containsKey(table) ||
            !await _tableExists(txn, table)) {
          continue;
        }
        preservedMissingCloudTables[table] = await txn.query(
          table,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      await SyncRuntimeState.setApplyingCloud(txn, true);
      try {
        if (removeLocalUserId != null &&
            removeLocalUserId.isNotEmpty &&
            removeLocalUserId != userId) {
          if (await _tableExists(
            txn,
            ScheduleCompletionProofsTable.tableName,
          )) {
            await txn.update(
              ScheduleCompletionProofsTable.tableName,
              {'user_id': userId},
              where: 'user_id = ?',
              whereArgs: [removeLocalUserId],
            );
          }
          await _deleteRowsForUser(txn, removeLocalUserId, includeUser: true);
          await txn.delete(
            SyncOutboxSchema.outboxTable,
            where: 'user_id = ?',
            whereArgs: [removeLocalUserId],
          );
        }

        await _deleteRowsForUser(txn, userId, includeUser: false);

        final localUser = _localUserRow(snapshot.user!, userId);
        final existingUser = await txn.query(
          'users',
          columns: const ['id'],
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );
        if (existingUser.isEmpty) {
          await txn.insert('users', localUser);
        } else {
          // REPLACE deletes the old parent row before inserting its new copy.
          // That fires ON DELETE CASCADE on active generated-plan requests.
          await txn.update(
            'users',
            localUser,
            where: 'id = ?',
            whereArgs: [userId],
          );
        }

        for (final table in UserDataSyncTables.localUserOwnedTables) {
          final rows =
              snapshot.tables[table] ??
              preservedMissingCloudTables[table] ??
              const <Map<String, Object?>>[];
          for (final row in rows) {
            if (table == PersonalScheduleAiRequestsTable.tableName &&
                await _hasLocalScheduleStaging(txn, row['request_id'])) {
              // Replacing a staged request row fires its ON DELETE CASCADE,
              // which would erase the in-progress local generation chunks.
              // Keep that request's local state until generation commits.
              continue;
            }
            await txn.insert(
              table,
              _localRowFromCloud(table, row, userId),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        for (final table in SyncOutboxSchema.serverOwnedReadOnlyTables) {
          if (!await _tableExists(txn, table)) continue;
          final rows =
              snapshot.tables[table] ??
              preservedMissingCloudTables[table] ??
              const <Map<String, Object?>>[];
          for (final row in rows) {
            await txn.insert(
              table,
              _localRowFromCloud(table, row, userId),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await txn.delete(
          SyncOutboxSchema.outboxTable,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      } finally {
        await SyncRuntimeState.setApplyingCloud(txn, false);
      }
    });
  }

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return rows.isNotEmpty;
  }

  Future<void> _deleteRowsForUser(
    Transaction txn,
    String userId, {
    required bool includeUser,
  }) async {
    for (final table in UserDataSyncTables.localUserOwnedTables.reversed) {
      if (!includeUser &&
          table == PersonalScheduleAiRequestsTable.tableName &&
          await _tableExists(txn, PersonalScheduleAiStagingTable.tableName)) {
        await txn.rawDelete(
          'DELETE FROM ${PersonalScheduleAiRequestsTable.tableName} '
          'WHERE user_id = ? AND request_id NOT IN ('
          'SELECT request_id FROM ${PersonalScheduleAiStagingTable.tableName}'
          ')',
          [userId],
        );
        continue;
      }
      await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
    }
    for (final table in SyncOutboxSchema.serverOwnedReadOnlyTables) {
      if (!await _tableExists(txn, table)) continue;
      await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
    }

    if (includeUser) {
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    }
  }

  Future<bool> _hasLocalScheduleStaging(
    DatabaseExecutor db,
    Object? requestId,
  ) async {
    final normalized = requestId?.toString().trim();
    if (normalized == null || normalized.isEmpty) return false;
    if (!await _tableExists(db, PersonalScheduleAiStagingTable.tableName)) {
      return false;
    }
    final rows = await db.query(
      PersonalScheduleAiStagingTable.tableName,
      columns: const ['request_id'],
      where: 'request_id = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Map<String, Object?> _localUserRow(
    Map<String, Object?> cloudRow,
    String userId,
  ) {
    final row = _filterColumns(
      table: 'users',
      source: cloudRow,
      targetUserId: userId,
    );

    row['id'] = userId;
    row['subscription_tier'] =
        _readNonEmptyString(row['subscription_tier']) ?? 'free';
    return row;
  }

  Map<String, Object?> _localRowFromCloud(
    String table,
    Map<String, Object?> cloudRow,
    String userId,
  ) {
    final row = _filterColumns(
      table: table,
      source: cloudRow,
      targetUserId: userId,
    );

    row['user_id'] = userId;
    return row;
  }

  Map<String, Object?> _filterColumns({
    required String table,
    required Map<String, Object?> source,
    required String targetUserId,
  }) {
    final baseColumns = UserDataSyncTables.localColumnsByTable[table];
    if (baseColumns == null) {
      throw StateError('Unsupported local sync table: $table');
    }
    final allowedColumns = table == 'meal_plans'
        ? <String>{...baseColumns, ...mealPlanNutritionSyncColumns}
        : baseColumns;

    final row = <String, Object?>{};
    for (final entry in source.entries) {
      final column = entry.key;
      if (!allowedColumns.contains(column)) continue;
      if (column == 'subject_id') continue;
      if (column == 'user_id') {
        row[column] = targetUserId;
        continue;
      }

      row[column] = _localValue(column, entry.value);
    }

    return row;
  }

  Object? _localValue(String column, Object? value) {
    if (value == null) return null;
    if (UserDataSyncTables.booleanColumns.contains(column)) {
      return _boolToInt(value);
    }
    if (column == 'payload' || column == 'program_json') {
      if (value is String) return value;
      return jsonEncode(value);
    }
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  int _boolToInt(Object value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value == 0 ? 0 : 1;

    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' ? 1 : 0;
  }

  String? _readNonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  Map<String, Object?> _copyRow(Map<String, Object?> row) {
    return Map<String, Object?>.from(row);
  }
}
