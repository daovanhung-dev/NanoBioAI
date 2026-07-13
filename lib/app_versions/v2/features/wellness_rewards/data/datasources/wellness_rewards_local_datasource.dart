import 'dart:convert';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/wellness_reward_models.dart';

class WellnessRewardsLocalDatasource {
  final Database? databaseOverride;

  const WellnessRewardsLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<WellnessRewardsDashboard?> loadDashboard(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    final db = await _db();
    final summaries = await db.query(
      WellnessRewardSummaryCacheTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      limit: 1,
    );
    if (summaries.isEmpty) return null;

    final offers = await db.query(
      WellnessRewardOfferCacheTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      orderBy: 'is_active DESC, cost_points ASC, title ASC',
    );
    final history = await db.query(
      WellnessRewardPointHistoryCacheTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      orderBy: 'created_at DESC',
    );
    final redemptions = await db.query(
      WellnessRewardRedemptionCacheTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      orderBy: 'created_at DESC',
    );

    return WellnessRewardsDashboard(
      summary: WellnessRewardSummary.fromMap(summaries.first),
      offers: offers
          .map((row) {
            final copy = Map<String, Object?>.from(row);
            copy['eligible_plan_codes'] = _decodeStringList(
              row['eligible_plan_codes'],
            );
            return WellnessRewardOffer.fromMap(copy);
          })
          .toList(growable: false),
      pointHistory: history
          .map(WellnessPointHistoryEntry.fromMap)
          .toList(growable: false),
      redemptions: redemptions
          .map(WellnessRewardRedemption.fromMap)
          .toList(growable: false),
    );
  }

  Future<void> replaceDashboard({
    required String userId,
    required WellnessRewardsDashboard dashboard,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    final db = await _db();
    final syncedAt = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert(
        WellnessRewardSummaryCacheTable.tableName,
        {
          'user_id': normalizedUserId,
          'pending_points': dashboard.summary.pendingPoints,
          'available_points': dashboard.summary.availablePoints,
          'expiring_soon_points': dashboard.summary.expiringSoonPoints,
          'next_expiry_at': dashboard.summary.nextExpiryAt?.toIso8601String(),
          'synced_at': syncedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _replaceUserRows(
        txn,
        table: WellnessRewardOfferCacheTable.tableName,
        userId: normalizedUserId,
        rows: dashboard.offers.map(
          (offer) => {
            'id': offer.id,
            'user_id': normalizedUserId,
            'title': offer.title,
            'description': offer.description,
            'provider_name': offer.providerName,
            'cost_points': offer.costPoints,
            'available_codes': offer.availableCodes,
            'eligible_plan_codes': jsonEncode(offer.eligiblePlanCodes),
            'available_from': offer.availableFrom?.toIso8601String(),
            'available_until': offer.availableUntil?.toIso8601String(),
            'voucher_expires_at': offer.voucherExpiresAt?.toIso8601String(),
            'is_active': offer.isActive ? 1 : 0,
            'synced_at': syncedAt,
          },
        ),
      );
      await _replaceUserRows(
        txn,
        table: WellnessRewardPointHistoryCacheTable.tableName,
        userId: normalizedUserId,
        rows: dashboard.pointHistory.map(
          (entry) => {
            'id': entry.id,
            'user_id': normalizedUserId,
            'points_delta': entry.pointsDelta,
            'event_type': entry.eventType,
            'status': entry.status,
            'title': entry.title,
            'is_redeemable': entry.isRedeemable ? 1 : 0,
            'available_at': entry.availableAt?.toIso8601String(),
            'expires_at': entry.expiresAt?.toIso8601String(),
            'created_at': entry.createdAt?.toIso8601String(),
            'synced_at': syncedAt,
          },
        ),
      );
      await _replaceUserRows(
        txn,
        table: WellnessRewardRedemptionCacheTable.tableName,
        userId: normalizedUserId,
        rows: dashboard.redemptions.map(
          (entry) => _redemptionMap(
            userId: normalizedUserId,
            redemption: entry,
            syncedAt: syncedAt,
          ),
        ),
      );
    });
  }

  Future<void> upsertRedemption({
    required String userId,
    required WellnessRewardRedemption redemption,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || redemption.id.isEmpty) return;
    final db = await _db();
    await db.insert(
      WellnessRewardRedemptionCacheTable.tableName,
      _redemptionMap(
        userId: normalizedUserId,
        redemption: redemption,
        syncedAt: DateTime.now().toUtc().toIso8601String(),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _replaceUserRows(
    DatabaseExecutor txn, {
    required String table,
    required String userId,
    required Iterable<Map<String, Object?>> rows,
  }) async {
    await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
    final batch = txn.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _redemptionMap({
    required String userId,
    required WellnessRewardRedemption redemption,
    required String syncedAt,
  }) {
    // Mã voucher không bao giờ được ghi vào SQLite; mã thật chỉ nằm ở vùng
    // bảo mật của hệ điều hành và được đọc lại qua RPC riêng tư.
    return {
      'id': redemption.id,
      'user_id': userId,
      'offer_id': redemption.offerId,
      'title': redemption.title,
      'provider_name': redemption.providerName,
      'points_spent': redemption.pointsSpent,
      'status': redemption.status,
      'voucher_expires_at': redemption.voucherExpiresAt?.toIso8601String(),
      'created_at': redemption.createdAt?.toIso8601String(),
      'cancelled_at': redemption.cancelledAt?.toIso8601String(),
      'synced_at': syncedAt,
    };
  }
}

List<String> _decodeStringList(Object? value) {
  try {
    final decoded = jsonDecode(value?.toString() ?? '[]');
    if (decoded is! List) return const [];
    return decoded
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}
