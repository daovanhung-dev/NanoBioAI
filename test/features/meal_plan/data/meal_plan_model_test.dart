import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

void main() {
  test('MealPlanModel maps cooking instructions for JSON and SQLite', () {
    final json = {
      'id': 'meal-1',
      'user_id': 'u1',
      'plan_date': '2026-06-17',
      'meal_type': 'breakfast',
      'meal_name': 'Oatmeal',
      'description': 'Light breakfast',
      'calories': 350,
      'protein': 12.5,
      'carbs': 45,
      'fat': 8,
      'fiber': 6,
      'water_ml': 300,
      'meal_order': 1,
      'start_time': '07:00',
      'end_time': '07:30',
      'cooking_instructions': 'Cook oats. Add fruit.',
      'is_completed': 0,
      'ai_generated': 1,
      'created_at': '2026-06-16T08:00:00',
      'updated_at': '2026-06-16T08:00:00',
    };

    final model = MealPlanModel.fromJson(json);

    expect(model.cookingInstructions, 'Cook oats. Add fruit.');
    expect(model.startTime, '07:00');
    expect(model.endTime, '07:30');
    expect(model.toMap()['start_time'], '07:00');
    expect(model.toJson()['end_time'], '07:30');
    expect(model.toMap()['cooking_instructions'], 'Cook oats. Add fruit.');
    expect(model.toJson()['cooking_instructions'], 'Cook oats. Add fruit.');
    expect(model.toEntity().cookingInstructions, 'Cook oats. Add fruit.');
  });

  test(
    'MealPlanModel defaults missing cooking instructions to empty string',
    () {
      final map = {
        'id': 'meal-1',
        'user_id': 'u1',
        'plan_date': '2026-06-17',
        'meal_type': 'breakfast',
        'meal_name': 'Oatmeal',
        'description': 'Light breakfast',
        'calories': 350,
        'protein': 12.5,
        'carbs': 45,
        'fat': 8,
        'fiber': 6,
        'water_ml': 300,
        'meal_order': 1,
        'is_completed': 0,
        'ai_generated': 1,
        'created_at': '2026-06-16T08:00:00',
        'updated_at': '2026-06-16T08:00:00',
      };

      final model = MealPlanModel.fromMap(map);

      expect(model.cookingInstructions, '');
      expect(model.startTime, '07:00');
      expect(model.endTime, '07:30');
    },
  );
}
