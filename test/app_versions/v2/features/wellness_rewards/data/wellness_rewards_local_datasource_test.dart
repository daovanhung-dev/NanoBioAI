import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/data/datasources/wellness_rewards_local_datasource.dart';
import 'package:nano_app/app_versions/v2/features/wellness_rewards/domain/entities/wellness_reward_models.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late WellnessRewardsLocalDatasource datasource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    for (final statement in wellnessRewardCacheSchema) {
      await database.execute(statement);
    }
    datasource = WellnessRewardsLocalDatasource(databaseOverride: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('round-trips the read-only dashboard projection by user', () async {
    final expected = _dashboard(suffix: 'u1');

    await datasource.replaceDashboard(userId: 'user-1', dashboard: expected);
    final actual = await datasource.loadDashboard('user-1');

    expect(actual, isNotNull);
    expect(actual!.summary.pendingPoints, 10);
    expect(actual.summary.availablePoints, 20);
    expect(actual.offers.single.id, 'offer-u1');
    expect(actual.offers.single.eligiblePlanCodes, ['free', 'plus']);
    expect(actual.pointHistory.single.pointsDelta, 10);
    expect(actual.redemptions.single.id, 'redemption-u1');
  });

  test('never stores the one-time voucher code in SQLite', () async {
    await datasource.replaceDashboard(
      userId: 'user-1',
      dashboard: _dashboard(suffix: 'u1', voucherCode: 'SECRET-CODE-123'),
    );

    final columns = await database.rawQuery(
      'PRAGMA table_info(${WellnessRewardRedemptionCacheTable.tableName})',
    );
    final rows = await database.query(
      WellnessRewardRedemptionCacheTable.tableName,
    );
    final loaded = await datasource.loadDashboard('user-1');

    expect(
      columns.map((column) => column['name']),
      isNot(contains('voucher_code')),
    );
    expect(rows.single.containsKey('voucher_code'), isFalse);
    expect(rows.single.values, isNot(contains('SECRET-CODE-123')));
    expect(loaded!.redemptions.single.voucherCode, isNull);
  });

  test('replacement for one account does not erase another account', () async {
    await datasource.replaceDashboard(
      userId: 'user-1',
      dashboard: _dashboard(suffix: 'u1'),
    );
    await datasource.replaceDashboard(
      userId: 'user-2',
      dashboard: _dashboard(suffix: 'u2'),
    );
    await datasource.replaceDashboard(
      userId: 'user-1',
      dashboard: const WellnessRewardsDashboard(
        summary: WellnessRewardSummary(
          pendingPoints: 0,
          availablePoints: 0,
          expiringSoonPoints: 0,
        ),
        offers: [],
        pointHistory: [],
        redemptions: [],
      ),
    );

    final user1 = await datasource.loadDashboard('user-1');
    final user2 = await datasource.loadDashboard('user-2');

    expect(user1, isNotNull);
    expect(user1!.offers, isEmpty);
    expect(user2, isNotNull);
    expect(user2!.offers.single.id, 'offer-u2');
    expect(user2.redemptions.single.id, 'redemption-u2');
  });

  test('ignores blank user ids instead of leaking a shared cache', () async {
    await datasource.replaceDashboard(
      userId: '   ',
      dashboard: _dashboard(suffix: 'blank'),
    );

    expect(await datasource.loadDashboard(''), isNull);
    expect(
      await database.query(WellnessRewardSummaryCacheTable.tableName),
      isEmpty,
    );
  });
}

WellnessRewardsDashboard _dashboard({
  required String suffix,
  String? voucherCode,
}) {
  return WellnessRewardsDashboard(
    summary: WellnessRewardSummary(
      pendingPoints: 10,
      availablePoints: 20,
      expiringSoonPoints: 5,
      nextExpiryAt: DateTime.utc(2026, 12, 31),
    ),
    offers: [
      WellnessRewardOffer(
        id: 'offer-$suffix',
        title: 'Ưu đãi $suffix',
        description: 'Mô tả ưu đãi',
        providerName: 'NanoBio',
        costPoints: 20,
        availableCodes: 3,
        eligiblePlanCodes: const ['free', 'plus'],
        isActive: true,
      ),
    ],
    pointHistory: [
      WellnessPointHistoryEntry(
        id: 'history-$suffix',
        pointsDelta: 10,
        eventType: 'schedule_completion',
        status: 'pending',
        title: 'Hoàn thành nhiệm vụ',
        isRedeemable: true,
        createdAt: DateTime.utc(2026, 7, 13),
      ),
    ],
    redemptions: [
      WellnessRewardRedemption(
        id: 'redemption-$suffix',
        offerId: 'offer-$suffix',
        title: 'Voucher $suffix',
        providerName: 'NanoBio',
        pointsSpent: 20,
        status: 'issued',
        voucherCode: voucherCode,
        createdAt: DateTime.utc(2026, 7, 13),
      ),
    ],
  );
}
