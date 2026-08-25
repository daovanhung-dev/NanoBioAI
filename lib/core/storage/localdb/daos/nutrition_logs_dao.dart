import 'package:sqflite/sqflite.dart';

import '../models/nutrition_log_model.dart';

class NutritionLogsDao {
  static const tableName = 'nutrition_logs';
  static const detailsTableName = 'nutrition_log_details';

  final Database db;
  NutritionLogsDao(this.db);

  Future<void> insert(NutritionLogModel model) async {
    await db.transaction((txn) async {
      await txn.insert(
        tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _upsertDetails(txn, model);
    });
  }

  Future<void> insertMany(List<NutritionLogModel> models) async {
    if (models.isEmpty) return;
    await db.transaction((txn) async {
      for (final model in models) {
        await txn.insert(
          tableName,
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _upsertDetails(txn, model);
      }
    });
  }

  Future<List<NutritionLogModel>> getAll() async {
    return _queryJoined(orderBy: defaultOrderBy);
  }

  Future<NutritionLogModel?> getById(String id) async {
    final rows = await _queryJoined(
      where: 'l.id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<NutritionLogModel>> getByUserId(String userId) async {
    return _queryJoined(
      where: 'l.user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
    );
  }

  Future<NutritionLogModel?> getLatestByUserId(String userId) async {
    final rows = await _queryJoined(
      where: 'l.user_id = ?',
      whereArgs: [userId],
      orderBy: defaultOrderBy,
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<NutritionLogModel>> getByUserAndDate({
    required String userId,
    required String date,
  }) async {
    return _queryJoined(
      where:
          "l.user_id = ? AND (l.eaten_at = ? OR substr(l.eaten_at, 1, 10) = ?)",
      whereArgs: [userId, date, date],
      orderBy: defaultOrderBy,
    );
  }

  Future<List<NutritionLogModel>> getByUserAndDateRange({
    required String userId,
    required String fromDate,
    required String toDate,
  }) async {
    return _queryJoined(
      where:
          "l.user_id = ? AND substr(l.eaten_at, 1, 10) BETWEEN ? AND ?",
      whereArgs: [userId, fromDate, toDate],
      orderBy: defaultOrderBy,
    );
  }

  Future<void> update(NutritionLogModel model) async {
    await db.transaction((txn) async {
      await txn.update(
        tableName,
        model.toMap(),
        where: 'id = ?',
        whereArgs: [model.id],
      );
      await _upsertDetails(txn, model);
    });
  }

  Future<void> delete(String id) async {
    await db.transaction((txn) async {
      if (await _detailsTableExists(txn)) {
        await txn.delete(
          detailsTableName,
          where: 'nutrition_log_id = ?',
          whereArgs: [id],
        );
      }
      await txn.delete(tableName, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteByUserId(String userId) async {
    await db.transaction((txn) async {
      if (await _detailsTableExists(txn)) {
        await txn.delete(
          detailsTableName,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }
      await txn.delete(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  String get defaultOrderBy => 'l.eaten_at DESC';

  Future<void> _upsertDetails(
    DatabaseExecutor executor,
    NutritionLogModel model,
  ) async {
    if (!model.hasRichNutritionDetails ||
        !await _detailsTableExists(executor)) {
      return;
    }
    final existing = await executor.query(
      detailsTableName,
      columns: const ['created_at'],
      where: 'nutrition_log_id = ?',
      whereArgs: [model.id],
      limit: 1,
    );
    final existingCreatedAt = existing.isEmpty
        ? null
        : existing.first['created_at']?.toString();
    final payload = model.toDetailsMap(fallbackCreatedAt: existingCreatedAt);
    if (payload == null) return;
    await executor.insert(
      detailsTableName,
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NutritionLogModel>> _queryJoined({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    if (!await _detailsTableExists(db)) {
      final rows = await db.query(
        tableName,
        where: where?.replaceAll('l.', ''),
        whereArgs: whereArgs,
        orderBy: orderBy?.replaceAll('l.', ''),
        limit: limit,
      );
      return rows.map(NutritionLogModel.fromMap).toList(growable: false);
    }

    final sql = StringBuffer('''
SELECT
  l.*,
  d.serving_quantity AS detail_serving_quantity,
  d.serving_unit AS detail_serving_unit,
  d.nutrition_json AS detail_nutrition_json,
  d.nutrition_source AS detail_nutrition_source,
  d.nutrition_confidence AS detail_nutrition_confidence,
  d.notes AS detail_notes,
  d.created_at AS detail_created_at,
  d.updated_at AS detail_updated_at
FROM $tableName l
LEFT JOIN $detailsTableName d ON d.nutrition_log_id = l.id
''');
    if (where != null && where.trim().isNotEmpty) {
      sql.write(' WHERE $where');
    }
    if (orderBy != null && orderBy.trim().isNotEmpty) {
      sql.write(' ORDER BY $orderBy');
    }
    if (limit != null) sql.write(' LIMIT $limit');

    final rows = await db.rawQuery(sql.toString(), whereArgs);
    return rows.map(NutritionLogModel.fromMap).toList(growable: false);
  }

  Future<bool> _detailsTableExists(DatabaseExecutor executor) async {
    final rows = await executor.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [detailsTableName],
    );
    return rows.isNotEmpty;
  }
}
