import '../entities/wellness_rank_summary.dart';

abstract interface class WellnessRankRepository {
  Future<WellnessRankSummary> loadSummary(String userId);
}
