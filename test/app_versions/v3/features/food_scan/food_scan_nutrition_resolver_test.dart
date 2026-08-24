import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/application/food_scan_nutrition_resolver.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/domain/entities/food_scan_models.dart';

void main() {
  const resolver = FoodScanNutritionResolver();

  FoodScanItem item({
    required String name,
    required double grams,
    NutritionEstimate nutrition = const NutritionEstimate(
      caloriesKcal: 999,
      proteinG: 99,
      carbohydratesG: 99,
      fatG: 99,
    ),
  }) {
    return FoodScanItem(
      id: 'item-1',
      name: name,
      normalizedName: FoodScanNutritionResolver.normalizeFoodName(name),
      estimatedWeightGrams: grams,
      confirmedWeightGrams: grams,
      portionDescription: '',
      cookingMethod: '',
      ingredients: const [],
      possibleAllergens: const [],
      confidence: .9,
      nutrition: nutrition,
      nutritionSource: 'ai_fallback',
    );
  }

  test('internal catalog overrides core AI nutrition for known food', () {
    final resolved = resolver.resolveItem(item(name: 'Cơm trắng', grams: 100));

    expect(resolved.nutritionSource, 'internal_catalog');
    expect(resolved.catalogCode, 'rice_white_cooked');
    expect(resolved.nutrition.caloriesKcal, closeTo(130, .01));
    expect(resolved.nutrition.carbohydratesG, closeTo(28.2, .01));
  });

  test('changing grams recalculates deterministically without vision AI', () {
    final initial = resolver.resolveItem(item(name: 'Cơm trắng', grams: 100));
    final updated = resolver.recalculate(initial, 200);

    expect(updated.confirmedWeightGrams, 200);
    expect(updated.nutrition.caloriesKcal, closeTo(260, .01));
  });

  test('unknown food keeps AI fallback instead of weak match', () {
    final source = item(name: 'Món đặc biệt hoàn toàn lạ', grams: 150);
    final resolved = resolver.resolveItem(source);

    expect(resolved.nutritionSource, 'ai_fallback');
    expect(resolved.nutrition.caloriesKcal, 999);
  });
}
