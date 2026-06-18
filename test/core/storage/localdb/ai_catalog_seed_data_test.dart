import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/services/ai/ai_vietnamese_text_validator.dart';

void main() {
  test('meal catalog has forty unique active Vietnamese items', () {
    final meals = AiCatalogSeedData.meals;

    expect(meals, hasLength(40));
    expect(meals.map((item) => item.code).toSet(), hasLength(40));

    for (final slot in MealPlanAiNormalizer.mealSlots) {
      expect(meals.where((item) => item.mealType == slot.type), hasLength(8));
    }

    for (final item in meals) {
      expect(
        AIVietnameseTextValidator.isValidDisplayText(item.mealName),
        isTrue,
      );
      expect(
        AIVietnameseTextValidator.isValidDisplayText(item.description),
        isTrue,
      );
      expect(
        AIVietnameseTextValidator.isValidDisplayText(item.cookingInstructions),
        isTrue,
      );
    }
  });

  test(
    'exercise and schedule catalogs have unique Vietnamese display text',
    () {
      final exercises = AiCatalogSeedData.exercises;
      final scheduleTasks = AiCatalogSeedData.scheduleTasks;

      expect(exercises, hasLength(16));
      expect(exercises.map((item) => item.code).toSet(), hasLength(16));
      expect(scheduleTasks, hasLength(3));
      expect(scheduleTasks.map((item) => item.code).toSet(), hasLength(3));

      for (final item in exercises) {
        expect(
          AIVietnameseTextValidator.isValidDisplayText(item.title),
          isTrue,
        );
        expect(
          AIVietnameseTextValidator.isValidDisplayText(item.description),
          isTrue,
        );
        expect(
          AIVietnameseTextValidator.isValidDisplayText(item.encouragement),
          isTrue,
        );
      }

      for (final item in scheduleTasks) {
        expect(
          AIVietnameseTextValidator.isValidDisplayText(item.title),
          isTrue,
        );
        expect(
          AIVietnameseTextValidator.isValidDisplayText(item.description),
          isTrue,
        );
        expect(
          AIVietnameseTextValidator.isValidDisplayText(item.encouragement),
          isTrue,
        );
      }
    },
  );
}
