import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  test('migration v3 adds cooking instructions to meal plans once', () async {
    await db.execute('''
      CREATE TABLE meal_plans (
        id TEXT PRIMARY KEY,
        meal_name TEXT
      )
    ''');

    await MigrationManager.runMigrations(db, 2, 3);
    await MigrationManager.runMigrations(db, 2, 3);

    final columns = await db.rawQuery('PRAGMA table_info(meal_plans)');
    final names = columns.map((column) => column['name']).toList();

    expect(names, contains('cooking_instructions'));
    expect(names.where((name) => name == 'cooking_instructions'), hasLength(1));
  });

  test('migration v4 adds notification reminder columns once', () async {
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        body TEXT,
        type TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await MigrationManager.runMigrations(db, 3, 4);
    await MigrationManager.runMigrations(db, 3, 4);

    final columns = await db.rawQuery('PRAGMA table_info(notifications)');
    final names = columns.map((column) => column['name']).toList();

    const expectedColumns = [
      'source_type',
      'source_id',
      'scheduled_at',
      'notification_id',
      'action_status',
      'responded_at',
      'payload',
      'updated_at',
    ];

    for (final columnName in expectedColumns) {
      expect(names, contains(columnName));
      expect(names.where((name) => name == columnName), hasLength(1));
    }

    final indexes = await db.rawQuery('PRAGMA index_list(notifications)');
    final indexNames = indexes.map((index) => index['name']).toList();

    expect(indexNames, contains('idx_notifications_source'));
    expect(indexNames, contains('idx_notifications_notification_id'));
  });
}
