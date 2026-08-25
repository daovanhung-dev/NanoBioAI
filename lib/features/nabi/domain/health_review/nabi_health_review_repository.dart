import 'nabi_health_review_models.dart';

abstract interface class NabiHealthReviewRepository {
  Future<List<NabiHealthConditionReviewItem>> loadConditions(String actorKey);

  Future<void> saveHealthCheckIn({
    required String actorKey,
    required String overallFeeling,
    required Map<String, String> conditionStatusById,
    required String note,
  });

  Future<NabiGoalReviewSnapshot> loadGoals(String actorKey);

  Future<void> replaceOnboardingGoals({
    required String actorKey,
    required Set<String> goalCodes,
  });

  Future<NabiMutableProfileSnapshot> loadMutableProfile(String actorKey);

  Future<void> updateMutableProfile({
    required String actorKey,
    required NabiMutableProfileSnapshot profile,
  });
}
