import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v28.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('v28 removes Zalo opt-in and preserves cached contact data', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE sleep_safety_contacts_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone_e164 TEXT NOT NULL,
        priority INTEGER NOT NULL CHECK (priority BETWEEN 1 AND 3),
        verification_status TEXT NOT NULL,
        verified_at TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        allow_zalo_alert INTEGER NOT NULL DEFAULT 0,
        allow_phone_fallback INTEGER NOT NULL DEFAULT 1,
        allow_unverified_voice_alert INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, priority),
        UNIQUE(user_id, phone_e164)
      )
    ''');
    await db.insert('sleep_safety_contacts_cache', {
      'id': 'contact-qa',
      'user_id': 'user-1',
      'name': 'Người thân',
      'relationship': 'Gia đình',
      'phone_e164': '+84901234567',
      'priority': 1,
      'verification_status': 'verified',
      'verified_at': '2026-10-01T00:00:00Z',
      'active': 1,
      'allow_zalo_alert': 1,
      'allow_phone_fallback': 1,
      'allow_unverified_voice_alert': 1,
      'created_at': '2026-10-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
    });

    await MigrationV28.run(db);
    await MigrationV28.run(db);

    final row = (await db.query('sleep_safety_contacts_cache')).single;
    expect(row['id'], 'contact-qa');
    expect(row['name'], 'Người thân');
    expect(row['phone_e164'], '+84901234567');
    expect(row['priority'], 1);
    expect(row['verification_status'], 'verified');
    expect(row['verified_at'], '2026-10-01T00:00:00Z');
    expect(row['allow_phone_fallback'], 1);
    expect(row['allow_unverified_voice_alert'], 1);
    final columns = await db.rawQuery(
      'PRAGMA table_info(sleep_safety_contacts_cache)',
    );
    expect(
      columns.map((column) => column['name']),
      isNot(contains('allow_zalo_alert')),
    );
    expect(DatabaseVersion.currentVersion, 28);
  });
}
