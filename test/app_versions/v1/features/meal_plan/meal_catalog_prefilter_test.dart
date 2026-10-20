import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_catalog_prefilter.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  const prefilter = MealCatalogPrefilter();

  test('classifies explicit dish cues into period and main or side role', () {
    final examples =
        <(String, String, String, MealSchedulePeriod, MealScheduleRole)>[
          (
            'unclassified',
            'Cháo thịt gà',
            'breakfast',
            MealSchedulePeriod.morning,
            MealScheduleRole.main,
          ),
          (
            'unclassified',
            'Sinh tố chuối',
            'morning_snack',
            MealSchedulePeriod.morning,
            MealScheduleRole.side,
          ),
          (
            'unclassified',
            'Cơm chiên gà',
            'lunch',
            MealSchedulePeriod.midday,
            MealScheduleRole.main,
          ),
          (
            'unclassified',
            'Chè đậu xanh',
            'afternoon_snack',
            MealSchedulePeriod.evening,
            MealScheduleRole.side,
          ),
          (
            'unclassified',
            'Canh rau ngót',
            'dinner',
            MealSchedulePeriod.evening,
            MealScheduleRole.main,
          ),
          (
            'lunch',
            'Món tên không rõ nhóm',
            'lunch',
            MealSchedulePeriod.midday,
            MealScheduleRole.main,
          ),
        ];

    for (final (mealType, name, expectedType, period, role) in examples) {
      final classified = prefilter.classify(
        _unreviewedMeal(name: name, mealType: mealType),
      );
      expect(classified?.mealType, expectedType, reason: name);
      expect(classified?.period, period, reason: name);
      expect(classified?.role, role, reason: name);
    }
  });

  test('does not classify ambiguous names or confuse "kèm" with dessert', () {
    expect(
      prefilter.classify(_unreviewedMeal(name: 'Món lạ với tiêu xanh')),
      isNull,
    );
    expect(
      prefilter
          .classify(_unreviewedMeal(name: 'Thịt ba chỉ nướng kèm cà tím'))
          ?.mealType,
      'dinner',
    );
  });

  test('returns immutable unique candidates with slot counts', () {
    final meals = [
      _unreviewedMeal(name: 'Cháo gà', mealType: 'unclassified'),
      _unreviewedMeal(name: 'Sinh tố chuối', mealType: 'unclassified'),
      _unreviewedMeal(name: 'Cơm chiên gà', mealType: 'unclassified'),
      _unreviewedMeal(name: 'Chè đậu xanh', mealType: 'unclassified'),
      _unreviewedMeal(name: 'Canh rau ngót', mealType: 'unclassified'),
      _unreviewedMeal(name: 'Cháo gà', code: 'duplicate'),
    ];

    final result = prefilter.filter(
      catalog: meals,
      profile: NutritionProfileEntity.empty('user-1'),
    );

    expect(result.candidates, hasLength(5));
    expect(result.eligibleCountsByType, const {
      'breakfast': 1,
      'morning_snack': 1,
      'lunch': 1,
      'afternoon_snack': 1,
      'dinner': 1,
    });
    expect(
      () => result.candidates.add(
        const MealCandidateClassification(
          code: 'new',
          name: 'Món mới',
          mealType: 'dinner',
          period: MealSchedulePeriod.evening,
          role: MealScheduleRole.main,
        ),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => result.eligibleCodesByType['breakfast']!.add('not-eligible'),
      throwsUnsupportedError,
    );
  });

  test(
    'uses general suggestions for goals but keeps unknown allergies blocked',
    () {
      final meals = [
        _unreviewedMeal(name: 'Cháo gà'),
        _unreviewedMeal(name: 'Sinh tố chuối'),
        _unreviewedMeal(name: 'Cơm chiên gà'),
        _unreviewedMeal(name: 'Chè đậu xanh'),
        _unreviewedMeal(name: 'Canh rau ngót'),
      ];
      final allergyProfile = NutritionProfileEntity.empty('user-1').copyWith(
        restrictions: const [
          FoodRestrictionEntity(type: 'allergy', itemName: 'peanut'),
        ],
      );
      final goalProfile = NutritionProfileEntity.empty('user-1').copyWith(
        goals: const [
          NutritionGoalEntity(
            code: 'lose_weight',
            name: 'Giảm cân',
            priority: 1,
          ),
        ],
      );

      final allergyFiltered = prefilter.filter(
        catalog: meals,
        profile: allergyProfile,
      );
      final goalFiltered = prefilter.filter(
        catalog: meals,
        profile: goalProfile,
      );

      expect(allergyFiltered.candidates, isEmpty);
      expect(goalFiltered.candidates, hasLength(5));
      expect(goalFiltered.usedGeneralWellnessFallback, isTrue);
      expect(
        goalFiltered.candidates.every(
          (candidate) => candidate.isGeneralWellnessOnly,
        ),
        isTrue,
      );
      expect(allergyFiltered.hasMinimumCandidatesPerPeriod, isFalse);
    },
  );

  test('drops candidates when health or avoid evidence is unverified', () {
    final meals = [
      _unreviewedMeal(name: 'Cháo gà'),
      _unreviewedMeal(name: 'Sinh tố chuối'),
      _unreviewedMeal(name: 'Cơm chiên gà'),
      _unreviewedMeal(name: 'Chè đậu xanh'),
      _unreviewedMeal(name: 'Canh rau ngót'),
    ];
    final avoidProfile = NutritionProfileEntity.empty('user-1').copyWith(
      restrictions: const [
        FoodRestrictionEntity(type: 'avoid', itemName: 'tỏi'),
      ],
    );

    final healthFiltered = prefilter.filter(
      catalog: meals,
      profile: NutritionProfileEntity.empty('user-1'),
      conditions: const {'diabetes'},
    );
    final avoidFiltered = prefilter.filter(
      catalog: meals,
      profile: avoidProfile,
    );

    expect(healthFiltered.candidates, hasLength(5));
    expect(healthFiltered.usedGeneralWellnessFallback, isTrue);
    expect(avoidFiltered.candidates, isEmpty);
  });

  test(
    'marks a nonempty slot as usable even when it has fewer dishes than days',
    () {
      final result = prefilter.filter(
        catalog: [
          _unreviewedMeal(name: 'Cháo gà'),
          _unreviewedMeal(name: 'Sinh tố chuối'),
          _unreviewedMeal(name: 'Cơm chiên gà'),
          _unreviewedMeal(name: 'Chè đậu xanh'),
          _unreviewedMeal(name: 'Canh rau ngót'),
        ],
        profile: NutritionProfileEntity.empty('user-1'),
      );

      expect(result.hasEnoughForDays(1), isTrue);
      expect(result.hasEnoughForDays(2), isFalse);
      expect(result.hasCandidatesForEverySlot, isTrue);
    },
  );

  test('filters the complete bundled 3,163-meal catalog locally', () async {
    final catalog = [
      ...await _readCatalog('assets/data/meal_catalog_v1.json'),
      ...await _readCatalog('assets/data/nabi_3000_mon_viet_moi.json'),
    ];
    final result = prefilter.filter(
      catalog: catalog,
      profile: NutritionProfileEntity.empty('catalog-audit'),
    );

    expect(catalog, hasLength(3163));
    expect(result.meals, hasLength(result.candidates.length));
    expect(
      result.candidates.map((candidate) => candidate.code).toSet(),
      hasLength(result.candidates.length),
    );
    expect(
      result.eligibleCountsByType.keys,
      containsAll(const {
        'breakfast',
        'morning_snack',
        'lunch',
        'afternoon_snack',
        'dinner',
      }),
    );
    // Report the current rule-based output in test logs for review without
    // treating any inferred classification as verified source metadata.
    // ignore: avoid_print
    print(
      'Catalog prefilter: ${catalog.length} input, '
      '${result.candidates.length} retained, '
      '${result.classificationIssues.length} classification issues, '
      'per slot ${result.eligibleCountsByType}',
    );
    expect(result.classificationIssues, isEmpty);

    final syntheticPersonalized = prefilter.filter(
      catalog: catalog,
      profile: NutritionProfileEntity.empty('synthetic-profile'),
      goals: const {'heart health'},
      conditions: const {'constipation', 'bloating', 'indigestion'},
    );
    expect(syntheticPersonalized.usedGeneralWellnessFallback, isTrue);
    expect(syntheticPersonalized.hasMinimumCandidatesPerPeriod, isTrue);
    expect(syntheticPersonalized.eligibleCountsByPeriod, const {
      MealSchedulePeriod.morning: 680,
      MealSchedulePeriod.midday: 597,
      MealSchedulePeriod.evening: 1836,
    });
    expect(
      syntheticPersonalized.eligibleCountsByPeriod.values,
      everyElement(greaterThanOrEqualTo(50)),
    );
    expect(
      syntheticPersonalized.candidates.every(
        (candidate) => candidate.isGeneralWellnessOnly,
      ),
      isTrue,
    );
  });
}

Future<List<MealCatalogItemModel>> _readCatalog(String path) async {
  final decoded = jsonDecode(await File(path).readAsString());
  final recipes = (decoded as Map<String, Object?>)['recipes'] as List<Object?>;
  final timestamp = DateTime.utc(2026).toIso8601String();
  return recipes
      .map(
        (recipe) => MealCatalogItemModel.fromSourceJson(
          Map<String, Object?>.from(recipe! as Map),
          timestamp: timestamp,
        ),
      )
      .toList(growable: false);
}

MealCatalogItemModel _unreviewedMeal({
  required String name,
  String mealType = 'unclassified',
  String? code,
}) {
  final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return MealCatalogItemModel(
    code: code ?? 'nabi_vn_$slug',
    mealType: mealType,
    mealName: name,
    description: 'Món kiểm thử.',
    cookingInstructions: 'Nấu chín theo hướng dẫn.',
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    waterMl: 0,
    ingredients: const ['nguyên liệu kiểm thử'],
    cookingSteps: const ['Nấu chín.'],
    allergenVerificationStatus: 'unknown',
    nutritionStatus: 'estimated_unverified',
    constraintMetadataStatus: 'awaiting_professional_review',
    metadataStatus: 'ai_generated_needs_review',
    isPlanEligible: false,
    sourceName: MealCatalogItemModel.unreviewedWellnessCandidateSourceName,
    sourceHash: List.filled(64, 'c').join(),
    createdAt: '2026-01-01T00:00:00.000',
    updatedAt: '2026-01-01T00:00:00.000',
  );
}
