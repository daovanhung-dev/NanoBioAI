class FitnessTrainingProfileSnapshot {
  const FitnessTrainingProfileSnapshot({
    required this.userId,
    required this.fullName,
    required this.birthDate,
    required this.goals,
    required this.conditions,
    required this.foodRestrictions,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.activityLevel,
    required this.sleepTime,
    required this.wakeTime,
    required this.mealTimes,
    required this.workoutTime,
  });

  final String userId;
  final String fullName;
  final DateTime? birthDate;
  final List<String> goals;
  final List<String> conditions;
  final List<String> foodRestrictions;
  final double? heightCm;
  final double? weightKg;
  final String gender;
  final String activityLevel;
  final String sleepTime;
  final String wakeTime;
  final List<String> mealTimes;
  final String workoutTime;
}
