import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_manager.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_runtime_state.dart';
import 'package:sqflite/sqflite.dart';
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

  test('migration v8 creates and seeds AI catalog tables once', () async {
    await MigrationManager.runMigrations(db, 7, 8);
    await MigrationManager.runMigrations(db, 7, 8);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tables.map((table) => table['name']).toList();

    expect(tableNames, contains('meal_catalog'));
    expect(tableNames, contains('exercise_catalog'));
    expect(tableNames, contains('schedule_task_catalog'));

    final mealCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM meal_catalog'),
    );
    final exerciseCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM exercise_catalog'),
    );
    final scheduleCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM schedule_task_catalog'),
    );

    expect(mealCount, 40);
    expect(exerciseCount, 16);
    expect(scheduleCount, 3);

    final indexes = await db.rawQuery('PRAGMA index_list(meal_catalog)');
    final indexNames = indexes.map((index) => index['name']).toList();
    expect(indexNames, contains('idx_meal_catalog_type'));
  });

  test('migration v9 creates durable user-data sync triggers once', () async {
    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');
    for (final table in SyncOutboxSchema.userOwnedTables) {
      await db.execute(
        'CREATE TABLE $table (id TEXT PRIMARY KEY, user_id TEXT)',
      );
    }

    await MigrationManager.runMigrations(db, 8, 9);
    await MigrationManager.runMigrations(db, 8, 9);

    final userColumns = await db.rawQuery('PRAGMA table_info(users)');
    final names = userColumns.map((column) => column['name']).toList();
    expect(names, containsAll(<String>[
      'product_access_status',
      'sale_status',
      'onboarding_status',
      'onboarding_completed_at',
    ]));

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tables.map((table) => table['name']).toList();
    expect(tableNames, contains('sync_outbox'));
    expect(tableNames, contains('sync_runtime_state'));

    await db.insert('users', {'id': 'auth-1'});
    await db.insert('meal_plans', {'id': 'meal-1', 'user_id': 'auth-1'});
    await db.update(
      'meal_plans',
      {'user_id': 'auth-1'},
      where: 'id = ?',
      whereArgs: ['meal-1'],
    );

    final mealMarkers = await db.query(
      SyncOutboxSchema.outboxTable,
      where: 'user_id = ? AND table_name = ?',
      whereArgs: ['auth-1', 'meal_plans'],
    );
    expect(mealMarkers, hasLength(1));
    expect(mealMarkers.single['operation'], 'upsert');

    await SyncRuntimeState.setApplyingCloud(db, true);
    await db.insert('daily_health_tasks', {
      'id': 'task-cloud-1',
      'user_id': 'auth-1',
    });
    await SyncRuntimeState.setApplyingCloud(db, false);

    final cloudApplyMarkers = await db.query(
      SyncOutboxSchema.outboxTable,
      where: 'record_id = ?',
      whereArgs: ['task-cloud-1'],
    );
    expect(cloudApplyMarkers, isEmpty);
  });
}
