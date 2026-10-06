import 'package:sqflite/sqflite.dart';

class MigrationV26 {
  const MigrationV26._();

  static Future<void> run(Database db) async => ensureSchema(db);

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'sleep_safety_contacts_cache',
      columnName: 'allow_zalo_alert',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'sleep_safety_contacts_cache',
      columnName: 'allow_phone_fallback',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
  }

  static Future<void> _addColumnIfMissing(
    DatabaseExecutor db, {
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    if (columns.any((column) => column['name'] == columnName)) return;
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnName $definition',
    );
  }
}
