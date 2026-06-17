import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';

void main() {
  test('normalizes AI dates and ids into deterministic weekly meals', () {
    final meals = const MealPlanAiNormalizer().normalize(
      items: _items(DateTime(2025, 1, 1)),
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

    expect(meals[5].id, 'meal_u1_2026-06-19_1');
    expect(meals[5].planDate, '2026-06-19');
  });

  test('throws when AI response is missing a meal record', () {
    final items = _items(DateTime(2025, 1, 1))..removeLast();

    expect(
      () => const MealPlanAiNormalizer().normalize(
        items: items,
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        createdAt: '2026-06-17T08:00:00',
      ),
      throwsFormatException,
    );
  });

  test('throws when AI response is missing meal_type', () {
    final items = _items(DateTime(2025, 1, 1));
    items.first.remove('meal_type');

    expect(
      () => const MealPlanAiNormalizer().normalize(
        items: items,
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        createdAt: '2026-06-17T08:00:00',
      ),
      throwsFormatException,
    );
  });
}

List<Map<String, Object?>> _items(DateTime aiStartDate) {
  return [
    for (var day = 0; day < 7; day++)
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'id': 'ai-id-$day-${slot.type}',
          'user_id': 'wrong-user',
          'plan_date': _dateKey(aiStartDate.add(Duration(days: day))),
          'meal_type': slot.type,
          'start_time': '00:00',
          'end_time': '00:01',
          'meal_name': 'Meal ${slot.order}',
          'description': 'Description ${slot.order}',
          'calories': 300 + slot.order,
          'protein': 10.0,
          'carbs': 30.0,
          'fat': 8.0,
          'fiber': 4.0,
          'water_ml': 300,
          'meal_order': 99,
          'cooking_instructions': 'Cook',
          'is_completed': 1,
          'ai_generated': 0,
          'created_at': '2025-01-01T00:00:00',
          'updated_at': '2025-01-01T00:00:00',
        },
  ];
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
