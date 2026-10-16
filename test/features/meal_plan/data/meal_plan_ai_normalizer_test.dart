import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';

void main() {
  const catalog = AiCatalogBundle(
    meals: AiCatalogSeedData.meals,
    exercises: AiCatalogSeedData.exercises,
    scheduleTasks: AiCatalogSeedData.scheduleTasks,
  );

  test('normalizes AI codes into deterministic weekly meals', () {
    final meals = const MealPlanAiNormalizer().normalize(
      items: _items(),
      catalog: catalog,
      userId: 'u1',
      startDate: DateTime(2026, 6, 18),
      createdAt: '2026-06-17T08:00:00',
    );

    expect(meals, hasLength(35));
    expect(meals.first.id, 'meal_u1_2026-06-18_1');
    expect(meals.first.userId, 'u1');
    expect(meals.first.planDate, '2026-06-18');
    expect(meals.first.mealType, 'breakfast');
    expect(meals.first.mealOrder, 1);
    expect(meals.first.startTime, '07:00');
    expect(meals.first.endTime, '07:30');
    expect(meals.first.mealName, 'Cháo yến mạch trứng gà');
    expect(meals.first.description, contains('Bữa sáng'));
    expect(meals.first.cookingInstructions, contains('Nấu'));
    expect(meals.first.mealName, isNot(contains('Bua')));
    expect(meals.first.isCompleted, isFalse);
    expect(meals.first.aiGenerated, isTrue);

    final firstDay = meals
        .where((meal) => meal.planDate == '2026-06-18')
        .map((meal) => meal.mealType)
        .toList();
    expect(firstDay, [
      'breakfast',
      'morning_snack',
      'lunch',
      'afternoon_snack',
      'dinner',
    ]);
  });

  test('throws when AI response contains a display text field', () {
    final items = _items();
    items.first['meal_name'] = 'Com khong dau';

    expect(
      () => const MealPlanAiNormalizer().normalize(
        items: items,
        catalog: catalog,
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        createdAt: '2026-06-17T08:00:00',
      ),
      throwsFormatException,
    );
  });

  test('throws when AI response uses an unknown meal code', () {
    final items = _items();
    items.first['meal_code'] = 'unknown_meal';

    expect(
      () => const MealPlanAiNormalizer().normalize(
        items: items,
        catalog: catalog,
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        createdAt: '2026-06-17T08:00:00',
      ),
      throwsFormatException,
    );
  });

  test('rejects meal codes already used earlier in the week', () {
    final eligibleByType = {
      for (final slot in MealPlanAiNormalizer.mealSlots)
        slot.type: {
          AiCatalogSeedData.meals
              .firstWhere((meal) => meal.mealType == slot.type)
              .code,
        },
    };
    final fallback = [
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'day': 3,
          'meal_type': slot.type,
          'meal_code': eligibleByType[slot.type]!.single,
        },
    ];
    expect(
      () => const MealPlanAiNormalizer().validateCodeItems(
        items: fallback,
        catalog: catalog,
        startDay: 3,
        days: 1,
        usedCodeCounts: {
          for (final codes in eligibleByType.values)
            for (final code in codes) code: 2,
        },
        eligibleCodesByType: eligibleByType,
      ),
      throwsFormatException,
    );
  });

  test('rejects active candidate meals that have not passed review', () {
    final candidate = _unreviewedCandidate();
    final candidateCatalog = AiCatalogBundle(
      meals: [...catalog.meals, candidate],
      exercises: catalog.exercises,
      scheduleTasks: catalog.scheduleTasks,
    );
    final items = _items().take(MealPlanAiNormalizer.mealsPerDay).toList();
    items.first['meal_code'] = candidate.code;

    expect(
      () => const MealPlanAiNormalizer().validateCodeItems(
        items: items,
        catalog: candidateCatalog,
        startDay: 1,
        days: 1,
        usedCodeCounts: const {},
      ),
      throwsFormatException,
    );
  });

  test(
    'hydrates explicitly eligible wellness candidate without unverified nutrition',
    () {
      final candidate = _unreviewedCandidate();
      final candidateCatalog = AiCatalogBundle(
        meals: [...catalog.meals, candidate],
        exercises: catalog.exercises,
        scheduleTasks: catalog.scheduleTasks,
      );
      final items = _items().take(MealPlanAiNormalizer.mealsPerDay).toList();
      items.first['meal_code'] = candidate.code;
      final eligibleCodesByType = {
        for (final item in items)
          item['meal_type'] as String: {item['meal_code'] as String},
      };

      final meals = const MealPlanAiNormalizer().normalize(
        items: items,
        catalog: candidateCatalog,
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        days: 1,
        createdAt: '2026-06-17T08:00:00',
        eligibleCodesByType: eligibleCodesByType,
      );

      final hydrated = meals.first;
      expect(hydrated.catalogCode, candidate.code);
      expect(hydrated.mealName, candidate.mealName);
      expect(hydrated.ingredients, candidate.ingredients);
      expect(hydrated.cookingInstructions, candidate.cookingInstructions);
      expect(hydrated.calories, 0);
      expect(hydrated.protein, 0);
      expect(hydrated.sodiumMg, isNull);
      expect(hydrated.nutritionStatus, 'estimated_unverified');
      expect(hydrated.benefits, isEmpty);
    },
  );

  test('accepts a source-verified eligible meal with reviewed constraints', () {
    final reviewed = MealCatalogItemModel(
      code: 'reviewed_breakfast',
      mealType: 'breakfast',
      mealName: 'Bữa sáng đã duyệt',
      description: 'Mô tả',
      cookingInstructions: 'Chế biến',
      calories: 320,
      protein: 12,
      carbs: 42,
      fat: 8,
      fiber: 4,
      waterMl: 0,
      nutritionStatus: 'verified',
      verifiedNutrients: const {'energy_kcal': 320},
      nutritionEvidenceSource: 'reviewed source',
      nutritionEvidenceDate: '2026-10-16',
      nutritionEvidenceVersion: 'v1',
      constraintMetadataStatus: 'verified',
      allergenVerificationStatus: 'verified_none',
      allergenEvidenceSource: 'reviewed source',
      metadataStatus: 'source_verified',
      isPlanEligible: true,
      sourceName: 'Reviewed source',
      sourceHash: List.filled(64, 'a').join(),
      ingredients: const ['gạo'],
      cookingSteps: const ['Nấu chín'],
      servingSize: '1 khẩu phần',
      createdAt: '2026-10-16T00:00:00Z',
      updatedAt: '2026-10-16T00:00:00Z',
    );
    final reviewedCatalog = AiCatalogBundle(
      meals: [...catalog.meals, reviewed],
      exercises: catalog.exercises,
      scheduleTasks: catalog.scheduleTasks,
    );

    expect(
      const MealPlanAiNormalizer().validateCodeItemForSlot(
        item: {'day': 1, 'meal_type': 'breakfast', 'meal_code': reviewed.code},
        catalog: reviewedCatalog,
        day: 1,
        mealType: 'breakfast',
        usedCodeCounts: const {},
        eligibleCodesByType: {
          'breakfast': {reviewed.code},
        },
      ),
      [
        {'day': 1, 'meal_type': 'breakfast', 'meal_code': reviewed.code},
      ],
    );
  });
}

List<Map<String, Object?>> _items() {
  final byType = <String, List<String>>{
    for (final slot in MealPlanAiNormalizer.mealSlots)
      slot.type: AiCatalogSeedData.meals
          .where((item) => item.mealType == slot.type)
          .map((item) => item.code)
          .toList(),
  };

  return [
    for (var day = 1; day <= 7; day++)
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'day': day,
          'meal_type': slot.type,
          'meal_code':
              byType[slot.type]![(day - 1) % byType[slot.type]!.length],
        },
  ];
}

MealCatalogItemModel _unreviewedCandidate() => MealCatalogItemModel(
  code: 'nabi_vn_candidate',
  mealType: 'unclassified',
  mealName: 'Món chờ rà soát',
  description: 'Mô tả',
  cookingInstructions: 'Bước nấu chưa duyệt',
  calories: 350,
  protein: 12,
  carbs: 40,
  fat: 10,
  fiber: 5,
  waterMl: 0,
  nutritionStatus: 'estimated_unverified',
  constraintMetadataStatus: 'awaiting_professional_review',
  metadataStatus: 'ai_generated_needs_review',
  isPlanEligible: false,
  sourceName:
      'NaBi Vietnam original-recipe compilation (AI-assisted, unverified)',
  sourceHash: List.filled(64, 'b').join(),
  allergenVerificationStatus: 'unknown',
  ingredients: const ['nguyên liệu chưa rà soát'],
  cookingSteps: const ['Bước chưa rà soát'],
  isActive: true,
  createdAt: '2026-10-16T00:00:00Z',
  updatedAt: '2026-10-16T00:00:00Z',
);
