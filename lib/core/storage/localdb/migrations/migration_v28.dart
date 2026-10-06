import 'package:sqflite/sqflite.dart';

class MigrationV28 {
  const MigrationV28._();

  static const _table = 'sleep_safety_contacts_cache';
  static const _legacyTable = 'sleep_safety_contacts_cache_v27';

  static Future<void> run(Database db) async => ensureSchema(db);

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    final columns = await db.rawQuery('PRAGMA table_info($_table)');
    if (columns.isEmpty ||
        !columns.any((column) => column['name'] == 'allow_zalo_alert')) {
      return;
    }

    await db.execute('ALTER TABLE $_table RENAME TO $_legacyTable');
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone_e164 TEXT NOT NULL,
        priority INTEGER NOT NULL CHECK (priority BETWEEN 1 AND 3),
        verification_status TEXT NOT NULL,
        verified_at TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        allow_phone_fallback INTEGER NOT NULL DEFAULT 1,
        allow_unverified_voice_alert INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, priority),
        UNIQUE(user_id, phone_e164)
      )
    ''');
    await db.execute('''
      INSERT INTO $_table (
        id, user_id, name, relationship, phone_e164, priority,
        verification_status, verified_at, active, allow_phone_fallback,
        allow_unverified_voice_alert, created_at, updated_at
      )
      SELECT
        id, user_id, name, relationship, phone_e164, priority,
        verification_status, verified_at, active, allow_phone_fallback,
        allow_unverified_voice_alert, created_at, updated_at
      FROM $_legacyTable
    ''');
    await db.execute('DROP TABLE $_legacyTable');
  }
}
