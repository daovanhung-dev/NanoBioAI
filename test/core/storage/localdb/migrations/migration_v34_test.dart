import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v34.dart';
import 'package:nano_app/core/storage/localdb/tables/medication_reminders_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test(
    'v33 to v34 adds a local owner-scoped reminder table idempotently',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');

      await MigrationV34.run(db);
      await MigrationV34.run(db);
      await db.insert('users', {'id': 'guest-1'});
      await db.insert(MedicationRemindersTable.tableName, {
        'id': 'med-1',
        'user_id': 'guest-1',
        'medicine_name': 'Medicine name',
        'times_json': '[480,900]',
        'enabled': 1,
        'created_at': '2026-10-15T00:00:00Z',
        'updated_at': '2026-10-15T00:00:00Z',
      });

      final rows = await db.query(MedicationRemindersTable.tableName);
      expect(rows.single['times_json'], '[480,900]');
      expect(rows.single['user_id'], 'guest-1');
      expect(DatabaseVersion.currentVersion, 34);
    },
  );
}
