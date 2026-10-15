import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/database_version.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v32.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test(
    'v32 upgrades reward caches and preserves existing voucher rows',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('''
      CREATE TABLE wellness_reward_offer_cache (
        id TEXT NOT NULL, user_id TEXT NOT NULL, title TEXT NOT NULL,
        description TEXT NOT NULL, provider_name TEXT NOT NULL,
        cost_points INTEGER NOT NULL, available_codes INTEGER NOT NULL DEFAULT 0,
        eligible_plan_codes TEXT NOT NULL DEFAULT '[]', available_from TEXT,
        available_until TEXT, voucher_expires_at TEXT,
        is_active INTEGER NOT NULL DEFAULT 1, synced_at TEXT NOT NULL,
        PRIMARY KEY(user_id, id)
      )
    ''');
      await db.execute('''
      CREATE TABLE wellness_reward_redemption_cache (
        id TEXT NOT NULL, user_id TEXT NOT NULL, offer_id TEXT NOT NULL,
        title TEXT NOT NULL, provider_name TEXT NOT NULL,
        points_spent INTEGER NOT NULL, status TEXT NOT NULL,
        voucher_expires_at TEXT, created_at TEXT, cancelled_at TEXT,
        synced_at TEXT NOT NULL, PRIMARY KEY(user_id, id)
      )
    ''');
      await db.insert('wellness_reward_offer_cache', {
        'id': 'offer-1',
        'user_id': 'user-1',
        'title': 'Voucher cũ',
        'description': 'Mô tả',
        'provider_name': 'NanoBio',
        'cost_points': 10,
        'synced_at': '2026-10-14T00:00:00Z',
      });
      await db.insert('wellness_reward_redemption_cache', {
        'id': 'redemption-1',
        'user_id': 'user-1',
        'offer_id': 'offer-1',
        'title': 'Voucher cũ',
        'provider_name': 'NanoBio',
        'points_spent': 10,
        'status': 'issued',
        'synced_at': '2026-10-14T00:00:00Z',
      });

      await MigrationV32.run(db);
      await MigrationV32.run(db);

      final offer = (await db.query('wellness_reward_offer_cache')).single;
      final redemption = (await db.query(
        'wellness_reward_redemption_cache',
      )).single;
      expect(offer['reward_type'], 'voucher');
      expect(offer['stock_count'], 0);
      expect(offer['title'], 'Voucher cũ');
      expect(redemption['reward_type'], 'voucher');
      expect(redemption['received_at'], isNull);
      expect(redemption['status'], 'issued');
      expect(DatabaseVersion.currentVersion, greaterThanOrEqualTo(33));
    },
  );

  test('v32 creates reward cache tables with physical gift fields', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await MigrationV32.ensureSchema(db);

    final offerColumns = (await db.rawQuery(
      'PRAGMA table_info(${WellnessRewardOfferCacheTable.tableName})',
    )).map((row) => row['name']);
    final redemptionColumns = (await db.rawQuery(
      'PRAGMA table_info(${WellnessRewardRedemptionCacheTable.tableName})',
    )).map((row) => row['name']);
    expect(offerColumns, containsAll(['reward_type', 'stock_count']));
    expect(redemptionColumns, containsAll(['reward_type', 'received_at']));
  });
}
