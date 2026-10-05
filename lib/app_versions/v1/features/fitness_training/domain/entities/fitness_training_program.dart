class FitnessTrainingIntake {
  const FitnessTrainingIntake({
    required this.adultEligible,
    required this.goal,
    required this.experience,
    required this.venue,
    required this.equipmentIds,
    required this.trainingWeekdays,
    required this.sessionMinutes,
    required this.workoutTime,
    required this.mealTimes,
    required this.excludedMovementGroups,
    required this.excludedAllergens,
    required this.availableFoodGroups,
    required this.sleepTime,
    required this.wakeTime,
    required this.heightCm,
    required this.weightKg,
    required this.sexCode,
    required this.activityLevel,
    required this.bmi,
    required this.bmrKcal,
    required this.tdeeKcal,
  });

  final bool adultEligible;
  final String goal;
  final String experience;
  final String venue;
  final List<String> equipmentIds;
  final List<int> trainingWeekdays;
  final int sessionMinutes;
  final String workoutTime;
  final List<String> mealTimes;
  final List<String> excludedMovementGroups;
  final List<String> excludedAllergens;
  final List<String> availableFoodGroups;
  final String sleepTime;
  final String wakeTime;
  final double? heightCm;
  final double? weightKg;
  final String? sexCode;
  final String? activityLevel;
  final double? bmi;
  final int? bmrKcal;
  final int? tdeeKcal;

  FitnessTrainingIntake copyWith({String? workoutTime}) =>
      FitnessTrainingIntake(
        adultEligible: adultEligible,
        goal: goal,
        experience: experience,
        venue: venue,
        equipmentIds: equipmentIds,
        trainingWeekdays: trainingWeekdays,
        sessionMinutes: sessionMinutes,
        workoutTime: workoutTime ?? this.workoutTime,
        mealTimes: mealTimes,
        excludedMovementGroups: excludedMovementGroups,
        excludedAllergens: excludedAllergens,
        availableFoodGroups: availableFoodGroups,
        sleepTime: sleepTime,
        wakeTime: wakeTime,
        heightCm: heightCm,
        weightKg: weightKg,
        sexCode: sexCode,
        activityLevel: activityLevel,
        bmi: bmi,
        bmrKcal: bmrKcal,
        tdeeKcal: tdeeKcal,
      );

  FitnessTrainingIntake forWorkoutOnly() => FitnessTrainingIntake(
    adultEligible: adultEligible,
    goal: goal,
    experience: experience,
    venue: venue,
    equipmentIds: equipmentIds,
    trainingWeekdays: trainingWeekdays,
    sessionMinutes: sessionMinutes,
    workoutTime: workoutTime,
    mealTimes: const [],
    excludedMovementGroups: excludedMovementGroups,
    excludedAllergens: const [],
    availableFoodGroups: const [],
    sleepTime: '',
    wakeTime: '',
    heightCm: heightCm,
    weightKg: weightKg,
    sexCode: sexCode,
    activityLevel: activityLevel,
    bmi: bmi,
    bmrKcal: bmrKcal,
    tdeeKcal: tdeeKcal,
  );

  /// Data that may be sent to AI for the workout-only M32 flow.
  /// Legacy food and sleep fields remain in [toJson] for stored programs.
  Map<String, Object?> toAiJson() => {
    'adult_eligible': adultEligible,
    'goal': goal,
    'experience': experience,
    'venue': venue,
    'equipment_ids': equipmentIds,
    'training_weekdays': trainingWeekdays,
    'session_minutes': sessionMinutes,
    'workout_time': workoutTime,
    'excluded_movement_groups': excludedMovementGroups,
    'metrics': {
      if (bmi != null) 'bmi': bmi,
      if (bmrKcal != null) 'bmr_kcal': bmrKcal,
      if (tdeeKcal != null) 'tdee_kcal': tdeeKcal,
    },
  };

  Map<String, Object?> toJson() => {
    'adult_eligible': adultEligible,
    'goal': goal,
    'experience': experience,
    'venue': venue,
    'equipment_ids': equipmentIds,
    'training_weekdays': trainingWeekdays,
    'session_minutes': sessionMinutes,
    'workout_time': workoutTime,
    'meal_times': mealTimes,
    'excluded_movement_groups': excludedMovementGroups,
    'excluded_allergens': excludedAllergens,
    'available_food_groups': availableFoodGroups,
    'sleep_time': sleepTime,
    'wake_time': wakeTime,
    'metrics': {
      if (bmi != null) 'bmi': bmi,
      if (bmrKcal != null) 'bmr_kcal': bmrKcal,
      if (tdeeKcal != null) 'tdee_kcal': tdeeKcal,
    },
  };

  factory FitnessTrainingIntake.fromJson(Map<String, Object?> json) {
    final metrics = _object(json['metrics']);
    return FitnessTrainingIntake(
      adultEligible: json['adult_eligible'] == true,
      goal: _string(json['goal']),
      experience: _string(json['experience']),
      venue: _string(json['venue']),
      equipmentIds: _stringList(json['equipment_ids']),
      trainingWeekdays: _integerList(json['training_weekdays']),
      sessionMinutes: _integer(json['session_minutes']),
      workoutTime: _string(json['workout_time']),
      mealTimes: _stringList(json['meal_times']),
      excludedMovementGroups: _stringList(json['excluded_movement_groups']),
      excludedAllergens: _stringList(json['excluded_allergens']),
      availableFoodGroups: _stringList(json['available_food_groups']),
      sleepTime: _string(json['sleep_time']),
      wakeTime: _string(json['wake_time']),
      heightCm: _nullableDouble(metrics['height_cm']),
      weightKg: _nullableDouble(metrics['weight_kg']),
      sexCode: _nullableString(metrics['sex']),
      activityLevel: _nullableString(metrics['activity_level']),
      bmi: _nullableDouble(metrics['bmi']),
      bmrKcal: _nullableInt(metrics['bmr_kcal']),
      tdeeKcal: _nullableInt(metrics['tdee_kcal']),
    );
  }
}

class FitnessWorkoutExercise {
  const FitnessWorkoutExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.durationMinutes,
    required this.restSeconds,
  });

  final String exerciseId;
  final int? sets;
  final int? reps;
  final int? durationMinutes;
  final int? restSeconds;

  Map<String, Object?> toJson() => {
    'exercise_id': exerciseId,
    if (sets != null) 'sets': sets,
    if (reps != null) 'reps': reps,
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
    if (restSeconds != null) 'rest_seconds': restSeconds,
  };

  factory FitnessWorkoutExercise.fromJson(Map<String, Object?> json) =>
      FitnessWorkoutExercise(
        exerciseId: _string(json['exercise_id']),
        sets: _nullableInt(json['sets']),
        reps: _nullableInt(json['reps']),
        durationMinutes: _nullableInt(json['duration_minutes']),
        restSeconds: _nullableInt(json['rest_seconds']),
      );
}

class FitnessProgramMeal {
  const FitnessProgramMeal({
    required this.mealSlot,
    required this.recipeId,
    required this.servings,
  });

  final String mealSlot;
  final String recipeId;
  final double servings;

  Map<String, Object?> toJson() => {
    'meal_slot': mealSlot,
    'recipe_id': recipeId,
    'servings': servings,
  };

  factory FitnessProgramMeal.fromJson(Map<String, Object?> json) =>
      FitnessProgramMeal(
        mealSlot: _string(json['meal_slot']),
        recipeId: _string(json['recipe_id']),
        servings: _double(json['servings'], fallback: 1),
      );
}

class FitnessProgramDay {
  const FitnessProgramDay({
    required this.dayIndex,
    required this.date,
    required this.isRestDay,
    required this.exercises,
    required this.meals,
    required this.sleepTime,
    required this.wakeTime,
  });

  final int dayIndex;
  final DateTime date;
  final bool isRestDay;
  final List<FitnessWorkoutExercise> exercises;
  final List<FitnessProgramMeal> meals;
  final String sleepTime;
  final String wakeTime;

  Map<String, Object?> toJson() => {
    'day_index': dayIndex,
    'date': _dateKey(date),
    'is_rest_day': isRestDay,
    'exercises': exercises.map((item) => item.toJson()).toList(),
    'meals': meals.map((item) => item.toJson()).toList(),
    'sleep_time': sleepTime,
    'wake_time': wakeTime,
  };

  factory FitnessProgramDay.fromJson(Map<String, Object?> json) {
    final exerciseRows = _objectList(json['exercises']);
    final mealRows = _objectList(json['meals']);
    return FitnessProgramDay(
      dayIndex: _integer(json['day_index']),
      date: DateTime.tryParse(_string(json['date'])) ?? DateTime(2000),
      isRestDay: json['is_rest_day'] == true,
      exercises: [
        for (final row in exerciseRows) FitnessWorkoutExercise.fromJson(row),
      ],
      meals: [for (final row in mealRows) FitnessProgramMeal.fromJson(row)],
      sleepTime: _string(json['sleep_time']),
      wakeTime: _string(json['wake_time']),
    );
  }
}

class FitnessWeeklyCheckIn {
  const FitnessWeeklyCheckIn({
    required this.week,
    required this.effortScore,
    required this.sorenessScore,
    required this.note,
    required this.createdAt,
  });

  final int week;
  final int effortScore;
  final int sorenessScore;
  final String note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'week': week,
    'effort_score': effortScore,
    'soreness_score': sorenessScore,
    'note': note,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory FitnessWeeklyCheckIn.fromJson(Map<String, Object?> json) =>
      FitnessWeeklyCheckIn(
        week: _integer(json['week']),
        effortScore: _integer(json['effort_score']),
        sorenessScore: _integer(json['soreness_score']),
        note: _string(json['note']),
        createdAt:
            DateTime.tryParse(_string(json['created_at'])) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

abstract final class FitnessProgramStatus {
  static const preview = 'preview';
  static const active = 'active';
  static const archived = 'archived';
}

class FitnessTrainingProgram {
  const FitnessTrainingProgram({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.status,
    required this.activeWeek,
    required this.quotaCommitted,
    required this.startDate,
    required this.intake,
    required this.days,
    required this.checkIns,
    required this.createdAt,
    required this.updatedAt,
    this.parentProgramId,
  });

  final String id;
  final String userId;
  final String requestId;
  final String status;
  final int activeWeek;
  final bool quotaCommitted;
  final DateTime startDate;
  final FitnessTrainingIntake intake;
  final List<FitnessProgramDay> days;
  final List<FitnessWeeklyCheckIn> checkIns;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentProgramId;

  FitnessTrainingProgram copyWith({
    String? status,
    int? activeWeek,
    bool? quotaCommitted,
    FitnessTrainingIntake? intake,
    List<FitnessProgramDay>? days,
    List<FitnessWeeklyCheckIn>? checkIns,
    DateTime? updatedAt,
  }) => FitnessTrainingProgram(
    id: id,
    userId: userId,
    requestId: requestId,
    status: status ?? this.status,
    activeWeek: activeWeek ?? this.activeWeek,
    quotaCommitted: quotaCommitted ?? this.quotaCommitted,
    startDate: startDate,
    intake: intake ?? this.intake,
    days: days ?? this.days,
    checkIns: checkIns ?? this.checkIns,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    parentProgramId: parentProgramId,
  );

  List<FitnessProgramDay> get weekDays => days
      .where(
        (day) =>
            day.dayIndex >= (activeWeek - 1) * 7 &&
            day.dayIndex < activeWeek * 7,
      )
      .toList(growable: false);

  Map<String, Object?> toJson() => {
    'id': id,
    'request_id': requestId,
    'status': status,
    'active_week': activeWeek,
    'quota_committed': quotaCommitted,
    'parent_program_id': parentProgramId,
    'start_date': _dateKey(startDate),
    'intake': intake.toJson(),
    'days': days.map((day) => day.toJson()).toList(),
    'check_ins': checkIns.map((item) => item.toJson()).toList(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory FitnessTrainingProgram.fromJson(Map<String, Object?> json) {
    final intake = FitnessTrainingIntake.fromJson(_object(json['intake']));
    final days = _objectList(json['days']);
    final checks = _objectList(json['check_ins']);
    return FitnessTrainingProgram(
      id: _string(json['id']),
      userId: _string(json['user_id']),
      requestId: _string(json['request_id']),
      status: _string(json['status']),
      activeWeek: _integer(json['active_week'], fallback: 1),
      quotaCommitted: json['quota_committed'] == true,
      startDate:
          DateTime.tryParse(_string(json['start_date'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      intake: intake,
      days: [for (final row in days) FitnessProgramDay.fromJson(row)],
      checkIns: [for (final row in checks) FitnessWeeklyCheckIn.fromJson(row)],
      createdAt:
          DateTime.tryParse(_string(json['created_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(_string(json['updated_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      parentProgramId: _nullableString(json['parent_program_id']),
    );
  }
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

Map<String, Object?> _object(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};

List<Map<String, Object?>> _objectList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((row) => Map<String, Object?>.from(row))
          .toList()
    : const [];

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

List<int> _integerList(Object? value) => value is List
    ? value.map((item) => _integer(item)).toList(growable: false)
    : const [];

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) {
  final result = _string(value).trim();
  return result.isEmpty ? null : result;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
