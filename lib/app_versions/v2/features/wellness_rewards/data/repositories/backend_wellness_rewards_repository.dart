import 'package:nano_app/core/network/backend_api_client.dart';

import '../../domain/entities/wellness_reward_models.dart';
import '../../domain/repositories/wellness_rewards_repository.dart';
import '../datasources/wellness_rewards_remote_datasource.dart';
import '../datasources/wellness_rewards_local_datasource.dart';

class BackendWellnessRewardsRepository implements WellnessRewardsRepository {
  final WellnessRewardsRemoteDatasource remoteDatasource;
  final WellnessRewardsLocalDatasource localDatasource;
  final String? Function() currentUserId;

  const BackendWellnessRewardsRepository({
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
    } on BackendApiException catch (error) {
      if (error.businessCode == 'AUTH_REQUIRED') {
        throw WellnessRewardException.fromCode('auth_required');
      }
      return _cachedOrThrow(_safeBackendError(error));
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
          final ledgerId = map['point_ledger_id']?.toString().trim() ?? '';
          final availablePoints = _optionalInt(map['available_points']);
          if (ledgerId.isNotEmpty && availablePoints != null) {
            await localDatasource.applySuccessfulRedemption(
              userId: userId,
              redemption: redemption,
              pointHistory: WellnessPointHistoryEntry(
                id: ledgerId,
                pointsDelta: -redemption.pointsSpent,
                eventType: 'redemption',
                status: 'redeemed',
                title:
                    '${redemption.isPhysical ? 'Đổi quà' : 'Đổi ưu đãi'}: '
                    '${redemption.title}',
                isRedeemable: true,
                createdAt: redemption.createdAt,
              ),
              availablePoints: availablePoints,
            );
          } else {
            await localDatasource.upsertRedemption(
              userId: userId,
              redemption: redemption,
            );
          }
        } catch (_) {
          // Server ledger remains authoritative if the SQLite projection fails.
        }
      }
      return redemption;
    } on WellnessRewardException {
      rethrow;
    } on BackendApiException catch (error) {
      throw _safeBackendError(error);
    } catch (_) {
      throw WellnessRewardException.fromCode('unknown');
    }
  }

  @override
  Future<String?> loadVoucherCode(String redemptionId) async {
    try {
      return await remoteDatasource.getVoucherCode(redemptionId);
    } on BackendApiException catch (error) {
      throw _safeBackendError(error);
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

WellnessRewardException _safeBackendError(BackendApiException error) {
  final normalized = error.businessCode.toLowerCase();
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
    'reward_stock_invalid',
    'reward_type_invalid',
    'redemption_not_found',
    'redemption_required',
    'wellness_rewards_disabled',
    'reward_program_invalid',
    'reward_program_not_configured',
    'duplicate_request',
    'idempotency_conflict',
  };
  for (final code in codes) {
    if (normalized == code || normalized.contains(code)) {
      return WellnessRewardException.fromCode(code);
    }
  }
  return WellnessRewardException.fromCode('unknown');
}

int? _optionalInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
