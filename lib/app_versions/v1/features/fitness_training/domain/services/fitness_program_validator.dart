import 'dart:convert';

import '../entities/fitness_training_catalog.dart';
import '../entities/fitness_training_program.dart';

class FitnessProgramValidationException implements Exception {
  const FitnessProgramValidationException(this.code);

  final String code;

  @override
  String toString() => 'Fitness program is invalid: $code';
}

class FitnessProgramValidator {
  const FitnessProgramValidator();

  FitnessTrainingProgram parse({
    required String response,
    required String userId,
    required String requestId,
    required String programId,
    required String status,
    required bool quotaCommitted,
    required FitnessTrainingIntake intake,
    required FitnessTrainingCatalog catalog,
    required DateTime startDate,
    required DateTime now,
    int firstDayIndex = 0,
    List<FitnessProgramDay> preservedDays = const [],
    List<FitnessWeeklyCheckIn> checkIns = const [],
    String? parentProgramId,
  }) {
    if (!intake.adultEligible) _invalid('adult_gate');
    if (firstDayIndex < 0 || firstDayIndex > 27 || firstDayIndex % 7 != 0) {
      _invalid('replan_window');
    }

    final decoded = _decode(response);
    _requireOnlyKeys(decoded, const {'days'}, 'root_shape');
    final dayRows = _objectList(decoded['days']);
    final expectedCount = 28 - firstDayIndex;
    if (dayRows.length != expectedCount) _invalid('day_count');

    final eligibleExerciseIds = catalog
        .eligibleExercises(
          venue: intake.venue,
          equipmentIds: intake.equipmentIds.toSet(),
          excludedMovementGroups: intake.excludedMovementGroups.toSet(),
        )
        .map((item) => item.id)
        .toSet();
    final generatedByIndex = <int, FitnessProgramDay>{};
    for (final row in dayRows) {
      _requireOnlyKeys(row, const {'day_index', 'workout'}, 'day_shape');
      if (row['day_index'] == null) _invalid('day_shape');
      final index = _int(row['day_index']);
      if (index < firstDayIndex ||
          index > 27 ||
          generatedByIndex.containsKey(index)) {
        _invalid('day_index');
      }
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: index));
      final expectedWorkout = intake.trainingWeekdays.contains(date.weekday);
      final workout = _object(row['workout']);
      if (row['workout'] is! Map || workout['is_rest_day'] is! bool) {
        _invalid('workout_shape');
      }
      _requireOnlyKeys(workout, const {
        'is_rest_day',
        'exercises',
      }, 'workout_shape');
      if (workout['exercises'] is! List) _invalid('workout_shape');
      final isRestDay = workout['is_rest_day'] == true;
      final exercises = _objectList(workout['exercises']);
      if (isRestDay == expectedWorkout ||
          (expectedWorkout && exercises.isEmpty) ||
          (!expectedWorkout && exercises.isNotEmpty)) {
        _invalid('training_days');
      }
      if (exercises.length > 8) _invalid('exercise_count');

      final validatedExercises = <FitnessWorkoutExercise>[];
      for (final item in exercises) {
        _requireOnlyKeys(item, const {
          'exercise_id',
          'sets',
          'reps',
          'duration_minutes',
          'rest_seconds',
        }, 'exercise_shape');
        final exercise = FitnessWorkoutExercise.fromJson(item);
        if (!eligibleExerciseIds.contains(exercise.exerciseId)) {
          _invalid('exercise_catalog_filter');
        }
        _validateExercisePrescription(
          exercise,
          catalog.exercisesById[exercise.exerciseId]!,
        );
        validatedExercises.add(exercise);
      }

      generatedByIndex[index] = FitnessProgramDay(
        dayIndex: index,
        date: date,
        isRestDay: isRestDay,
        exercises: validatedExercises,
        meals: const [],
        sleepTime: '',
        wakeTime: '',
      );
    }

    final mergedDays = <FitnessProgramDay>[];
    for (var index = 0; index < firstDayIndex; index++) {
      final preserved = preservedDays.where((day) => day.dayIndex == index);
      if (preserved.isEmpty) _invalid('preserved_history');
      mergedDays.add(preserved.first);
    }
    for (var index = firstDayIndex; index < 28; index++) {
      final day = generatedByIndex[index];
      if (day == null) _invalid('missing_day');
      mergedDays.add(day);
    }

    return FitnessTrainingProgram(
      id: programId,
      userId: userId,
      requestId: requestId,
      status: status,
      activeWeek: firstDayIndex ~/ 7 + 1,
      quotaCommitted: quotaCommitted,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      intake: intake,
      days: mergedDays,
      checkIns: checkIns,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
      parentProgramId: parentProgramId,
    );
  }

  void _validateExercisePrescription(
    FitnessWorkoutExercise exercise,
    FitnessExercise catalogExercise,
  ) {
    final bounds = catalogExercise.bounds;
    if (bounds.containsKey('sets_min')) {
      if (!_within(exercise.sets, bounds['sets_min'], bounds['sets_max']) ||
          !_within(exercise.reps, bounds['reps_min'], bounds['reps_max']) ||
          !_within(
            exercise.restSeconds,
            bounds['rest_seconds_min'],
            bounds['rest_seconds_max'],
          ) ||
          exercise.durationMinutes != null) {
        _invalid('strength_bounds');
      }
      return;
    }
    if (!_within(
          exercise.durationMinutes,
          bounds['duration_minutes_min'],
          bounds['duration_minutes_max'],
        ) ||
        exercise.sets != null ||
        exercise.reps != null ||
        exercise.restSeconds != null) {
      _invalid('cardio_bounds');
    }
  }

  Map<String, Object?> _decode(String response) {
    var text = response.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } catch (_) {
      _invalid('invalid_json');
    }
    _invalid('invalid_root');
  }

  bool _within(int? value, Object? min, Object? max) {
    if (value == null || min is! num || max is! num) return false;
    return value >= min && value <= max;
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    _invalid('number_type');
  }

  Map<String, Object?> _object(Object? value) =>
      value is Map ? Map<String, Object?>.from(value) : const {};

  void _requireOnlyKeys(
    Map<String, Object?> value,
    Set<String> allowed,
    String code,
  ) {
    if (value.keys.any((key) => !allowed.contains(key))) _invalid(code);
  }

  List<Map<String, Object?>> _objectList(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList()
      : const [];

  Never _invalid(String code) => throw FitnessProgramValidationException(code);
}
