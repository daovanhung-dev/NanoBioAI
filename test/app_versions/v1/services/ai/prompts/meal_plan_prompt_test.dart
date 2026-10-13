import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart';

void main() {
  test('meal prompt includes the requested day and prior use counts', () {
    final prompt = MealPlanPrompt.generate(
      startDate: DateTime(2026, 10, 13),
      startDay: 6,
      days: 1,
      catalog: const [],
      usedMealCodeCounts: const {'br_oat_egg': 2, 'meal_other': 1},
    );

    expect(prompt, contains('"day": 6'));
    expect(prompt, isNot(contains('"day": 1')));
    expect(prompt, contains('{"br_oat_egg":2,"meal_other":1}'));
    expect(prompt, contains('Không lặp lại meal_code đã xuất hiện trước đó'));
    expect(prompt, contains('Không lặp lại tên món đã xuất hiện trước đó'));
  });
}
