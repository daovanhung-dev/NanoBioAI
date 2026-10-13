import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  const selector = MealCandidateSelector();

  test('full-plan generation keeps active local catalog meals', () {
    final candidates = selector.eligibleMeals(
      catalog: <MealCatalogItemModel>[
        _meal(code: 'approved'),
        _meal(code: 'draft', metadataStatus: 'pending_review'),
        _meal(code: 'reference', isPlanEligible: false),
        _meal(code: 'unclassified', mealType: 'unclassified'),
        _meal(code: 'fixture-meal-breakfast-v1'),
        _meal(code: 'inactive', isActive: false),
      ],
      profile: NutritionProfileEntity.empty('user-1'),
    );

    expect(
      candidates.map((item) => item.code),
      orderedEquals(['approved', 'draft', 'reference', 'unclassified']),
    );
  });

  test('slot filtering handles every underscore-based meal type', () {
    const types = [
      'breakfast',
      'morning_snack',
      'lunch',
      'afternoon_snack',
      'dinner',
    ];
    final catalog = [
      for (final type in types) _meal(code: type, mealType: type),
    ];

    for (final type in types) {
      expect(
        selector
            .eligibleMeals(
              catalog: catalog,
              profile: NutritionProfileEntity.empty('user-1'),
              mealType: type,
            )
            .map((meal) => meal.code),
        [type],
        reason: type,
      );
    }
  });

  test(
    'slot-scoped replacement accepts unclassified and keeps allergy guard',
    () {
      final profile = NutritionProfileEntity.empty('user-1').copyWith(
        restrictions: const <FoodRestrictionEntity>[
          FoodRestrictionEntity(type: 'allergy', itemName: 'đậu phộng'),
        ],
      );

      final replacement = selector.replacementFor(
        catalog: <MealCatalogItemModel>[
          _meal(code: 'current'),
          _meal(code: 'peanut', ingredients: const ['Đậu phộng rang']),
          _meal(code: 'wrong-slot', mealType: 'dinner'),
          _meal(
            code: 'wildcard',
            mealType: 'unclassified',
            allergenStatus: 'verified_none',
          ),
        ],
        profile: profile,
        mealType: 'breakfast',
        currentCode: 'current',
        replacementCount: 0,
      );

      expect(replacement?.code, 'wildcard');
    },
  );

  test('slot-scoped replacement excludes condition-tag conflict', () {
    final profile = NutritionProfileEntity.empty(
      'user-1',
    ).copyWith(currentStatus: 'Đang bị trào ngược dạ dày');

    final candidates = selector.eligibleMeals(
      catalog: <MealCatalogItemModel>[
        _meal(
          code: 'avoid',
          avoidConditionTags: const ['trào ngược'],
          constraintStatus: 'verified',
        ),
        _meal(code: 'safe', constraintStatus: 'verified'),
      ],
      profile: profile,
      mealType: 'breakfast',
    );

    expect(candidates.map((item) => item.code), orderedEquals(['safe']));
  });

  test('known allergy excludes unknown and conflicting metadata', () {
    final profile = NutritionProfileEntity.empty('user-1').copyWith(
      restrictions: const <FoodRestrictionEntity>[
        FoodRestrictionEntity(type: 'allergy', itemName: 'peanut'),
      ],
    );

    final candidates = selector.eligibleMeals(
      catalog: <MealCatalogItemModel>[
        _meal(code: 'unknown'),
        _meal(
          code: 'conflict',
          ingredients: const ['peanut'],
          allergenStatus: 'verified_present',
          allergenTags: const ['peanut'],
        ),
        _meal(
          code: 'verified-safe',
          ingredients: const ['rice'],
          allergenStatus: 'verified_none',
        ),
      ],
      profile: profile,
    );

    expect(candidates.map((item) => item.code), ['verified-safe']);
  });

  test(
    'condition and avoid-food constraints require reviewed ingredient data',
    () {
      final conditionCandidates = selector.eligibleMeals(
        catalog: <MealCatalogItemModel>[
          _meal(code: 'condition-unknown'),
          _meal(code: 'condition-reviewed', constraintStatus: 'verified'),
        ],
        profile: NutritionProfileEntity.empty('user-1'),
        conditions: const {'diabetes'},
      );
      expect(conditionCandidates.map((item) => item.code), [
        'condition-reviewed',
      ]);

      final avoidProfile = NutritionProfileEntity.empty('user-1').copyWith(
        restrictions: const <FoodRestrictionEntity>[
          FoodRestrictionEntity(type: 'avoid', itemName: 'garlic'),
        ],
      );
      final avoidCandidates = selector.eligibleMeals(
        catalog: <MealCatalogItemModel>[
          _meal(code: 'not-reviewed', ingredients: const ['rice']),
          _meal(
            code: 'contains-garlic',
            ingredients: const ['garlic'],
            constraintStatus: 'verified',
          ),
          _meal(
            code: 'verified-without-garlic',
            ingredients: const ['rice'],
            constraintStatus: 'verified',
          ),
        ],
        profile: avoidProfile,
      );
      expect(avoidCandidates.map((item) => item.code), [
        'verified-without-garlic',
      ]);
    },
  );

  test(
    'nutrition goal uses verified values instead of legacy macro fields',
    () {
      final candidates = selector.eligibleMeals(
        catalog: <MealCatalogItemModel>[
          _meal(code: 'legacy-only'),
          _meal(
            code: 'verified',
            verifiedNutrients: const {'energy_kcal': 300},
          ),
        ],
        profile: NutritionProfileEntity.empty('user-1'),
        goals: const {'lose_weight'},
      );

      expect(candidates.map((item) => item.code), ['verified']);
    },
  );

  test('unparsed allergy note blocks every candidate', () {
    expect(
      selector.eligibleMeals(
        catalog: [_meal(code: 'candidate')],
        profile: NutritionProfileEntity.empty('user-1'),
        unparsedAllergyDetails: true,
      ),
      isEmpty,
    );
  });
}

MealCatalogItemModel _meal({
  required String code,
  String mealType = 'breakfast',
  String metadataStatus = 'approved',
  bool isPlanEligible = true,
  bool isActive = true,
  List<String> ingredients = const [],
  List<String> avoidConditionTags = const [],
  List<String> allergenTags = const [],
  String allergenStatus = 'unknown',
  String constraintStatus = 'approved',
  Map<String, Object?>? verifiedNutrients,
}) {
  return MealCatalogItemModel(
    code: code,
    mealType: mealType,
    mealName: 'Món $code',
    description: 'Mô tả',
    cookingInstructions: 'Chế biến',
    calories: 300,
    protein: 10,
    carbs: 40,
    fat: 8,
    fiber: 4,
    waterMl: 0,
    ingredients: ingredients,
    cookingSteps: const ['Bước 1'],
    allergenTags: allergenTags,
    allergenVerificationStatus: allergenStatus,
    avoidConditionTags: avoidConditionTags,
    metadataStatus: metadataStatus,
    constraintMetadataStatus: constraintStatus,
    verifiedNutrients: verifiedNutrients,
    isPlanEligible: isPlanEligible,
    isActive: isActive,
    createdAt: '2026-08-02T00:00:00Z',
    updatedAt: '2026-08-02T00:00:00Z',
  );
}
