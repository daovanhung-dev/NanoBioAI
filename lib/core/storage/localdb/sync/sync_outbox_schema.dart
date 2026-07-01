import 'package:sqflite/sqflite.dart';

/// SQLite write-through queue schema for all locally stored user data.
///
/// The triggers enqueue a compact dirty marker in the same transaction as a
/// user-data write. Dart drains that queue to Supabase using a full,
/// user-scoped snapshot, therefore a local write can never be lost merely
/// because the app goes offline immediately afterwards.
class SyncOutboxSchema {
  SyncOutboxSchema._();

  static const runtimeStateTable = 'sync_runtime_state';
  static const outboxTable = 'sync_outbox';
  static const applyingCloudKey = 'is_applying_cloud';

  static const userOwnedTables = <String>[
    'health_profiles',
    'lifestyle_habits',
    'health_goals',
    'health_conditions',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
    'meal_plans',
    'daily_health_tasks',
    'lifestyle_schedule_items',
    'notifications',
    'health_tracking_logs',
    'nutrition_logs',
    'ai_insights',
    'ai_recommendations',
  ];

  static const createRuntimeStateTable = '''
CREATE TABLE IF NOT EXISTS sync_runtime_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const createOutboxTable = '''
CREATE TABLE IF NOT EXISTS sync_outbox (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('upsert', 'delete')),
  payload TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'syncing', 'failed')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  next_retry_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const createUserStatusIndex = '''
CREATE INDEX IF NOT EXISTS idx_sync_outbox_user_status_due
ON sync_outbox(user_id, status, next_retry_at, created_at)
''';

  static const createUserTableIndex = '''
CREATE INDEX IF NOT EXISTS idx_sync_outbox_user_table
ON sync_outbox(user_id, table_name, record_id)
''';

  static Future<void> create(Database db) async {
    await db.execute(createRuntimeStateTable);
    await db.execute(createOutboxTable);
    await db.execute(createUserStatusIndex);
    await db.execute(createUserTableIndex);
    await _ensureRuntimeState(db);
    await _createTriggers(db);
  }

  /// Reinstalls the SQLite trigger set when its definition changes.
  ///
  /// `CREATE TRIGGER IF NOT EXISTS` deliberately keeps existing triggers, so a
  /// database upgrade must explicitly drop and recreate them. This is used by
  /// migration v12 to add stable IDs for legacy inserts that previously wrote
  /// `NULL` to `id` and therefore bypassed the sync outbox.
  static Future<void> recreateTriggers(Database db) async {
    await _dropTriggers(db);
    await _createTriggers(db);
  }

  static Future<void> _ensureRuntimeState(Database db) {
    return db.insert(runtimeStateTable, {
      'key': applyingCloudKey,
      'value': '0',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> _createTriggers(Database db) async {
    // A number of legacy writers omit the TEXT primary-key `id`. SQLite allows
    // that on rowid tables, but the old outbox trigger intentionally ignored
    // rows with a null ID. Normalize first so every user-owned change is
    // observable and can be represented in a cloud snapshot.
    for (final table in userOwnedTables) {
      await db.execute(_normalizeIdAfterInsertTrigger(table));
    }

    await db.execute(_insertTriggerForUsers());
    await db.execute(_updateTriggerForUsers());
    await db.execute(_deleteTriggerForUsers());

    for (final table in userOwnedTables) {
      await db.execute(_insertTriggerForUserOwnedTable(table));
      await db.execute(_updateTriggerForUserOwnedTable(table));
      await db.execute(_deleteTriggerForUserOwnedTable(table));
    }
  }

  static Future<void> _dropTriggers(Database db) async {
    await db.execute('DROP TRIGGER IF EXISTS trg_sync_outbox_users_insert');
    await db.execute('DROP TRIGGER IF EXISTS trg_sync_outbox_users_update');
    await db.execute('DROP TRIGGER IF EXISTS trg_sync_outbox_users_delete');

    for (final table in userOwnedTables) {
      await db.execute(
        'DROP TRIGGER IF EXISTS trg_sync_normalize_id_${table}_insert',
      );
      await db.execute(
        'DROP TRIGGER IF EXISTS trg_sync_outbox_${table}_insert',
      );
      await db.execute(
        'DROP TRIGGER IF EXISTS trg_sync_outbox_${table}_update',
      );
      await db.execute(
        'DROP TRIGGER IF EXISTS trg_sync_outbox_${table}_delete',
      );
    }
  }

  static String _normalizeIdAfterInsertTrigger(String table) =>
      '''
CREATE TRIGGER IF NOT EXISTS trg_sync_normalize_id_${table}_insert
AFTER INSERT ON $table
WHEN NEW.user_id IS NOT NULL
  AND (NEW.id IS NULL OR TRIM(CAST(NEW.id AS TEXT)) = '')
BEGIN
  UPDATE $table
  SET id = ${sqliteUuidExpression()}
  WHERE rowid = NEW.rowid
    AND (id IS NULL OR TRIM(CAST(id AS TEXT)) = '');
END
''';

  /// SQLite expression that produces a RFC 4122 version-4 UUID-shaped value.
  /// The value remains a valid UUID when the snapshot RPC mirrors it to
  /// Supabase, so reference fields such as `source_id` stay stable locally.
  static String sqliteUuidExpression() =>
      "lower(hex(randomblob(4))) || '-' || "
      "lower(hex(randomblob(2))) || '-' || "
      "'4' || substr(lower(hex(randomblob(2))), 2) || '-' || "
      "substr('89ab', abs(random()) % 4 + 1, 1) || "
      "substr(lower(hex(randomblob(2))), 2) || '-' || "
      "lower(hex(randomblob(6)))";

  static String _insertTriggerForUsers() =>
      _upsertTriggerForUsers('insert', 'INSERT');

  static String _updateTriggerForUsers() =>
      _upsertTriggerForUsers('update', 'UPDATE');

  static String _upsertTriggerForUsers(String suffix, String event) =>
      '''
CREATE TRIGGER IF NOT EXISTS trg_sync_outbox_users_$suffix
AFTER $event ON users
WHEN NEW.id IS NOT NULL
  AND COALESCE((SELECT value FROM $runtimeStateTable WHERE key = '$applyingCloudKey'), '0') <> '1'
BEGIN
  INSERT INTO $outboxTable (
    id, user_id, table_name, record_id, operation, payload, status,
    attempt_count, last_error, next_retry_at, created_at, updated_at
  ) VALUES (
    NEW.id || ':users:' || NEW.id || ':upsert',
    NEW.id, 'users', NEW.id, 'upsert', '{}', 'pending',
    0, NULL, NULL,
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  )
  ON CONFLICT(id) DO UPDATE SET
    operation = 'upsert',
    payload = '{}',
    status = 'pending',
    last_error = NULL,
    next_retry_at = NULL,
    updated_at = excluded.updated_at;
END
''';

  static String _deleteTriggerForUsers() =>
      '''
CREATE TRIGGER IF NOT EXISTS trg_sync_outbox_users_delete
AFTER DELETE ON users
WHEN OLD.id IS NOT NULL
  AND COALESCE((SELECT value FROM $runtimeStateTable WHERE key = '$applyingCloudKey'), '0') <> '1'
BEGIN
  INSERT INTO $outboxTable (
    id, user_id, table_name, record_id, operation, payload, status,
    attempt_count, last_error, next_retry_at, created_at, updated_at
  ) VALUES (
    OLD.id || ':users:' || OLD.id || ':delete',
    OLD.id, 'users', OLD.id, 'delete', '{}', 'pending',
    0, NULL, NULL,
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  )
  ON CONFLICT(id) DO UPDATE SET
    operation = 'delete',
    payload = '{}',
    status = 'pending',
    last_error = NULL,
    next_retry_at = NULL,
    updated_at = excluded.updated_at;
END
''';

  static String _insertTriggerForUserOwnedTable(String table) =>
      _upsertTriggerForUserOwnedTable(table, 'insert', 'INSERT');

  static String _updateTriggerForUserOwnedTable(String table) =>
      _upsertTriggerForUserOwnedTable(table, 'update', 'UPDATE');

  static String _upsertTriggerForUserOwnedTable(
    String table,
    String suffix,
    String event,
  ) =>
      '''
CREATE TRIGGER IF NOT EXISTS trg_sync_outbox_${table}_$suffix
AFTER $event ON $table
WHEN NEW.user_id IS NOT NULL
  AND NEW.id IS NOT NULL
  AND COALESCE((SELECT value FROM $runtimeStateTable WHERE key = '$applyingCloudKey'), '0') <> '1'
BEGIN
  INSERT INTO $outboxTable (
    id, user_id, table_name, record_id, operation, payload, status,
    attempt_count, last_error, next_retry_at, created_at, updated_at
  ) VALUES (
    NEW.user_id || ':$table:' || NEW.id || ':upsert',
    NEW.user_id, '$table', NEW.id, 'upsert', '{}', 'pending',
    0, NULL, NULL,
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  )
  ON CONFLICT(id) DO UPDATE SET
    operation = 'upsert',
    payload = '{}',
    status = 'pending',
    last_error = NULL,
    next_retry_at = NULL,
    updated_at = excluded.updated_at;
END
''';

  static String _deleteTriggerForUserOwnedTable(String table) =>
      '''
CREATE TRIGGER IF NOT EXISTS trg_sync_outbox_${table}_delete
AFTER DELETE ON $table
WHEN OLD.user_id IS NOT NULL
  AND OLD.id IS NOT NULL
  AND COALESCE((SELECT value FROM $runtimeStateTable WHERE key = '$applyingCloudKey'), '0') <> '1'
BEGIN
  INSERT INTO $outboxTable (
    id, user_id, table_name, record_id, operation, payload, status,
    attempt_count, last_error, next_retry_at, created_at, updated_at
  ) VALUES (
    OLD.user_id || ':$table:' || OLD.id || ':delete',
    OLD.user_id, '$table', OLD.id, 'delete', '{}', 'pending',
    0, NULL, NULL,
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  )
  ON CONFLICT(id) DO UPDATE SET
    operation = 'delete',
    payload = '{}',
    status = 'pending',
    last_error = NULL,
    next_retry_at = NULL,
    updated_at = excluded.updated_at;
END
''';
}
