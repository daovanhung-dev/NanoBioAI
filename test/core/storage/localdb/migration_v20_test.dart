import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v20.dart';
import 'package:nano_app/core/storage/localdb/tables/health_profiles_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('v20 removes legacy FK orphans before enforcement', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(UsersTable.createTable);
    await db.execute(HealthProfilesTable.createTable);
    await db.insert('health_profiles', {
      'id': 'profile-orphan',
      'user_id': 'missing-user',
      'created_at': '2026-08-17T00:00:00Z',
      'updated_at': '2026-08-17T00:00:00Z',
    });

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isNotEmpty);

    await MigrationV20.run(db);

    expect(await db.query('health_profiles'), isEmpty);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('foreign keys reject invalid children and cascade user deletion', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute(UsersTable.createTable);
    await db.execute(HealthProfilesTable.createTable);

    await expectLater(
      db.insert('health_profiles', {
        'id': 'invalid-profile',
        'user_id': 'missing-user',
      }),
      throwsA(anything),
    );

    await db.insert('users', {
      'id': 'user-a',
      'product_access_status': 'guest',
      'onboarding_status': 'in_progress',
    });
    await db.insert('health_profiles', {
      'id': 'profile-a',
      'user_id': 'user-a',
    });

    await db.delete('users', where: 'id = ?', whereArgs: ['user-a']);
    expect(await db.query('health_profiles'), isEmpty);
  });
}
