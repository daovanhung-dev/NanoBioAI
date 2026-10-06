import 'package:sqflite/sqflite.dart';

class MigrationV27 {
  const MigrationV27._();

  static Future<void> run(Database db) async => ensureSchema(db);

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(sleep_safety_contacts_cache)',
    );
    if (columns.any(
      (column) => column['name'] == 'allow_unverified_voice_alert',
    )) {
      return;
    }
    await db.execute(
      'ALTER TABLE sleep_safety_contacts_cache '
      'ADD COLUMN allow_unverified_voice_alert INTEGER NOT NULL DEFAULT 0',
    );
  }
}
