import 'package:sqflite/sqflite.dart';

import '../tables/daily_health_tasks_table.dart';
import '../tables/exercise_catalog_table.dart';
import '../tables/health_score_ledgers_table.dart';
import '../tables/lifestyle_schedule_items_table.dart';
import '../tables/meal_catalog_table.dart';
import '../tables/personal_schedule_ai_requests_table.dart';
import '../tables/schedule_task_catalog_table.dart';
import '../tables/wellness_point_ledgers_table.dart';
import '../seeders/ai_catalog_seeder.dart';
import '../sync/sync_outbox_schema.dart';

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
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 5)) {
      await _migrateToV5(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 6)) {
      await _migrateToV6(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 7)) {
      await _migrateToV7(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 8)) {
      await _migrateToV8(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 9)) {
      await _migrateToV9(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 10)) {
      await _migrateToV10(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 11)) {
      await _migrateToV11(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 12)) {
      await _migrateToV12(db);
    }
    if (_shouldRunMigration(oldVersion, newVersion, targetVersion: 13)) {
      await _migrateToV13(db);
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

  static Future<void> _migrateToV5(Database db) async {
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createDateIndex);
    await db.execute(LifestyleScheduleItemsTable.createSourceIndex);
  }

  static Future<void> _migrateToV6(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'meal_plans',
      columnName: 'start_time',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'meal_plans',
      columnName: 'end_time',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'health_tracking_logs',
      columnName: 'daily_score',
      definition: 'INTEGER',
    );
  }

  static Future<void> _migrateToV7(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'health_tracking_logs',
      columnName: 'heart_rate_bpm',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'health_tracking_logs',
      columnName: 'oxygen_saturation',
      definition: 'REAL',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'subscription_tier',
      definition: "TEXT DEFAULT 'free'",
    );
  }

  static Future<void> _migrateToV8(Database db) async {
    await db.execute(MealCatalogTable.createTable);
    await db.execute(MealCatalogTable.createTypeIndex);
    await db.execute(ExerciseCatalogTable.createTable);
    await db.execute(ExerciseCatalogTable.createCategoryIndex);
    await db.execute(ScheduleTaskCatalogTable.createTable);
    await db.execute(ScheduleTaskCatalogTable.createCategoryIndex);
    await AiCatalogSeeder.seed(db);
  }

  static Future<void> _migrateToV9(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'product_access_status',
      definition: "TEXT DEFAULT 'guest'",
    );
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'sale_status',
      definition: "TEXT DEFAULT 'none'",
    );
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'onboarding_status',
      definition: "TEXT DEFAULT 'not_started'",
    );
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'onboarding_completed_at',
      definition: 'TEXT',
    );
    await SyncOutboxSchema.create(db);
  }

  static Future<void> _migrateToV10(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'guest_initial_plan_used',
      definition: 'INTEGER DEFAULT 0',
    );
    await db.execute(PersonalScheduleAiRequestsTable.createTable);
    await db.execute(PersonalScheduleAiRequestsTable.createUserModeIndex);
  }

  static Future<void> _migrateToV11(Database db) async {
    for (final table in SyncOutboxSchema.userOwnedTables) {
      await _backfillMissingSyncId(db, table);
    }
    await SyncOutboxSchema.create(db);
  }

  /// v12 repairs legacy user-owned rows that were created without an `id`.
  /// Those rows bypassed the old outbox triggers (`NEW.id IS NOT NULL`) and
  /// could never be included in a Supabase snapshot. Recreate the trigger set
  /// after backfill so future inserts are normalized before outbox processing.
  static Future<void> _migrateToV12(Database db) async {
    await SyncOutboxSchema.create(db);
    for (final table in SyncOutboxSchema.userOwnedTables) {
      await _backfillMissingSyncId(db, table);
    }
    await _backfillPersonalScheduleAiRequestSync(db);
    await SyncOutboxSchema.recreateTriggers(db);
  }

  static Future<void> _migrateToV13(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'lifestyle_schedule_items',
      columnName: 'completion_proof_path',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'lifestyle_schedule_items',
      columnName: 'completion_proof_captured_at',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'lifestyle_schedule_items',
      columnName: 'completed_at',
      definition: 'TEXT',
    );

    await db.execute(HealthScoreLedgersTable.createTable);
    await db.execute(HealthScoreLedgersTable.createSubjectPeriodIndex);
    await db.execute(HealthScoreLedgersTable.createUserPeriodIndex);
    await db.execute(WellnessPointLedgersTable.createTable);
    await db.execute(WellnessPointLedgersTable.createUserDateIndex);
    await db.execute(WellnessPointLedgersTable.createSourceIndex);
    await SyncOutboxSchema.create(db);
    await SyncOutboxSchema.recreateTriggers(db);
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

  static Future<void> _backfillMissingSyncId(
    Database db,
    String tableName,
  ) async {
    if (!await _tableExists(db, tableName)) return;
    if (!await _columnExists(db, tableName, 'id')) return;
    if (!await _columnExists(db, tableName, 'user_id')) return;

    await db.execute('''
      UPDATE $tableName
      SET id = ${SyncOutboxSchema.sqliteUuidExpression()}
      WHERE id IS NULL OR TRIM(CAST(id AS TEXT)) = ''
    ''');
  }

  static Future<void> _backfillPersonalScheduleAiRequestSync(
    Database db,
  ) async {
    const tableName = SyncOutboxSchema.personalScheduleAiRequestsTable;
    if (!await _tableExists(db, tableName)) return;
    if (!await _columnExists(db, tableName, 'request_id')) return;
    if (!await _columnExists(db, tableName, 'user_id')) return;

    await db.execute('''
      INSERT INTO ${SyncOutboxSchema.outboxTable} (
        id, user_id, table_name, record_id, operation, payload, status,
        attempt_count, last_error, next_retry_at, created_at, updated_at
      )
      SELECT
        user_id || ':$tableName:' || request_id || ':upsert',
        user_id, '$tableName', request_id, 'upsert', '{}', 'pending',
        0, NULL, NULL,
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
      FROM $tableName
      WHERE user_id IS NOT NULL
        AND request_id IS NOT NULL
      ON CONFLICT(id) DO UPDATE SET
        operation = 'upsert',
        payload = '{}',
        status = 'pending',
        last_error = NULL,
        next_retry_at = NULL,
        updated_at = excluded.updated_at
    ''');
  }

  static Future<bool> _tableExists(Database db, String tableName) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return rows.isNotEmpty;
  }

  static Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }
}
