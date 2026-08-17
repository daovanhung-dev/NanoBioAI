import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v19.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_health_checkin_outbox_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('database version is 19', () {
    expect(DatabaseVersion.currentVersion, 19);
  });

  test('migration v19 creates durable health reward check-in outbox', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await MigrationV19.run(db);
    await MigrationV19.ensureSchema(db);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [ScheduleHealthCheckInOutboxTable.tableName],
    );
    final columns = await db.rawQuery(
      'PRAGMA table_info(${ScheduleHealthCheckInOutboxTable.tableName})',
    );
    final names = columns.map((row) => row['name']).toSet();

    expect(tables, hasLength(1));
    expect(
      names,
      containsAll({
        'schedule_item_id',
        'action_type',
        'payload',
        'completion_token',
        'sync_status',
        'points_delta',
      }),
    );
  });
}
