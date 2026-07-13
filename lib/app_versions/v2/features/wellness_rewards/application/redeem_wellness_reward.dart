import '../domain/entities/wellness_reward_models.dart';
import '../domain/repositories/wellness_rewards_repository.dart';

class RedeemWellnessReward {
  final WellnessRewardsRepository repository;

  const RedeemWellnessReward({required this.repository});

  Future<WellnessRewardRedemption> execute({
    required String offerId,
    required String idempotencyKey,
  }) {
    return repository.redeemOffer(
      offerId: offerId,
      idempotencyKey: idempotencyKey,
    );
  }
}
