class OnboardingEntity {
  final int? id;
  final String email;
  final String phone;
  final String fullName;
  final String gender;
  final int birthYear;
  final String occupation;
  final double heightCm;
  final double weightKg;

  final List<String> goals;
  final String otherGoal;

  final List<String> conditions;
  final String otherCondition;

  final List<String> habits;

  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;

  final String allergyName;
  final String allergyNote;

  final String treatmentName;
  final String medicationName;
  final String treatmentNote;

  final String concernText;
  final bool agreed;

  const OnboardingEntity({
    this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.birthYear,
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.goals,
    required this.otherGoal,
    required this.conditions,
    required this.otherCondition,
    required this.habits,
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
    required this.allergyName,
    required this.allergyNote,
    required this.treatmentName,
    required this.medicationName,
    required this.treatmentNote,
    required this.concernText,
    required this.agreed,
  });

  double get bmi {
    final heightMeter = heightCm / 100.0;
    if (heightMeter <= 0) return 0;
    return weightKg / (heightMeter * heightMeter);
  }

  bool get hasAllergy => allergyName.trim().isNotEmpty;
  bool get hasTreatment =>
      treatmentName.trim().isNotEmpty ||
      medicationName.trim().isNotEmpty ||
      treatmentNote.trim().isNotEmpty;
}
