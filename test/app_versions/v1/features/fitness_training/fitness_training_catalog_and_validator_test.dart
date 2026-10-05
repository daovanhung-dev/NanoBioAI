import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/data/datasources/fitness_training_catalog_asset_datasource.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_catalog.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_program.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/services/fitness_program_validator.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/services/fitness_training_age_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FitnessTrainingCatalog catalog;

  setUpAll(() async {
    catalog = await const FitnessTrainingCatalogAssetDatasource().load();
  });

  test('age gate checks the exact 18th birthday and rejects future dates', () {
    expect(
      FitnessTrainingAgeGate.isAdult(
        DateTime(2008, 10, 5),
        DateTime(2026, 10, 5),
      ),
      isTrue,
    );
    expect(
      FitnessTrainingAgeGate.isAdult(
        DateTime(2008, 10, 6),
        DateTime(2026, 10, 5),
      ),
      isFalse,
    );
    expect(
      FitnessTrainingAgeGate.ageOn(DateTime(2030, 1, 1), DateTime(2026, 1, 1)),
      isNull,
    );
  });

  test('catalog has the pilot inventory and filters home/gym equipment', () {
    expect(catalog.exercises, hasLength(24));
    expect(catalog.equipment, hasLength(10));
    expect(catalog.recipes, hasLength(35));
    expect(catalog.ingredients, hasLength(47));

    final home = catalog.eligibleExercises(
      venue: 'home',
      equipmentIds: const {},
      excludedMovementGroups: const {},
    );
    expect(home, hasLength(8));
    expect(home.every((exercise) => exercise.venue == 'home'), isTrue);

    final noGymEquipment = catalog.eligibleExercises(
      venue: 'gym',
      equipmentIds: const {},
      excludedMovementGroups: const {},
    );
    expect(noGymEquipment, isEmpty);
  });

  test(
    'recipe filter fails closed for unknown allergens and excludes milk',
    () {
      final unknown = catalog.eligibleRecipes(
        excludedAllergens: const {'unknown:sesame_oil'},
        availableFoodGroups: catalog.foodGroups,
      );
      expect(unknown, isEmpty);

      final milkFree = catalog.eligibleRecipes(
        excludedAllergens: const {'milk'},
        availableFoodGroups: catalog.foodGroups,
      );
      expect(milkFree, isNotEmpty);
      expect(
        milkFree.every((recipe) => !recipe.allergens.contains('milk')),
        isTrue,
      );
      expect(
        milkFree.every(
          (recipe) => recipe.ingredients.every((item) {
            final ingredient = catalog.ingredientsById[item.ingredientId]!;
            return !ingredient.allergens.contains('milk');
          }),
        ),
        isTrue,
      );
    },
  );

  test(
    'intake serialization excludes birth date and direct profile fields',
    () {
      final json = _intake().toJson();
      final encoded = jsonEncode(json);
      expect(json, isNot(contains('birth_date')));
      expect(json, isNot(contains('height_cm')));
      expect(json, isNot(contains('weight_kg')));
      expect(encoded, isNot(contains('full_name')));
      expect(encoded, isNot(contains('birth_date')));
    },
  );

  test(
    'validates all 28 days and rejects IDs outside the reviewed catalog',
    () {
      final intake = _intake();
      final response = _response(catalog, intake);
      final validator = const FitnessProgramValidator();
      final parsed = validator.parse(
        response: jsonEncode(response),
        userId: 'local-user',
        requestId: 'request-1',
        programId: 'program-1',
        status: FitnessProgramStatus.preview,
        quotaCommitted: true,
        intake: intake,
        catalog: catalog,
        startDate: DateTime(2026, 10, 5),
        now: DateTime.utc(2026, 10, 5),
      );
      expect(parsed.days, hasLength(28));
      expect(parsed.days.where((day) => day.isRestDay), hasLength(16));

      final invalid = _response(catalog, intake);
      final firstWorkout =
          (invalid['days'] as List).firstWhere(
                (row) =>
                    ((row as Map)['workout'] as Map)['is_rest_day'] == false,
              )
              as Map<String, Object?>;
      final workout = Map<String, Object?>.from(
        firstWorkout['workout']! as Map,
      );
      final exercises = List<Map<String, Object?>>.from(
        workout['exercises']! as List,
      );
      exercises.first['exercise_id'] = 'unapproved-exercise-id';
      workout['exercises'] = exercises;
      firstWorkout['workout'] = workout;

      expect(
        () => validator.parse(
          response: jsonEncode(invalid),
          userId: 'local-user',
          requestId: 'request-2',
          programId: 'program-2',
          status: FitnessProgramStatus.preview,
          quotaCommitted: true,
          intake: intake,
          catalog: catalog,
          startDate: DateTime(2026, 10, 5),
          now: DateTime.utc(2026, 10, 5),
        ),
        throwsA(isA<FitnessProgramValidationException>()),
      );
    },
  );

  test('rejects Gemini fields outside the strict response schema', () {
    final intake = _intake();
    final invalid = _response(catalog, intake);
    invalid['unexpected'] = true;

    expect(
      () => _parse(invalid, intake, catalog),
      throwsA(isA<FitnessProgramValidationException>()),
    );
  });

  test('rejects incomplete workout and meal structures', () {
    final intake = _intake();
    final missingWorkoutExercises = _response(catalog, intake);
    final firstDay = (missingWorkoutExercises['days'] as List).first as Map;
    (firstDay['workout'] as Map).remove('exercises');
    expect(
      () => _parse(missingWorkoutExercises, intake, catalog),
      throwsA(isA<FitnessProgramValidationException>()),
    );

    final invalidServings = _response(catalog, intake);
    final day = (invalidServings['days'] as List).first as Map;
    ((day['meals'] as List).first as Map).remove('servings');
    expect(
      () => _parse(invalidServings, intake, catalog),
      throwsA(isA<FitnessProgramValidationException>()),
    );
  });
}

FitnessTrainingProgram _parse(
  Map<String, Object?> response,
  FitnessTrainingIntake intake,
  FitnessTrainingCatalog catalog,
) => const FitnessProgramValidator().parse(
  response: jsonEncode(response),
  userId: 'local-user',
  requestId: 'schema-test',
  programId: 'schema-program',
  status: FitnessProgramStatus.preview,
  quotaCommitted: true,
  intake: intake,
  catalog: catalog,
  startDate: DateTime(2026, 10, 5),
  now: DateTime.utc(2026, 10, 5),
);

FitnessTrainingIntake _intake() => FitnessTrainingIntake(
  adultEligible: true,
  goal: 'general_fitness',
  experience: 'beginner',
  venue: 'home',
  equipmentIds: const [],
  trainingWeekdays: const [1, 3, 5],
  sessionMinutes: 45,
  workoutTime: '17:30',
  mealTimes: const ['07:30', '10:00', '12:30', '15:30', '19:00'],
  excludedMovementGroups: const [],
  excludedAllergens: const [],
  availableFoodGroups: const [
    'protein',
    'carbohydrate',
    'fruit_vegetable',
    'fat_source',
  ],
  sleepTime: '22:30',
  wakeTime: '06:30',
  heightCm: 170,
  weightKg: 70,
  sexCode: 'female',
  activityLevel: 'light',
  bmi: 24.2,
  bmrKcal: 1450,
  tdeeKcal: 1994,
);

Map<String, Object?> _response(dynamic catalog, FitnessTrainingIntake intake) {
  final exercises = catalog.eligibleExercises(
    venue: intake.venue,
    equipmentIds: intake.equipmentIds.toSet(),
    excludedMovementGroups: intake.excludedMovementGroups.toSet(),
  );
  final recipes = catalog.eligibleRecipes(
    excludedAllergens: intake.excludedAllergens.toSet(),
    availableFoodGroups: intake.availableFoodGroups.toSet(),
  );
  final trainingExercise = exercises.first;
  final bounds = trainingExercise.bounds;
  final exercisePrescription = bounds.containsKey('sets_min')
      ? {
          'exercise_id': trainingExercise.id,
          'sets': bounds['sets_min'],
          'reps': bounds['reps_min'],
          'rest_seconds': bounds['rest_seconds_min'],
          'duration_minutes': null,
        }
      : {
          'exercise_id': trainingExercise.id,
          'sets': null,
          'reps': null,
          'rest_seconds': null,
          'duration_minutes': bounds['duration_minutes_min'],
        };
  final start = DateTime(2026, 10, 5);
  return {
    'days': [
      for (var index = 0; index < 28; index++)
        () {
          final date = start.add(Duration(days: index));
          final training = intake.trainingWeekdays.contains(date.weekday);
          return {
            'day_index': index,
            'workout': {
              'is_rest_day': !training,
              'exercises': training ? [exercisePrescription] : <Object>[],
            },
            'meals': [
              for (final slot in FitnessProgramValidator.mealSlots)
                {
                  'meal_slot': slot,
                  'recipe_id': recipes
                      .firstWhere((recipe) => recipe.mealSlot == slot)
                      .id,
                  'servings': 1.0,
                },
            ],
          };
        }(),
    ],
  };
}
