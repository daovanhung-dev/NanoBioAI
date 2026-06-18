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

  test(
    'migration v5 creates lifestyle schedule table and indexes once',
    () async {
      await MigrationManager.runMigrations(db, 4, 5);
      await MigrationManager.runMigrations(db, 4, 5);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = tables.map((table) => table['name']).toList();

      expect(tableNames, contains('lifestyle_schedule_items'));

      final columns = await db.rawQuery(
        'PRAGMA table_info(lifestyle_schedule_items)',
      );
      final names = columns.map((column) => column['name']).toList();

      const expectedColumns = [
        'id',
        'user_id',
        'schedule_date',
        'start_time',
        'end_time',
        'title',
        'description',
        'category',
        'source_type',
        'source_id',
        'target_value',
        'current_value',
        'unit',
        'is_completed',
        'sort_order',
        'ai_generated',
        'encouragement',
        'created_at',
        'updated_at',
      ];

      for (final columnName in expectedColumns) {
        expect(names, contains(columnName));
        expect(names.where((name) => name == columnName), hasLength(1));
      }

      final indexes = await db.rawQuery(
        'PRAGMA index_list(lifestyle_schedule_items)',
      );
      final indexNames = indexes.map((index) => index['name']).toList();

      expect(indexNames, contains('idx_lifestyle_schedule_user_date'));
      expect(indexNames, contains('idx_lifestyle_schedule_source'));
    },
  );

  test('migration v6 adds meal times and daily score once', () async {
    await db.execute('''
      CREATE TABLE meal_plans (
        id TEXT PRIMARY KEY,
        meal_name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE health_tracking_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        log_date TEXT
      )
    ''');

    await MigrationManager.runMigrations(db, 5, 6);
    await MigrationManager.runMigrations(db, 5, 6);

    final mealColumns = await db.rawQuery('PRAGMA table_info(meal_plans)');
    final mealNames = mealColumns.map((column) => column['name']).toList();

    expect(mealNames, contains('start_time'));
    expect(mealNames, contains('end_time'));
    expect(mealNames.where((name) => name == 'start_time'), hasLength(1));
    expect(mealNames.where((name) => name == 'end_time'), hasLength(1));

    final logColumns = await db.rawQuery(
      'PRAGMA table_info(health_tracking_logs)',
    );
    final logNames = logColumns.map((column) => column['name']).toList();

    expect(logNames, contains('daily_score'));
    expect(logNames.where((name) => name == 'daily_score'), hasLength(1));
  });

  test('migration v7 adds live metrics and subscription tier once', () async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE health_tracking_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        log_date TEXT
      )
    ''');

    await MigrationManager.runMigrations(db, 6, 7);
    await MigrationManager.runMigrations(db, 6, 7);

    final userColumns = await db.rawQuery('PRAGMA table_info(users)');
    final userNames = userColumns.map((column) => column['name']).toList();

    expect(userNames, contains('subscription_tier'));
    expect(
      userNames.where((name) => name == 'subscription_tier'),
      hasLength(1),
    );

    final logColumns = await db.rawQuery(
      'PRAGMA table_info(health_tracking_logs)',
    );
    final logNames = logColumns.map((column) => column['name']).toList();

    expect(logNames, contains('heart_rate_bpm'));
    expect(logNames, contains('oxygen_saturation'));
    expect(logNames.where((name) => name == 'heart_rate_bpm'), hasLength(1));
    expect(logNames.where((name) => name == 'oxygen_saturation'), hasLength(1));
  });
}
