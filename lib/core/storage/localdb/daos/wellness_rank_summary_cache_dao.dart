import 'package:sqflite/sqflite.dart';

import '../tables/wellness_rank_cache_table.dart';

class WellnessRankSummaryCacheDao {
  final DatabaseExecutor db;

  const WellnessRankSummaryCacheDao(this.db);

  Future<Map<String, Object?>?> findForUser(String userId) async {
    final rows = await db.query(
      WellnessRankSummaryCacheTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<void> save(Map<String, Object?> row) async {
    await db.insert(
      WellnessRankSummaryCacheTable.tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
