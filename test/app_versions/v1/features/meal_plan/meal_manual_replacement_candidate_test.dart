import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  const selector = MealCandidateSelector();

  test('manual replacement keeps same slot + unclassified and removes unsafe rows', () {
    final profile = NutritionProfileEntity.empty('user-1').copyWith(
      restrictions: const <FoodRestrictionEntity>[
        FoodRestrictionEntity(type: 'allergy', itemName: 'đậu phộng'),
      ],
      currentStatus: 'Đang bị trào ngược dạ dày',
    );

    final candidates = selector.eligibleMeals(
      catalog: <MealCatalogItemModel>[
        _meal(code: 'safe-breakfast', mealType: 'breakfast'),
        _meal(code: 'safe-source', mealType: 'unclassified'),
        _meal(code: 'dinner-only', mealType: 'dinner'),
        _meal(code: 'fixture-meal-breakfast-v1', mealType: 'breakfast'),
        _meal(
          code: 'allergy-conflict',
          mealType: 'breakfast',
          ingredients: const <String>['Đậu phộng rang'],
        ),
        _meal(
          code: 'condition-conflict',
          mealType: 'unclassified',
          avoidConditionTags: const <String>['trào ngược'],
        ),
      ],
      profile: profile,
      mealType: 'breakfast',
      excludedCodes: const <String>{'current-code'},
    );

    expect(
      candidates.map((item) => item.code),
      orderedEquals(<String>['safe-breakfast', 'safe-source']),
    );
  });

  test('fixture rows are excluded even from full-plan candidate catalog', () {
    final candidates = selector.eligibleMeals(
      catalog: <MealCatalogItemModel>[
        _meal(code: 'fixture-meal-breakfast-v1', mealType: 'breakfast'),
        _meal(code: 'real-meal', mealType: 'unclassified'),
      ],
      profile: NutritionProfileEntity.empty('user-1'),
    );

    expect(candidates.map((item) => item.code), orderedEquals(['real-meal']));
  });
}

MealCatalogItemModel _meal({
  required String code,
  required String mealType,
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
    createdAt: '2026-08-16T00:00:00Z',
    updatedAt: '2026-08-16T00:00:00Z',
  );
}
