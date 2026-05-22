import '../../domain/entities/onboarding_entity.dart';

class OnboardingModel extends OnboardingEntity {
  const OnboardingModel({
    super.id,
    required super.email,
    required super.phone,
    required super.fullName,
    required super.gender,
    required super.birthYear,
    required super.occupation,
    required super.heightCm,
    required super.weightKg,
    required super.goals,
    required super.otherGoal,
    required super.conditions,
    required super.otherCondition,
    required super.habits,
    required super.sleepQuality,
    required super.activityLevel,
    required super.waterPerDay,
    required super.allergyName,
    required super.allergyNote,
    required super.treatmentName,
    required super.medicationName,
    required super.treatmentNote,
    required super.concernText,
    required super.agreed,
  });

  factory OnboardingModel.fromEntity(OnboardingEntity entity) {
    return OnboardingModel(
      id: entity.id,
      email: entity.email,
      phone: entity.phone,
      fullName: entity.fullName,
      gender: entity.gender,
      birthYear: entity.birthYear,
      occupation: entity.occupation,
      heightCm: entity.heightCm,
      weightKg: entity.weightKg,
      goals: entity.goals,
      otherGoal: entity.otherGoal,
      conditions: entity.conditions,
      otherCondition: entity.otherCondition,
      habits: entity.habits,
      sleepQuality: entity.sleepQuality,
      activityLevel: entity.activityLevel,
      waterPerDay: entity.waterPerDay,
      allergyName: entity.allergyName,
      allergyNote: entity.allergyNote,
      treatmentName: entity.treatmentName,
      medicationName: entity.medicationName,
      treatmentNote: entity.treatmentNote,
      concernText: entity.concernText,
      agreed: entity.agreed,
    );
  }
}
