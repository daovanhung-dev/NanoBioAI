import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/features/dashboard/presentation/controllers/dashboard_controller.dart';

import '../../domain/entities/onboarding_entity.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../providers/repository_providers.dart';

class OnboardingState {
  final int currentStep;
  final bool isSaving;
  final String? savedLog;

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

  const OnboardingState({
    this.currentStep = 0,
    this.isSaving = false,
    this.savedLog,
    this.email = '',
    this.phone = '',
    this.fullName = '',
    this.gender = '',
    this.birthYear = 2000,
    this.occupation = '',
    this.heightCm = 170,
    this.weightKg = 65,
    this.goals = const [],
    this.otherGoal = '',
    this.conditions = const [],
    this.otherCondition = '',
    this.habits = const [],
    this.sleepQuality = 'Ngủ ngon',
    this.activityLevel = 'Ít vận động',
    this.waterPerDay = 'Dưới 1 lít nước/ngày',
    this.allergyName = '',
    this.allergyNote = '',
    this.treatmentName = '',
    this.medicationName = '',
    this.treatmentNote = '',
    this.concernText = '',
    this.agreed = false,
  });

  double get bmi {
    final heightMeter = heightCm / 100.0;
    if (heightMeter <= 0) return 0;
    return weightKg / (heightMeter * heightMeter);
  }

  bool get canSave =>
      fullName.trim().isNotEmpty &&
      gender.trim().isNotEmpty &&
      birthYear > 1900 &&
      occupation.trim().isNotEmpty &&
      agreed;

  OnboardingEntity toEntity() {
    return OnboardingEntity(
      email: email.trim(),
      phone: phone.trim(),
      fullName: fullName.trim(),
      gender: gender.trim(),
      birthYear: birthYear,
      occupation: occupation.trim(),
      heightCm: heightCm,
      weightKg: weightKg,
      goals: goals,
      otherGoal: otherGoal.trim(),
      conditions: conditions,
      otherCondition: otherCondition.trim(),
      habits: habits,
      sleepQuality: sleepQuality,
      activityLevel: activityLevel,
      waterPerDay: waterPerDay,
      allergyName: allergyName.trim(),
      allergyNote: allergyNote.trim(),
      treatmentName: treatmentName.trim(),
      medicationName: medicationName.trim(),
      treatmentNote: treatmentNote.trim(),
      concernText: concernText.trim(),
      agreed: agreed,
    );
  }

  OnboardingState copyWith({
    int? currentStep,
    bool? isSaving,
    String? savedLog,
    String? email,
    String? phone,
    String? fullName,
    String? gender,
    int? birthYear,
    String? occupation,
    double? heightCm,
    double? weightKg,
    List<String>? goals,
    String? otherGoal,
    List<String>? conditions,
    String? otherCondition,
    List<String>? habits,
    String? sleepQuality,
    String? activityLevel,
    String? waterPerDay,
    String? allergyName,
    String? allergyNote,
    String? treatmentName,
    String? medicationName,
    String? treatmentNote,
    String? concernText,
    bool? agreed,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isSaving: isSaving ?? this.isSaving,
      savedLog: savedLog ?? this.savedLog,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      occupation: occupation ?? this.occupation,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goals: goals ?? this.goals,
      otherGoal: otherGoal ?? this.otherGoal,
      conditions: conditions ?? this.conditions,
      otherCondition: otherCondition ?? this.otherCondition,
      habits: habits ?? this.habits,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      activityLevel: activityLevel ?? this.activityLevel,
      waterPerDay: waterPerDay ?? this.waterPerDay,
      allergyName: allergyName ?? this.allergyName,
      allergyNote: allergyNote ?? this.allergyNote,
      treatmentName: treatmentName ?? this.treatmentName,
      medicationName: medicationName ?? this.medicationName,
      treatmentNote: treatmentNote ?? this.treatmentNote,
      concernText: concernText ?? this.concernText,
      agreed: agreed ?? this.agreed,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);

  void nextStep() {
    if (state.currentStep >= 6) return;
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep <= 0) return;
    state = state.copyWith(currentStep: state.currentStep - 1);
  }

  void goToStep(int step) {
    final safeStep = step.clamp(0, 6);
    state = state.copyWith(currentStep: safeStep);
  }

  void updateEmail(String value) => state = state.copyWith(email: value);
  void updatePhone(String value) => state = state.copyWith(phone: value);
  void updateFullName(String value) => state = state.copyWith(fullName: value);

  void updateGender(String value) {
    state = state.copyWith(gender: value);
  }

  void updateBirthYear(String value) {
    state = state.copyWith(birthYear: int.tryParse(value) ?? state.birthYear);
  }

  void updateOccupation(String value) =>
      state = state.copyWith(occupation: value);

  void updateHeight(String value) {
    state = state.copyWith(heightCm: double.tryParse(value) ?? state.heightCm);
  }

  void updateWeight(String value) {
    state = state.copyWith(weightKg: double.tryParse(value) ?? state.weightKg);
  }

  void updateOtherGoal(String value) =>
      state = state.copyWith(otherGoal: value);
  void updateOtherCondition(String value) =>
      state = state.copyWith(otherCondition: value);

  void updateSleepQuality(String value) =>
      state = state.copyWith(sleepQuality: value);
  void updateActivityLevel(String value) =>
      state = state.copyWith(activityLevel: value);
  void updateWaterPerDay(String value) =>
      state = state.copyWith(waterPerDay: value);

  void updateAllergyName(String value) =>
      state = state.copyWith(allergyName: value);
  void updateAllergyNote(String value) =>
      state = state.copyWith(allergyNote: value);
  void updateTreatmentName(String value) =>
      state = state.copyWith(treatmentName: value);
  void updateMedicationName(String value) =>
      state = state.copyWith(medicationName: value);
  void updateTreatmentNote(String value) =>
      state = state.copyWith(treatmentNote: value);

  void updateConcernText(String value) =>
      state = state.copyWith(concernText: value);
  void setAgreed(bool value) => state = state.copyWith(agreed: value);

  void toggleGoal(String code) {
    final items = [...state.goals];
    if (items.contains(code)) {
      items.remove(code);
    } else {
      items.add(code);
    }
    state = state.copyWith(goals: items);
  }

  void toggleCondition(String code) {
    final items = [...state.conditions];
    if (items.contains(code)) {
      items.remove(code);
    } else {
      items.add(code);
    }
    state = state.copyWith(conditions: items);
  }

  void toggleHabit(String code) {
    final items = [...state.habits];
    if (items.contains(code)) {
      items.remove(code);
    } else {
      items.add(code);
    }
    state = state.copyWith(habits: items);
  }

  Future<void> saveOnboarding() async {
    if (!state.agreed) {
      throw StateError(
        'Bạn cần đồng ý với điều khoản để mình có thể tiếp tục đồng hành cùng bạn.',
      );
    }

    if (!state.canSave) {
      throw StateError(
        'Mình vẫn còn thiếu vài thông tin bắt buộc. Bạn kiểm tra lại giúp mình nhé.',
      );
    }

    if (state.isSaving) return;
    state = state.copyWith(isSaving: true);

    try {
      await _repository.save(state.toEntity());
      debugPrint('Generating the weekly meal plan');
      await ref.read(dashboardControllerProvider.notifier).genMealByWeeksToDB();
      await AppPrefs.setOnboardingCompleted(true);

      state = state.copyWith(
        isSaving: false,
        savedLog: 'Mình đã lưu hồ sơ sức khỏe của bạn thành công.',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        savedLog: 'Mình chưa thể lưu hồ sơ lúc này: $e',
      );
      rethrow;
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
