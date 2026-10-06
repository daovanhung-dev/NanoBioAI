import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v27.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'v27 adds opt-in for unverified voice alerts with default off',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('''
      CREATE TABLE sleep_safety_contacts_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone_e164 TEXT NOT NULL,
        priority INTEGER NOT NULL,
        verification_status TEXT NOT NULL,
        verified_at TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        allow_zalo_alert INTEGER NOT NULL DEFAULT 0,
        allow_phone_fallback INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
      await db.insert('sleep_safety_contacts_cache', {
        'id': 'contact-1',
        'user_id': 'user-1',
        'name': 'Người thân',
        'relationship': 'Gia đình',
        'phone_e164': '+84901234567',
        'priority': 1,
        'verification_status': 'pending',
        'active': 1,
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-01T00:00:00Z',
      });

      await MigrationV27.run(db);
      await MigrationV27.run(db);

      final row = (await db.query('sleep_safety_contacts_cache')).single;
      expect(row['id'], 'contact-1');
      expect(row['allow_unverified_voice_alert'], 0);
      expect(DatabaseVersion.currentVersion, 28);
    },
  );
}
