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
