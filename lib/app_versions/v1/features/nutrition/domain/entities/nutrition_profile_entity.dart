class NutritionProfileEntity {
  const NutritionProfileEntity({
    required this.id,
    required this.userId,
    this.birthDate,
    this.waistCm,
    this.currentStatus = '',
    this.averageSleepHours,
    this.smokingStatus = 'not_provided',
    this.smokingAmountNote = '',
    this.alcoholFrequency = 'not_provided',
    this.coffeeFrequency = 'not_provided',
    this.targetWeightKg,
    this.targetWeightSource = '',
    this.waterRestriction = false,
    this.waterRestrictionNote = '',
    this.nocturiaLevel = 'not_provided',
    this.restrictions = const [],
    this.symptoms = const [],
    this.medications = const [],
    this.labResults = const [],
    this.goals = const [],
    this.mealPreferences = const [],
    this.preferenceRules = const [],
    this.schemaVersion = 1,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String userId;
  final DateTime? birthDate;
  final double? waistCm;
  final String currentStatus;
  final double? averageSleepHours;
  final String smokingStatus;
  final String smokingAmountNote;
  final String alcoholFrequency;
  final String coffeeFrequency;
  final double? targetWeightKg;
  final String targetWeightSource;
  final bool waterRestriction;
  final String waterRestrictionNote;
  final String nocturiaLevel;
  final List<FoodRestrictionEntity> restrictions;
  final List<HealthSymptomEntity> symptoms;
  final List<MedicationRecordEntity> medications;
  final List<LabResultEntity> labResults;
  final List<NutritionGoalEntity> goals;
  final List<MealSchedulePreferenceEntity> mealPreferences;
  final List<NutritionPreferenceRuleEntity> preferenceRules;
  final int schemaVersion;
  final String createdAt;
  final String updatedAt;

  factory NutritionProfileEntity.empty(String userId) {
    return NutritionProfileEntity(id: '', userId: userId);
  }

  NutritionProfileEntity copyWith({
    String? id,
    String? userId,
    DateTime? birthDate,
    bool clearBirthDate = false,
    double? waistCm,
    bool clearWaistCm = false,
    String? currentStatus,
    double? averageSleepHours,
    bool clearAverageSleepHours = false,
    String? smokingStatus,
    String? smokingAmountNote,
    String? alcoholFrequency,
    String? coffeeFrequency,
    double? targetWeightKg,
    bool clearTargetWeightKg = false,
    String? targetWeightSource,
    bool? waterRestriction,
    String? waterRestrictionNote,
    String? nocturiaLevel,
    List<FoodRestrictionEntity>? restrictions,
    List<HealthSymptomEntity>? symptoms,
    List<MedicationRecordEntity>? medications,
    List<LabResultEntity>? labResults,
    List<NutritionGoalEntity>? goals,
    List<MealSchedulePreferenceEntity>? mealPreferences,
    List<NutritionPreferenceRuleEntity>? preferenceRules,
    int? schemaVersion,
    String? createdAt,
    String? updatedAt,
  }) {
    return NutritionProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
      waistCm: clearWaistCm ? null : waistCm ?? this.waistCm,
      currentStatus: currentStatus ?? this.currentStatus,
      averageSleepHours: clearAverageSleepHours
          ? null
          : averageSleepHours ?? this.averageSleepHours,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      smokingAmountNote: smokingAmountNote ?? this.smokingAmountNote,
      alcoholFrequency: alcoholFrequency ?? this.alcoholFrequency,
      coffeeFrequency: coffeeFrequency ?? this.coffeeFrequency,
      targetWeightKg: clearTargetWeightKg
          ? null
          : targetWeightKg ?? this.targetWeightKg,
      targetWeightSource: targetWeightSource ?? this.targetWeightSource,
      waterRestriction: waterRestriction ?? this.waterRestriction,
      waterRestrictionNote:
          waterRestrictionNote ?? this.waterRestrictionNote,
      nocturiaLevel: nocturiaLevel ?? this.nocturiaLevel,
      restrictions: restrictions ?? this.restrictions,
      symptoms: symptoms ?? this.symptoms,
      medications: medications ?? this.medications,
      labResults: labResults ?? this.labResults,
      goals: goals ?? this.goals,
      mealPreferences: mealPreferences ?? this.mealPreferences,
      preferenceRules: preferenceRules ?? this.preferenceRules,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FoodRestrictionEntity {
  const FoodRestrictionEntity({
    this.id = '',
    required this.type,
    required this.itemName,
    this.severityLevel,
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String type;
  final String itemName;
  final int? severityLevel;
  final String note;
  final bool isActive;
}

class HealthSymptomEntity {
  const HealthSymptomEntity({
    this.id = '',
    required this.symptomType,
    this.bodyLocation = '',
    this.severityLevel,
    this.startedAt,
    this.triggerNote = '',
    this.impactNote = '',
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String symptomType;
  final String bodyLocation;
  final int? severityLevel;
  final DateTime? startedAt;
  final String triggerNote;
  final String impactNote;
  final String note;
  final bool isActive;
}

class MedicationRecordEntity {
  const MedicationRecordEntity({
    this.id = '',
    required this.name,
    this.productType = 'medication',
    this.usageSchedule = '',
    this.prescriberConfirmed = false,
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String productType;
  final String usageSchedule;
  final bool prescriberConfirmed;
  final String note;
  final bool isActive;
}

class LabResultEntity {
  const LabResultEntity({
    this.id = '',
    this.testCode = '',
    required this.testName,
    required this.valueText,
    this.unit = '',
    this.measuredAt,
    this.referenceNote = '',
    this.note = '',
  });

  final String id;
  final String testCode;
  final String testName;
  final String valueText;
  final String unit;
  final DateTime? measuredAt;
  final String referenceNote;
  final String note;
}

class NutritionGoalEntity {
  const NutritionGoalEntity({
    this.id = '',
    required this.code,
    required this.name,
    required this.priority,
    this.targetPeriod = '',
    this.targetDate,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String name;
  final int priority;
  final String targetPeriod;
  final DateTime? targetDate;
  final bool isActive;
}

class MealSchedulePreferenceEntity {
  const MealSchedulePreferenceEntity({
    this.id = '',
    required this.mealType,
    this.startTime = '',
    this.endTime = '',
    this.portionNote = '',
    this.targetCalories,
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String mealType;
  final String startTime;
  final String endTime;
  final String portionNote;
  final int? targetCalories;
  final String note;
  final bool isActive;
}

class NutritionPreferenceRuleEntity {
  const NutritionPreferenceRuleEntity({
    this.id = '',
    required this.ruleType,
    this.itemCode = '',
    required this.itemName,
    required this.preferenceLevel,
    this.note = '',
    this.isActive = true,
    this.schemaVersion = 1,
  });

  final String id;
  final String ruleType;
  final String itemCode;
  final String itemName;
  final String preferenceLevel;
  final String note;
  final bool isActive;
  final int schemaVersion;
}
