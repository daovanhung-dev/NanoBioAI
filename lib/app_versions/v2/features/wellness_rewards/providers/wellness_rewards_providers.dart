import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/load_wellness_rewards.dart';
import '../application/redeem_wellness_reward.dart';
import '../data/datasources/wellness_rewards_remote_datasource.dart';
import '../data/datasources/wellness_rewards_local_datasource.dart';
import '../data/datasources/wellness_voucher_secure_store.dart';
import '../data/repositories/supabase_wellness_rewards_repository.dart';
import '../domain/entities/wellness_reward_models.dart';
import '../domain/repositories/wellness_rewards_repository.dart';

final wellnessRewardsRemoteDatasourceProvider =
    Provider<WellnessRewardsRemoteDatasource>((ref) {
      return const SupabaseWellnessRewardsRemoteDatasource();
    });

final wellnessVoucherSecureStoreProvider = Provider<WellnessVoucherSecureStore>(
  (ref) => const OsWellnessVoucherSecureStore(),
);

final wellnessRewardsLocalDatasourceProvider =
    Provider<WellnessRewardsLocalDatasource>((ref) {
      return const WellnessRewardsLocalDatasource();
    });

final wellnessRewardsUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final wellnessRewardsRepositoryProvider = Provider<WellnessRewardsRepository>((
  ref,
) {
  return SupabaseWellnessRewardsRepository(
    remoteDatasource: ref.watch(wellnessRewardsRemoteDatasourceProvider),
    localDatasource: ref.watch(wellnessRewardsLocalDatasourceProvider),
    currentUserId: () => ref.read(wellnessRewardsUserIdProvider),
  );
});

final loadWellnessRewardsProvider = Provider<LoadWellnessRewards>((ref) {
  return LoadWellnessRewards(
    repository: ref.watch(wellnessRewardsRepositoryProvider),
  );
});

final redeemWellnessRewardProvider = Provider<RedeemWellnessReward>((ref) {
  return RedeemWellnessReward(
    repository: ref.watch(wellnessRewardsRepositoryProvider),
  );
});

final wellnessRewardsControllerProvider =
    AsyncNotifierProvider<WellnessRewardsController, WellnessRewardsDashboard>(
      WellnessRewardsController.new,
    );

class WellnessRewardsController
    extends AsyncNotifier<WellnessRewardsDashboard> {
  final Set<String> _redeemingOfferIds = <String>{};

  @override
  Future<WellnessRewardsDashboard> build() {
    return ref.read(loadWellnessRewardsProvider).execute();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(loadWellnessRewardsProvider).execute(),
    );
  }

  Future<WellnessRewardRedemption> redeem(String offerId) async {
    if (!_redeemingOfferIds.add(offerId)) {
      throw WellnessRewardException.fromCode('duplicate_request');
    }
    try {
      final userId = ref.read(wellnessRewardsUserIdProvider)?.trim();
      if (userId == null || userId.isEmpty) {
        throw WellnessRewardException.fromCode('auth_required');
      }
      final secureStore = ref.read(wellnessVoucherSecureStoreProvider);
      late final String idempotencyKey;
      try {
        idempotencyKey =
            await secureStore.readPendingRedemptionKey(
              userId: userId,
              offerId: offerId,
            ) ??
            'reward-$offerId-${DateTime.now().microsecondsSinceEpoch}';
        await secureStore.writePendingRedemptionKey(
          userId: userId,
          offerId: offerId,
          idempotencyKey: idempotencyKey,
        );
      } catch (_) {
        throw WellnessRewardException.fromCode('secure_storage_unavailable');
      }
      final redemption = await ref
          .read(redeemWellnessRewardProvider)
          .execute(offerId: offerId, idempotencyKey: idempotencyKey);
      await _cacheVoucherCode(redemption);
      try {
        await secureStore.deletePendingRedemptionKey(
          userId: userId,
          offerId: offerId,
        );
      } catch (_) {
        // Giữ khóa cũ là an toàn: lần thử sau chỉ replay, không trừ điểm lần hai.
      }
      try {
        final refreshed = await ref.read(loadWellnessRewardsProvider).execute();
        state = AsyncData(refreshed);
      } catch (_) {
        // Đổi điểm đã thành công; giữ trạng thái hiện tại để không báo lỗi giả.
      }
      return redemption;
    } finally {
      _redeemingOfferIds.remove(offerId);
    }
  }

  Future<String?> loadVoucherCode(String redemptionId) async {
    final userId = ref.read(wellnessRewardsUserIdProvider);
    if (userId == null || userId.isEmpty) {
      throw WellnessRewardException.fromCode('auth_required');
    }

    final secureStore = ref.read(wellnessVoucherSecureStoreProvider);
    String? cached;
    try {
      cached = await secureStore.readCode(
        userId: userId,
        redemptionId: redemptionId,
      );
    } catch (_) {
      // Vẫn có thể tải mã riêng tư từ máy chủ khi vùng bảo mật tạm lỗi.
    }
    if (cached != null) return cached;

    final code = await ref
        .read(wellnessRewardsRepositoryProvider)
        .loadVoucherCode(redemptionId);
    if (code != null && code.isNotEmpty) {
      try {
        await secureStore.writeCode(
          userId: userId,
          redemptionId: redemptionId,
          code: code,
        );
      } catch (_) {
        // Không làm mất mã vừa tải chỉ vì bộ nhớ bảo mật đang gián đoạn.
      }
    }
    return code;
  }

  Future<void> _cacheVoucherCode(WellnessRewardRedemption redemption) async {
    final code = redemption.voucherCode;
    final userId = ref.read(wellnessRewardsUserIdProvider);
    if (code == null || code.isEmpty || userId == null || userId.isEmpty) {
      return;
    }
    try {
      await ref
          .read(wellnessVoucherSecureStoreProvider)
          .writeCode(userId: userId, redemptionId: redemption.id, code: code);
    } catch (_) {
      // Giao dịch máy chủ đã thành công; lỗi lưu cục bộ không được báo đổi thất bại.
    }
  }
}
