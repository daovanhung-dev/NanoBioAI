import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');
    for (final table in SyncOutboxSchema.userOwnedTables) {
      await db.execute(
        'CREATE TABLE $table (id TEXT PRIMARY KEY, user_id TEXT)',
      );
    }
    await SyncOutboxSchema.create(db);
    await db.insert('users', {'id': 'auth-1'});
    await db.delete(SyncOutboxSchema.outboxTable);
  });

  tearDown(() async => db.close());

  test(
    'a local table write produces one snapshot push and clears that marker',
    () async {
      await db.insert('meal_plans', {'id': 'meal-1', 'user_id': 'auth-1'});

      var pushCalls = 0;
      final outbox = UserDataSyncOutbox(
        databaseOverride: db,
        currentUserId: () => 'auth-1',
        snapshotPusher: (_, __) async => pushCalls++,
      );

      final drained = await outbox.drainPending();

      expect(drained, 1);
      expect(pushCalls, 1);
      final remaining = await db.query(SyncOutboxSchema.outboxTable);
      expect(remaining, isEmpty);
    },
  );

  test('a write during snapshot push is retained for the next sync', () async {
    await db.insert('meal_plans', {'id': 'meal-1', 'user_id': 'auth-1'});

    var pushCalls = 0;
    final outbox = UserDataSyncOutbox(
      databaseOverride: db,
      currentUserId: () => 'auth-1',
      snapshotPusher: (_, database) async {
        pushCalls++;
        if (pushCalls == 1) {
          await database.insert('daily_health_tasks', {
            'id': 'task-1',
            'user_id': 'auth-1',
          });
        }
      },
    );

    await outbox.drainPending();

    final pendingAfterFirst = await db.query(
      SyncOutboxSchema.outboxTable,
      where: 'user_id = ?',
      whereArgs: ['auth-1'],
    );
    expect(pendingAfterFirst, hasLength(1));
    expect(pendingAfterFirst.single['record_id'], 'task-1');

    await outbox.drainPending();
    expect(pushCalls, 2);
    final remaining = await db.query(SyncOutboxSchema.outboxTable);
    expect(remaining, isEmpty);
  });
}
