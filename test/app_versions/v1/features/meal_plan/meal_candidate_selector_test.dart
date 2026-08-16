import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  const selector = MealCandidateSelector();

  test('full-plan generation keeps active Supabase meals except fixtures', () {
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

  test('slot-scoped replacement accepts unclassified and keeps allergy guard', () {
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
        _meal(code: 'wildcard', mealType: 'unclassified'),
      ],
      profile: profile,
      mealType: 'breakfast',
      currentCode: 'current',
      replacementCount: 0,
    );

    expect(replacement?.code, 'wildcard');
  });

  test('slot-scoped replacement excludes condition-tag conflict', () {
    final profile = NutritionProfileEntity.empty('user-1').copyWith(
      currentStatus: 'Đang bị trào ngược dạ dày',
    );

    final candidates = selector.eligibleMeals(
      catalog: <MealCatalogItemModel>[
        _meal(
          code: 'avoid',
          avoidConditionTags: const ['trào ngược'],
        ),
        _meal(code: 'safe'),
      ],
      profile: profile,
      mealType: 'breakfast',
    );

    expect(candidates.map((item) => item.code), orderedEquals(['safe']));
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
    avoidConditionTags: avoidConditionTags,
    metadataStatus: metadataStatus,
    constraintMetadataStatus: metadataStatus,
    isPlanEligible: isPlanEligible,
    isActive: isActive,
    createdAt: '2026-08-02T00:00:00Z',
    updatedAt: '2026-08-02T00:00:00Z',
  );
}
