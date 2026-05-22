// lib/features/dashboard/domain/entities/dashboard_entity.dart
class DashboardEntity {
  final int userId;

  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final int birthYear;

  final String occupation;
  final double heightCm;
  final double weightKg;
  final double bmi;

  final List<String> goals;
  final List<String> conditions;
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

  final Map<String, String> surveyAnswers;

  const DashboardEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthYear,
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.goals,
    required this.conditions,
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
    required this.surveyAnswers,
  });
}