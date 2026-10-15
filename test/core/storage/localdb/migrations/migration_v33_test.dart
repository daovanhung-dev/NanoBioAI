import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/wellness_rank_summary_cache_dao.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v32.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v33.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test(
    'v32 to v33 creates user-scoped rank cache and preserves rewards',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await MigrationV32.ensureSchema(db);
      await db.execute(WellnessRewardSummaryCacheTable.createTable);
      await db.insert(WellnessRewardSummaryCacheTable.tableName, {
        'user_id': 'user-a',
        'pending_points': 2,
        'available_points': 8,
        'expiring_soon_points': 0,
        'synced_at': '2026-10-14T00:00:00Z',
      });

      await MigrationV33.run(db);
      await MigrationV33.run(db);
      final dao = WellnessRankSummaryCacheDao(db);
      await dao.save({
        'user_id': 'user-a',
        'rank_code': 'wellness_rank_2',
        'rank_level': 2,
        'title': 'Người Ươm Nếp Lành',
        'experience_points': 600,
        'current_rank_threshold': 600,
        'next_rank_threshold': 1200,
        'experience_to_next_rank': 600,
        'rank_progress_exp': 0,
        'rank_progress_target': 600,
        'computed_at': '2026-10-14T00:00:00Z',
        'next_decay_at': '2026-10-21T00:00:00Z',
        'synced_at': '2026-10-14T00:00:00Z',
      });

      expect(await dao.findForUser('user-a'), isNotNull);
      expect(await dao.findForUser('user-b'), isNull);
      final rewards = await db.query(WellnessRewardSummaryCacheTable.tableName);
      expect(rewards.single['available_points'], 8);
      expect(DatabaseVersion.currentVersion, 33);
    },
  );
}
