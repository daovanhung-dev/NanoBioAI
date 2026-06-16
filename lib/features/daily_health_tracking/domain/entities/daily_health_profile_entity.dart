class DailyHealthProfileEntity {
  final String userId;
  final String fullName;
  final List<String> goals;
  final List<String> conditions;
  final List<String> habits;
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;

  const DailyHealthProfileEntity({
    required this.userId,
    required this.fullName,
    required this.goals,
    required this.conditions,
    required this.habits,
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
  });
}
