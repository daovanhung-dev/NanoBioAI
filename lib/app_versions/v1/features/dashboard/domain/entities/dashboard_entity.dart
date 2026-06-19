// lib/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart
import 'package:nano_app/core/interfaces/health_data_interface.dart';

class DashboardEntity implements HealthDataInterface {
  final int userId;

  @override
  final String fullName;
  final String email;
  final String phone;
  @override
  final String gender;
  @override
  final int birthYear;
  final String subscriptionTier;

  final String occupation;
  @override
  final double heightCm;
  @override
  final double weightKg;
  @override
  final double bmi;

  @override
  final List<String> goals;
  @override
  final List<String> conditions;
  @override
  final List<String> habits;

  @override
  final String sleepQuality;
  @override
  final String activityLevel;
  @override
  final String waterPerDay;

  @override
  final String allergyName;
  @override
  final String allergyNote;

  @override
  final String treatmentName;
  @override
  final String medicationName;
  @override
  final String treatmentNote;

  @override
  final String concernText;

  final Map<String, String> surveyAnswers;

  const DashboardEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthYear,
    this.subscriptionTier = 'free',
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
