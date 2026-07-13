import '../domain/entities/wellness_reward_models.dart';
import '../domain/repositories/wellness_rewards_repository.dart';

class LoadWellnessRewards {
  final WellnessRewardsRepository repository;

  const LoadWellnessRewards({required this.repository});

  Future<WellnessRewardsDashboard> execute() => repository.loadDashboard();
}
