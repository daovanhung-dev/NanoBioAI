import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  test('unclassified Supabase meals are valid candidates for every meal slot', () {
    final meals = List<MealCatalogItemModel>.generate(
      5,
      (index) => _meal('src_${index + 1}'),
    );
    final catalog = AiCatalogBundle(
      meals: meals,
      exercises: const [],
      scheduleTasks: const [],
    );

    for (final slot in MealPlanAiNormalizer.mealSlots) {
      expect(
        catalog.mealsForType(slot.type).map((item) => item.code).toSet(),
        equals(meals.map((item) => item.code).toSet()),
      );
    }
  });

  test('normalizer accepts AI assignment of unclassified meals to five slots', () {
    final catalog = AiCatalogBundle(
      meals: List<MealCatalogItemModel>.generate(
        5,
        (index) => _meal('src_${index + 1}'),
      ),
      exercises: const [],
      scheduleTasks: const [],
    );
    const normalizer = MealPlanAiNormalizer();

    final items = <Map<String, Object?>>[
      for (var i = 0; i < MealPlanAiNormalizer.mealSlots.length; i++)
        {
          'day': 1,
          'meal_type': MealPlanAiNormalizer.mealSlots[i].type,
          'meal_code': 'src_${i + 1}',
          'portion_level': 'standard',
          'priority': i + 1,
        },
    ];

    final validated = normalizer.validateCodeItems(
      items: items,
      catalog: catalog,
      startDay: 1,
      days: 1,
      usedCodeCounts: const {},
    );

    expect(validated, hasLength(5));
    expect(validated.map((item) => item['meal_code']), [
      'src_1',
      'src_2',
      'src_3',
      'src_4',
      'src_5',
    ]);
  });

  test('normalizer still rejects a code that is not in Supabase catalog', () {
    final catalog = AiCatalogBundle(
      meals: List<MealCatalogItemModel>.generate(
        5,
        (index) => _meal('src_${index + 1}'),
      ),
      exercises: const [],
      scheduleTasks: const [],
    );
    const normalizer = MealPlanAiNormalizer();

    final items = <Map<String, Object?>>[
      for (var i = 0; i < MealPlanAiNormalizer.mealSlots.length; i++)
        {
          'day': 1,
          'meal_type': MealPlanAiNormalizer.mealSlots[i].type,
          'meal_code': i == 0 ? 'not_on_supabase' : 'src_${i + 1}',
          'portion_level': 'standard',
          'priority': i + 1,
        },
    ];

    expect(
      () => normalizer.validateCodeItems(
        items: items,
        catalog: catalog,
        startDay: 1,
        days: 1,
        usedCodeCounts: const {},
      ),
      throwsFormatException,
    );
  });

  test('local fallback can build a day using only unclassified Supabase meals', () {
    final catalog = AiCatalogBundle(
      meals: List<MealCatalogItemModel>.generate(
        5,
        (index) => _meal('src_${index + 1}'),
      ),
      exercises: const [],
      scheduleTasks: const [],
    );
    const normalizer = MealPlanAiNormalizer();

    final fallback = normalizer.fallbackCodeItems(
      catalog: catalog,
      startDay: 1,
      days: 1,
      usedCodeCounts: const {},
    );

    expect(fallback, hasLength(5));
    expect(fallback.map((item) => item['meal_code']).toSet(), hasLength(5));
  });
}

MealCatalogItemModel _meal(String code) {
  return MealCatalogItemModel(
    code: code,
    mealType: 'unclassified',
    mealName: 'Món $code',
    description: 'Mô tả',
    cookingInstructions: 'Chế biến',
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    waterMl: 0,
    metadataStatus: 'source_imported',
    constraintMetadataStatus: 'awaiting_professional_review',
    isPlanEligible: false,
    isActive: true,
    createdAt: '2026-08-16T00:00:00Z',
    updatedAt: '2026-08-16T00:00:00Z',
  );
}
