class NabiHealthConditionReviewItem {
  final String id;
  final String code;
  final String name;

  const NabiHealthConditionReviewItem({
    required this.id,
    required this.code,
    required this.name,
  });
}

class NabiGoalReviewSnapshot {
  final Set<String> onboardingGoalCodes;

  const NabiGoalReviewSnapshot({required this.onboardingGoalCodes});
}

class NabiMutableProfileSnapshot {
  final String occupation;
  final double? heightCm;
  final double? weightKg;
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;

  const NabiMutableProfileSnapshot({
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
  });
}
