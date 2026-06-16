import 'package:sqflite/sqflite.dart';

import '../tables/daily_health_tasks_table.dart';

class MigrationManager {
  static Future<void> runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 2)) {
      await _migrateToV2(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 3)) {
      await _migrateToV3(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 4)) {
      await _migrateToV4(db);
    }
  }

  static bool _shouldRunMigration(
    int oldVersion,
    int newVersion, {
    required int targetVersion,
  }) {
    return oldVersion < targetVersion && newVersion >= targetVersion;
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

  static Future<void> _migrateToV4(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'source_type',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'source_id',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'scheduled_at',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'notification_id',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'action_status',
      definition: "TEXT DEFAULT 'pending'",
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'responded_at',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'payload',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'notifications',
      columnName: 'updated_at',
      definition: 'TEXT',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_source '
      'ON notifications(source_type, source_id, action_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_notification_id '
      'ON notifications(notification_id)',
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
