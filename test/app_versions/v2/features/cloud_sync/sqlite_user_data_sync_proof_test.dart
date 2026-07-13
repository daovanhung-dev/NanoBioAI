import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/sqlite_user_data_sync_local_datasource.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/user_data_snapshot.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_completion_proofs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_point_ledgers_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      "CREATE TABLE users (id TEXT PRIMARY KEY, subscription_tier TEXT)",
    );
    for (final table in SyncOutboxSchema.genericIdUserOwnedTables) {
      await db.execute(
        'CREATE TABLE $table (id TEXT PRIMARY KEY, user_id TEXT)',
      );
    }
    await db.execute('''
      CREATE TABLE personal_schedule_ai_requests (
        request_id TEXT PRIMARY KEY,
        user_id TEXT
      )
    ''');
    await db.execute(ScheduleCompletionProofsTable.createTable);
    await db.execute(WellnessPointLedgersTable.createTable);
    await SyncOutboxSchema.create(db);
  });

  tearDown(() => db.close());

  test(
    'guest proof ownership survives authenticated cloud replacement',
    () async {
      await db.insert('users', {'id': 'guest-1', 'subscription_tier': 'free'});
      await db.insert(ScheduleCompletionProofsTable.tableName, {
        'id': 'proof-1',
        'user_id': 'guest-1',
        'schedule_item_id': 'schedule-1',
        'schedule_date': '2026-07-13',
        'start_time': '07:00',
        'schedule_title': 'Đi bộ buổi sáng',
        'local_path': 'schedule_proofs/proof-1.jpg',
        'captured_at': '2026-07-13T07:05:00',
        'completed_at': '2026-07-13T07:05:00',
        'created_at': '2026-07-13T07:05:00',
        'updated_at': '2026-07-13T07:05:00',
      });

      await SqliteUserDataSyncLocalDatasource(
        databaseOverride: db,
      ).replaceFromCloud(
        userId: 'auth-1',
        snapshot: const UserDataSnapshot(user: {'id': 'auth-1'}, tables: {}),
        removeLocalUserId: 'guest-1',
      );

      final proofs = await db.query(ScheduleCompletionProofsTable.tableName);
      expect(proofs, hasLength(1));
      expect(proofs.single['user_id'], 'auth-1');
      expect(proofs.single['local_path'], 'schedule_proofs/proof-1.jpg');
    },
  );

  test(
    'server-owned wellness ledger is replaced from cloud without outbox',
    () async {
      await db.insert('users', {'id': 'auth-1', 'subscription_tier': 'free'});
      await db.delete(
        SyncOutboxSchema.outboxTable,
        where: 'user_id = ?',
        whereArgs: ['auth-1'],
      );
      await db.insert(WellnessPointLedgersTable.tableName, {
        'id': 'legacy-local',
        'user_id': 'auth-1',
        'source_type': 'legacy',
        'source_id': 'legacy',
        'schedule_date': '2026-07-12',
        'points_delta': 10,
        'program_code': 'legacy',
        'idempotency_key': 'legacy-local',
        'created_at': '2026-07-12T00:00:00Z',
        'updated_at': '2026-07-12T00:00:00Z',
      });

      await SqliteUserDataSyncLocalDatasource(
        databaseOverride: db,
      ).replaceFromCloud(
        userId: 'auth-1',
        snapshot: const UserDataSnapshot(
          user: {'id': 'auth-1'},
          tables: {
            'wellness_point_ledgers': [
              {
                'id': 'server-award',
                'user_id': 'auth-1',
                'source_type': 'schedule_reward',
                'source_id': 'attempt-1',
                'schedule_date': '2026-07-13',
                'points_delta': 10,
                'program_code': 'wellness_schedule_v2',
                'idempotency_key': 'award-attempt-1',
                'created_at': '2026-07-13T00:30:00Z',
                'updated_at': '2026-07-13T00:30:00Z',
              },
            ],
          },
        ),
      );

      final rows = await db.query(WellnessPointLedgersTable.tableName);
      expect(rows.map((row) => row['id']), ['server-award']);
      expect(
        await db.query(
          SyncOutboxSchema.outboxTable,
          where: 'user_id = ?',
          whereArgs: ['auth-1'],
        ),
        isEmpty,
      );
    },
  );
}
