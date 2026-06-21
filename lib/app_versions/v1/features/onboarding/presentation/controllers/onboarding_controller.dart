import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/services/supabase/auth/auth_profile_service.dart';

import '../../domain/entities/onboarding_entity.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../providers/onboarding_completion_provider.dart';
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
  static const _tag = 'ONBOARDING';
  DateTime? _startTime;

  @override
  OnboardingState build() {
    _startTime = DateTime.now();
    AppLogger.info(_tag, 'Controller initialized');
    Future.microtask(
      () => const AuthProfileService().markOnboardingInProgress(),
    );
    return const OnboardingState();
  }

  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);

  void nextStep() {
    if (state.currentStep >= OnboardingCatalog.totalSteps - 1) {
      AppLogger.warning(_tag, 'Next Button Clicked - Already at final step');
      return;
    }

    final oldStep = state.currentStep;
    final newStep = state.currentStep + 1;

    AppLogger.action(_tag, 'Next Button Clicked');
    AppLogger.navigation(_tag, _stepName(oldStep), _stepName(newStep));

    state = state.copyWith(currentStep: newStep);

    AppLogger.info(
      _tag,
      'Entered Step ${newStep + 1} - ${_stepTitle(newStep)}',
    );
  }

  void previousStep() {
    if (state.currentStep <= 0) {
      AppLogger.warning(_tag, 'Back Button Clicked - Already at first step');
      return;
    }

    final oldStep = state.currentStep;
    final newStep = state.currentStep - 1;

    AppLogger.action(_tag, 'Back Button Clicked');
    AppLogger.navigation(_tag, _stepName(oldStep), _stepName(newStep));

    state = state.copyWith(currentStep: newStep);

    AppLogger.info(
      _tag,
      'Entered Step ${newStep + 1} - ${_stepTitle(newStep)}',
    );
  }

  void goToStep(int step) {
    final safeStep = step.clamp(0, OnboardingCatalog.totalSteps - 1);
    final oldStep = state.currentStep;

    AppLogger.action(_tag, 'Jump to Step ${safeStep + 1}');
    AppLogger.navigation(_tag, _stepName(oldStep), _stepName(safeStep));

    state = state.copyWith(currentStep: safeStep);

    AppLogger.info(
      _tag,
      'Entered Step ${safeStep + 1} - ${_stepTitle(safeStep)}',
    );
  }

  String _stepName(int step) {
    return 'OnboardingStep${step + 1}';
  }

  String _stepTitle(int step) {
    const titles = [
      'Welcome',
      'Personal Information',
      'Health Goals',
      'Health Conditions',
      'Lifestyle Habits',
      'Extras (Allergy & Treatment)',
      'Consent & Disclaimer',
      'Review & Submit',
    ];
    return titles[step];
  }

  void updateEmail(String value) {
    AppLogger.form(_tag, 'email', value);
    state = state.copyWith(email: value);
  }

  void updatePhone(String value) {
    AppLogger.form(_tag, 'phone', value);
    state = state.copyWith(phone: value);
  }

  void updateFullName(String value) {
    AppLogger.form(_tag, 'fullName', value);
    state = state.copyWith(fullName: value);
  }

  void updateGender(String value) {
    AppLogger.form(_tag, 'gender', value);
    state = state.copyWith(gender: value);
  }

  void updateBirthYear(String value) {
    final year = int.tryParse(value) ?? state.birthYear;
    AppLogger.form(_tag, 'birthYear', year);
    state = state.copyWith(birthYear: year);
  }

  void updateOccupation(String value) {
    AppLogger.form(_tag, 'occupation', value);
    state = state.copyWith(occupation: value);
  }

  void updateHeight(String value) {
    final height = double.tryParse(value) ?? state.heightCm;
    AppLogger.form(_tag, 'heightCm', height);
    state = state.copyWith(heightCm: height);
  }

  void updateWeight(String value) {
    final weight = double.tryParse(value) ?? state.weightKg;
    AppLogger.form(_tag, 'weightKg', weight);
    AppLogger.info(_tag, 'BMI calculated: ${state.bmi.toStringAsFixed(2)}');
    state = state.copyWith(weightKg: weight);
  }

  void updateOtherGoal(String value) {
    AppLogger.form(_tag, 'otherGoal', value);
    state = state.copyWith(otherGoal: value);
  }

  void updateOtherCondition(String value) {
    AppLogger.form(_tag, 'otherCondition', value);
    state = state.copyWith(otherCondition: value);
  }

  void updateSleepQuality(String value) {
    AppLogger.form(_tag, 'sleepQuality', value);
    state = state.copyWith(sleepQuality: value);
  }

  void updateActivityLevel(String value) {
    AppLogger.form(_tag, 'activityLevel', value);
    state = state.copyWith(activityLevel: value);
  }

  void updateWaterPerDay(String value) {
    AppLogger.form(_tag, 'waterPerDay', value);
    state = state.copyWith(waterPerDay: value);
  }

  void updateAllergyName(String value) {
    AppLogger.form(_tag, 'allergyName', value);
    state = state.copyWith(allergyName: value);
  }

  void updateAllergyNote(String value) {
    AppLogger.form(_tag, 'allergyNote', value);
    state = state.copyWith(allergyNote: value);
  }

  void updateTreatmentName(String value) {
    AppLogger.form(_tag, 'treatmentName', value);
    state = state.copyWith(treatmentName: value);
  }

  void updateMedicationName(String value) {
    AppLogger.form(_tag, 'medicationName', value);
    state = state.copyWith(medicationName: value);
  }

  void updateTreatmentNote(String value) {
    AppLogger.form(_tag, 'treatmentNote', value);
    state = state.copyWith(treatmentNote: value);
  }

  void updateConcernText(String value) {
    AppLogger.form(_tag, 'concernText', value);
    state = state.copyWith(concernText: value);
  }

  void setAgreed(bool value) {
    AppLogger.form(_tag, 'agreed', value);
    state = state.copyWith(agreed: value);
  }

  void toggleGoal(String code) {
    final items = [...state.goals];
    final action = items.contains(code) ? 'removed' : 'added';

    if (items.contains(code)) {
      items.remove(code);
    } else {
      items.add(code);
    }

    AppLogger.form(_tag, 'selectedGoals', items);
    AppLogger.info(_tag, 'Goal "$code" $action');

    state = state.copyWith(goals: items);
  }

  void toggleCondition(String code) {
    final items = [...state.conditions];
    final action = items.contains(code) ? 'removed' : 'added';

    if (items.contains(code)) {
      items.remove(code);
    } else {
      items.add(code);
    }

    AppLogger.form(_tag, 'selectedConditions', items);
    AppLogger.info(_tag, 'Condition "$code" $action');

    state = state.copyWith(conditions: items);
  }

  void toggleHabit(String code) {
    final items = [...state.habits];
    final action = items.contains(code) ? 'removed' : 'added';

    if (items.contains(code)) {
      items.remove(code);
    } else {
      items.add(code);
    }

    AppLogger.form(_tag, 'selectedHabits', items);
    AppLogger.info(_tag, 'Habit "$code" $action');

    state = state.copyWith(habits: items);
  }

  Future<void> saveOnboarding() async {
    AppLogger.separator(_tag);
    AppLogger.action(_tag, 'Submit Button Clicked');

    // Validation checks
    if (!state.agreed) {
      AppLogger.validation(
        _tag,
        'Terms Agreement',
        false,
        reason: 'User must agree to terms',
      );

      AppLogger.error(
        _tag,
        'Onboarding Completed With Error',
        StateError(
          'Bạn cần đồng ý với điều khoản để mình có thể tiếp tục đồng hành cùng bạn.',
        ),
      );

      throw StateError(
        'Bạn cần đồng ý với điều khoản để mình có thể tiếp tục đồng hành cùng bạn.',
      );
    }

    AppLogger.validation(_tag, 'Terms Agreement', true);

    if (!state.canSave) {
      AppLogger.validation(
        _tag,
        'Required Fields',
        false,
        reason: 'Missing required fields',
      );

      final missingFields = <String>[];
      if (state.fullName.trim().isEmpty) missingFields.add('fullName');
      if (state.gender.trim().isEmpty) missingFields.add('gender');
      if (state.birthYear <= 1900) missingFields.add('birthYear');
      if (state.occupation.trim().isEmpty) missingFields.add('occupation');

      AppLogger.info(_tag, 'Missing fields: ${missingFields.join(', ')}');

      AppLogger.error(
        _tag,
        'Onboarding Completed With Error',
        StateError(
          'Mình vẫn còn thiếu vài thông tin bắt buộc. Bạn kiểm tra lại giúp mình nhé.',
        ),
      );

      throw StateError(
        'Mình vẫn còn thiếu vài thông tin bắt buộc. Bạn kiểm tra lại giúp mình nhé.',
      );
    }

    AppLogger.validation(_tag, 'Required Fields', true);

    if (state.isSaving) {
      AppLogger.warning(
        _tag,
        'Save already in progress, ignoring duplicate call',
      );
      return;
    }

    AppLogger.info(_tag, 'Starting onboarding save process...');
    state = state.copyWith(isSaving: true);

    try {
      // Log the data being saved
      final entity = state.toEntity();
      AppLogger.info(_tag, 'Saving onboarding profile...');
      AppLogger.info(_tag, 'User: ${entity.fullName} (${entity.email})');
      AppLogger.info(_tag, 'BMI: ${entity.bmi.toStringAsFixed(2)}');
      AppLogger.info(_tag, 'Goals: ${entity.goals.length} selected');
      AppLogger.info(_tag, 'Conditions: ${entity.conditions.length} selected');
      AppLogger.info(_tag, 'Habits: ${entity.habits.length} selected');

      await _repository.save(entity);
      AppLogger.success(_tag, 'Onboarding profile saved successfully');

      AppLogger.info(_tag, 'Generating onboarding meal plan and daily tasks');
      final onCompletionCallback = ref.read(
        onboardingCompletionCallbackProvider,
      );
      var generatedPlan = false;
      try {
        await onCompletionCallback();
        generatedPlan = true;
      } on DashboardGenerationAuthRequiredException catch (error) {
        AppLogger.info(_tag, 'Skip generated plan: $error');
      }

      AppLogger.info(_tag, 'Setting onboarding completed flag');
      await AppPrefs.setOnboardingCompleted(true);
      AppLogger.success(_tag, 'Onboarding completed flag set');

      state = state.copyWith(
        isSaving: false,
        savedLog: 'Mình đã lưu hồ sơ sức khỏe của bạn thành công.',
      );

      // Log completion summary
      final duration = DateTime.now().difference(_startTime!);
      AppLogger.separator(_tag);
      AppLogger.success(_tag, 'Onboarding Completed Successfully');

      AppLogger.summary(_tag, 'ONBOARDING_SUMMARY', {
        'Total Steps': OnboardingCatalog.totalSteps,
        'Completed Steps': OnboardingCatalog.totalSteps,
        'Duration': '${duration.inMinutes}m ${duration.inSeconds % 60}s',
        'User ID': entity.email.isNotEmpty ? entity.email : entity.phone,
        'Goals Count': entity.goals.length,
        'Conditions Count': entity.conditions.length,
        'Habits Count': entity.habits.length,
        'Has Allergy': entity.hasAllergy,
        'Has Treatment': entity.hasTreatment,
        'Saved To Database': true,
        'Meal Plan Generated': generatedPlan,
        'Daily Health Tasks Generated': generatedPlan,
      });
      AppLogger.separator(_tag);
    } catch (e, st) {
      AppLogger.error(_tag, 'Save onboarding failed', e, st);

      final message = e is AIOverloadedException
          ? AIOverloadedException.userMessage
          : 'Mình chưa thể lưu hồ sơ lúc này: $e';

      state = state.copyWith(isSaving: false, savedLog: message);

      AppLogger.separator(_tag);
      AppLogger.error(_tag, 'Onboarding Completed With Error', e);
      AppLogger.summary(_tag, 'ONBOARDING_SUMMARY', {
        'Status': 'Failed',
        'Error': e.toString(),
        'Saved To Database': false,
      });
      AppLogger.separator(_tag);

      rethrow;
    }
  }
}
