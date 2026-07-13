import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/wellness_reward_models.dart';
import '../../domain/repositories/wellness_rewards_repository.dart';
import '../datasources/wellness_rewards_remote_datasource.dart';
import '../datasources/wellness_rewards_local_datasource.dart';

class SupabaseWellnessRewardsRepository implements WellnessRewardsRepository {
  final WellnessRewardsRemoteDatasource remoteDatasource;
  final WellnessRewardsLocalDatasource localDatasource;
  final String? Function() currentUserId;

  const SupabaseWellnessRewardsRepository({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.currentUserId,
  });

  @override
  Future<WellnessRewardsDashboard> loadDashboard() async {
    try {
      final results = await Future.wait<Object>([
        remoteDatasource.getSummary(),
        remoteDatasource.listOffers(),
        remoteDatasource.listPointHistory(),
        remoteDatasource.listRedemptions(),
      ]);

      final summary = WellnessRewardSummary.fromMap(
        results[0] as Map<String, Object?>,
      );
      final offers = (results[1] as List<Map<String, Object?>>)
          .map(WellnessRewardOffer.fromMap)
          .where((offer) => offer.id.isNotEmpty && offer.isActive)
          .toList(growable: false);
      final history = (results[2] as List<Map<String, Object?>>)
          .map(WellnessPointHistoryEntry.fromMap)
          .where((entry) => entry.id.isNotEmpty)
          .toList(growable: false);
      final redemptions = (results[3] as List<Map<String, Object?>>)
          .map(WellnessRewardRedemption.fromMap)
          .where((entry) => entry.id.isNotEmpty)
          .toList(growable: false);

      final dashboard = WellnessRewardsDashboard(
        summary: summary,
        offers: offers,
        pointHistory: history,
        redemptions: redemptions,
      );
      final userId = currentUserId();
      if (userId != null && userId.isNotEmpty) {
        try {
          await localDatasource.replaceDashboard(
            userId: userId,
            dashboard: dashboard,
          );
        } catch (_) {
          // Cache cục bộ không được làm hỏng dữ liệu máy chủ vừa tải.
        }
      }
      return dashboard;
    } on WellnessRewardException {
      rethrow;
    } on AuthException {
      throw WellnessRewardException.fromCode('auth_required');
    } on PostgrestException catch (error) {
      return _cachedOrThrow(_safePostgrestError(error));
    } catch (_) {
      return _cachedOrThrow(WellnessRewardException.fromCode('unknown'));
    }
  }

  @override
  Future<WellnessRewardRedemption> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  }) async {
    if (offerId.trim().isEmpty || idempotencyKey.trim().isEmpty) {
      throw WellnessRewardException.fromCode('offer_unavailable');
    }
    try {
      final map = await remoteDatasource.redeemOffer(
        offerId: offerId,
        idempotencyKey: idempotencyKey,
      );
      final success = map['success'];
      if (success == false || success?.toString().toLowerCase() == 'false') {
        throw WellnessRewardException.fromCode(map['error_code']);
      }
      final redemption = WellnessRewardRedemption.fromMap(map);
      if (redemption.id.isEmpty) {
        throw WellnessRewardException.fromCode(map['error_code']);
      }
      final userId = currentUserId();
      if (userId != null && userId.isNotEmpty) {
        try {
          await localDatasource.upsertRedemption(
            userId: userId,
            redemption: redemption,
          );
        } catch (_) {
          // Giao dịch máy chủ đã thành công; cache chỉ là projection đọc.
        }
      }
      return redemption;
    } on WellnessRewardException {
      rethrow;
    } on AuthException {
      throw WellnessRewardException.fromCode('auth_required');
    } on PostgrestException catch (error) {
      throw _safePostgrestError(error);
    } catch (_) {
      throw WellnessRewardException.fromCode('unknown');
    }
  }

  @override
  Future<String?> loadVoucherCode(String redemptionId) async {
    try {
      return await remoteDatasource.getVoucherCode(redemptionId);
    } on AuthException {
      throw WellnessRewardException.fromCode('auth_required');
    } on PostgrestException catch (error) {
      throw _safePostgrestError(error);
    } catch (_) {
      throw WellnessRewardException.fromCode('unknown');
    }
  }

  Future<WellnessRewardsDashboard> _cachedOrThrow(
    WellnessRewardException error,
  ) async {
    final userId = currentUserId();
    if (userId != null && userId.isNotEmpty && error.code == 'unknown') {
      try {
        final cached = await localDatasource.loadDashboard(userId);
        if (cached != null) return cached;
      } catch (_) {
        // Giữ thông báo tiếng Việt an toàn từ lỗi gốc.
      }
    }
    throw error;
  }
}

WellnessRewardException _safePostgrestError(PostgrestException error) {
  final candidates = <String>[
    error.message,
    error.details?.toString() ?? '',
    error.hint?.toString() ?? '',
    error.code?.toString() ?? '',
  ];
  const codes = <String>{
    'auth_required',
    'member_account_required',
    'insufficient_points',
    'offer_out_of_stock',
    'out_of_stock',
    'offer_ineligible',
    'offer_unavailable',
    'offer_expired',
    'offer_not_found',
    'offer_required',
    'offer_window_invalid',
    'redemption_not_found',
    'redemption_required',
    'wellness_rewards_disabled',
    'reward_program_invalid',
    'reward_program_not_configured',
    'duplicate_request',
    'idempotency_conflict',
  };
  for (final candidate in candidates) {
    final normalized = candidate.trim().toLowerCase();
    for (final code in codes) {
      if (normalized == code || normalized.contains(code)) {
        return WellnessRewardException.fromCode(code);
      }
    }
  }
  return WellnessRewardException.fromCode('unknown');
}
