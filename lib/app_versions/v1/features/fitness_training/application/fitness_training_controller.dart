import 'dart:math';

import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/basic_health_calculator_models.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/services/basic_health_calculator.dart';

import '../domain/entities/fitness_training_catalog.dart';
import '../domain/entities/fitness_training_profile.dart';
import '../domain/entities/fitness_training_program.dart';
import '../domain/repositories/fitness_training_profile_repository.dart';
import '../domain/services/fitness_training_age_gate.dart';
import 'fitness_training_service.dart';

class FitnessTrainingLoadedContext {
  const FitnessTrainingLoadedContext({
    required this.profile,
    required this.catalog,
    required this.programs,
  });

  final FitnessTrainingProfileSnapshot profile;
  final FitnessTrainingCatalog catalog;
  final List<FitnessTrainingProgram> programs;

  FitnessTrainingProgram? get activeProgram {
    for (final program in programs) {
      if (program.status == FitnessProgramStatus.active) return program;
    }
    return null;
  }

  FitnessTrainingProgram? get previewProgram {
    for (final program in programs) {
      if (program.status == FitnessProgramStatus.preview) return program;
    }
    return null;
  }
}

class FitnessTrainingController {
  const FitnessTrainingController({
    required this.service,
    required this.profileRepository,
    required this.currentUserId,
    this.now = DateTime.now,
  });

  final FitnessTrainingService service;
  final FitnessTrainingProfileRepository profileRepository;
  final String? Function() currentUserId;
  final DateTime Function() now;

  bool get isGuest => currentUserId() == null;

  Future<FitnessTrainingLoadedContext> load() async {
    final profile = await profileRepository.load(currentUserId());
    final catalog = await service.loadCatalog();
    final programs = await service.loadPrograms(profile.userId);
    return FitnessTrainingLoadedContext(
      profile: profile,
      catalog: catalog,
      programs: programs,
    );
  }

  Future<FitnessTrainingLoadedContext> saveBirthDate(DateTime birthDate) async {
    final profile = await profileRepository.load(currentUserId());
    await profileRepository.saveBirthDate(
      userId: profile.userId,
      birthDate: DateTime(birthDate.year, birthDate.month, birthDate.day),
    );
    return load();
  }

  int? age(FitnessTrainingProfileSnapshot profile) =>
      FitnessTrainingAgeGate.ageOn(profile.birthDate, now());

  BasicHealthReport? bodyMetrics(FitnessTrainingProfileSnapshot profile) {
    final ageYears = age(profile);
    final height = profile.heightCm;
    final weight = profile.weightKg;
    final sex = _sex(profile.gender);
    final activity = _activity(profile.activityLevel);
    if (ageYears == null ||
        height == null ||
        weight == null ||
        sex == null ||
        activity == null) {
      return null;
    }
    try {
      return BasicHealthCalculator.calculate(
        BasicHealthInput(
          heightCm: height,
          weightKg: weight,
          ageYears: ageYears,
          sex: sex,
          activityLevel: activity,
        ),
      );
    } on BasicHealthCalculatorException {
      return null;
    }
  }

  FitnessTrainingIntake makeIntake({
    required FitnessTrainingProfileSnapshot profile,
    required String goal,
    required String experience,
    required String venue,
    required Set<String> equipmentIds,
    required List<int> trainingWeekdays,
    required int sessionMinutes,
    required String workoutTime,
    required List<String> excludedMovementGroups,
    required Set<String> excludedAllergens,
    required Set<String> availableFoodGroups,
    required String sleepTime,
    required String wakeTime,
  }) {
    final report = bodyMetrics(profile);
    final ageYears = age(profile);
    return FitnessTrainingIntake(
      adultEligible: ageYears != null && ageYears >= 18,
      goal: goal,
      experience: experience,
      venue: venue,
      equipmentIds: venue == 'gym' ? equipmentIds.toList() : const [],
      trainingWeekdays: [...trainingWeekdays]..sort(),
      sessionMinutes: sessionMinutes,
      workoutTime: workoutTime,
      mealTimes: profile.mealTimes,
      excludedMovementGroups: excludedMovementGroups,
      excludedAllergens: excludedAllergens.toList()..sort(),
      availableFoodGroups: availableFoodGroups.toList()..sort(),
      sleepTime: sleepTime,
      wakeTime: wakeTime,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      sexCode: _sex(profile.gender)?.code,
      activityLevel: _activity(profile.activityLevel)?.code,
      bmi: report?.bmi,
      bmrKcal: report?.bmrKcal,
      tdeeKcal: report?.tdeeKcal,
    );
  }

  Set<String> allergenTagsFor(String restriction) {
    final value = restriction.trim().toLowerCase();
    if (value.isEmpty) return const {};
    const aliases = <String, List<String>>{
      'milk': ['milk', 'sữa', 'lactose', 'dairy'],
      'egg': ['egg', 'trứng'],
      'fish': ['fish', 'cá'],
      'crustacean_shellfish': [
        'shellfish',
        'crustacean',
        'tôm',
        'cua',
        'hải sản có vỏ',
      ],
      'soy': ['soy', 'đậu nành', 'đậu tương'],
      'peanut': ['peanut', 'lạc', 'đậu phộng'],
      'tree_nuts': ['tree nut', 'hạt cây', 'hạnh nhân', 'óc chó', 'điều'],
      'wheat_gluten': ['wheat', 'gluten', 'lúa mì', 'lúa mạch'],
      'sesame': ['sesame', 'mè', 'vừng'],
    };
    for (final entry in aliases.entries) {
      if (entry.value.any(value.contains)) return {entry.key};
    }
    return {'unknown:${value.replaceAll(RegExp(r'\s+'), '_')}'};
  }

  Future<FitnessTrainingProgram> generate({
    required FitnessTrainingLoadedContext context,
    required FitnessTrainingIntake intake,
    required String requestId,
  }) => service.generateProgram(
    userId: context.profile.userId,
    guest: currentUserId() == null,
    requestId: requestId,
    intake: intake,
    catalog: context.catalog,
  );

  Future<FitnessTrainingProgram> replan({
    required FitnessTrainingLoadedContext context,
    required FitnessTrainingProgram activeProgram,
    required FitnessTrainingIntake intake,
    required FitnessWeeklyCheckIn checkIn,
    required String requestId,
  }) => service.replanRemainingWeeks(
    activeProgram: activeProgram,
    checkIn: checkIn,
    requestId: requestId,
    guest: currentUserId() == null,
    intake: intake,
    catalog: context.catalog,
  );

  Future<FitnessTrainingProgram> apply({
    required FitnessTrainingLoadedContext context,
    required FitnessTrainingProgram program,
    required int week,
  }) => service.applyWeek(
    userId: context.profile.userId,
    program: program,
    week: week,
    catalog: context.catalog,
    today: now(),
  );

  String newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  BasicHealthSex? _sex(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male' || normalized == 'nam') return BasicHealthSex.male;
    if (normalized == 'female' || normalized == 'nữ' || normalized == 'nu') {
      return BasicHealthSex.female;
    }
    return null;
  }

  BasicHealthActivityLevel? _activity(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('sedentary') || normalized.contains('ít')) {
      return BasicHealthActivityLevel.sedentary;
    }
    if (normalized.contains('light') || normalized.contains('nhẹ')) {
      return BasicHealthActivityLevel.light;
    }
    if (normalized.contains('moderate') || normalized.contains('vừa')) {
      return BasicHealthActivityLevel.moderate;
    }
    if (normalized.contains('active') || normalized.contains('cao')) {
      return BasicHealthActivityLevel.active;
    }
    return null;
  }
}
