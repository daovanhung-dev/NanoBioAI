import 'package:sqflite/sqflite.dart';

import '../models/health_score_ledger_model.dart';
import '../tables/health_score_ledgers_table.dart';

class HealthScoreLedgersDao {
  final Database db;

  const HealthScoreLedgersDao(this.db);

  Future<void> upsert(HealthScoreLedgerModel model) async {
    await db.insert(
      HealthScoreLedgersTable.tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<HealthScoreLedgerModel?> getByPeriod({
    required String userId,
    required String periodStart,
    required String periodEnd,
    required String formulaVersion,
  }) async {
    final rows = await db.query(
      HealthScoreLedgersTable.tableName,
      where:
          'user_id = ? AND period_start = ? AND period_end = ? AND formula_version = ?',
      whereArgs: [userId, periodStart, periodEnd, formulaVersion],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HealthScoreLedgerModel.fromMap(rows.first);
  }
}
