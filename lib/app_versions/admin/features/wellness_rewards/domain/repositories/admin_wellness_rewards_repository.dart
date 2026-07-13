import '../entities/admin_wellness_reward_models.dart';

abstract class AdminWellnessRewardsRepository {
  Future<AdminWellnessRewardsSnapshot> load({String query = ''});

  Future<AdminRewardMutationResult> upsertOffer(
    AdminRewardOfferCommand command,
  );

  Future<AdminRewardMutationResult> importCodes(
    AdminRewardCodeImportCommand command,
  );

  Future<AdminRewardMutationResult> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  });
}
