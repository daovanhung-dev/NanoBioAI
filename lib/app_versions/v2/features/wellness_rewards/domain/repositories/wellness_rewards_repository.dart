import '../entities/wellness_reward_models.dart';

abstract class WellnessRewardsRepository {
  Future<WellnessRewardsDashboard> loadDashboard();

  Future<WellnessRewardRedemption> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  });

  Future<String?> loadVoucherCode(String redemptionId);
}
