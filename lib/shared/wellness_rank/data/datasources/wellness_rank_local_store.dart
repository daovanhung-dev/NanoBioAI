import '../../domain/entities/wellness_rank_summary.dart';

abstract interface class WellnessRankLocalStore {
  Future<WellnessRankSummary?> load(String userId);

  Future<void> save(String userId, WellnessRankSummary summary);
}
