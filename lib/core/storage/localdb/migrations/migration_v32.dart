import 'package:sqflite/sqflite.dart';

import '../tables/wellness_rewards_cache_tables.dart';

class MigrationV32 {
  const MigrationV32._();

  static Future<void> run(DatabaseExecutor db) async {
    await _addColumn(
      db,
      WellnessRewardOfferCacheTable.tableName,
      'reward_type',
      "TEXT NOT NULL DEFAULT 'voucher'",
    );
    await _addColumn(
      db,
      WellnessRewardOfferCacheTable.tableName,
      'stock_count',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumn(
      db,
      WellnessRewardRedemptionCacheTable.tableName,
      'reward_type',
      "TEXT NOT NULL DEFAULT 'voucher'",
    );
    await _addColumn(
      db,
      WellnessRewardRedemptionCacheTable.tableName,
      'received_at',
      'TEXT',
    );
  }

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    await db.execute(WellnessRewardOfferCacheTable.createTable);
    await db.execute(WellnessRewardRedemptionCacheTable.createTable);
    await run(db);
  }

  static Future<void> _addColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    final columns = rows.map((row) => row['name']?.toString() ?? '').toSet();
    if (columns.isNotEmpty && !columns.contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
