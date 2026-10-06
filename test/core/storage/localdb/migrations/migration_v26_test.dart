import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v26.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'v26 preserves cached contacts and applies channel defaults once',
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
        'verification_status': 'verified',
        'active': 1,
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-01T00:00:00Z',
      });

      await MigrationV26.run(db);
      await MigrationV26.run(db);

      final row = (await db.query('sleep_safety_contacts_cache')).single;
      expect(row['id'], 'contact-1');
      expect(row['allow_zalo_alert'], 0);
      expect(row['allow_phone_fallback'], 1);
      final columns = await db.rawQuery(
        'PRAGMA table_info(sleep_safety_contacts_cache)',
      );
      final names = columns.map((column) => column['name']).toList();
      expect(names.where((name) => name == 'allow_zalo_alert'), hasLength(1));
      expect(
        names.where((name) => name == 'allow_phone_fallback'),
        hasLength(1),
      );
    },
  );
}
