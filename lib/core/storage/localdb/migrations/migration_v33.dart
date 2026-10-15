import 'package:sqflite/sqflite.dart';

import '../tables/wellness_rank_cache_table.dart';

class MigrationV33 {
  const MigrationV33._();

  static Future<void> run(DatabaseExecutor db) async {
    await db.execute(WellnessRankSummaryCacheTable.createTable);
  }

  static Future<void> ensureSchema(DatabaseExecutor db) => run(db);
}
