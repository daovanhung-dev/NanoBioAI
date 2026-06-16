import 'package:sqflite/sqflite.dart';

import '../tables/daily_health_tasks_table.dart';

class MigrationManager {
  static Future<void> runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
  }

  static Future<void> _migrateToV2(Database db) async {
    await db.execute(DailyHealthTasksTable.createTable);
    await _addColumnIfMissing(
      db,
      tableName: 'health_tracking_logs',
      columnName: 'log_date',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'health_tracking_logs',
      columnName: 'updated_at',
      definition: 'TEXT',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_health_tracking_logs_user_date '
      'ON health_tracking_logs(user_id, log_date)',
    );
  }

  static Future<void> _migrateToV3(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'meal_plans',
      columnName: 'cooking_instructions',
      definition: 'TEXT',
    );
  }

  static Future<void> _addColumnIfMissing(
    Database db, {
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $definition',
      );
    }
  }
}
