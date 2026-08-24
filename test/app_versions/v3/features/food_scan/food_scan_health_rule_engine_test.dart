import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/application/food_scan_health_rule_engine.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/domain/entities/food_scan_models.dart';

void main() {
  const engine = FoodScanHealthRuleEngine();

  const peanutItem = FoodScanItem(
    id: '1',
    name: 'Gỏi có đậu phộng',
    normalizedName: 'goi co dau phong',
    estimatedWeightGrams: 200,
    confirmedWeightGrams: 200,
    portionDescription: '1 đĩa',
    cookingMethod: 'trộn',
    ingredients: ['rau', 'đậu phộng'],
    possibleAllergens: ['đậu phộng'],
    confidence: .9,
    nutrition: NutritionEstimate(caloriesKcal: 300),
    nutritionSource: 'ai_fallback',
  );

  test('declared allergy produces deterministic warning', () {
    final result = engine.evaluate(
      healthContext: {
        'food_allergies': [
          {'allergy_name': 'Đậu phộng'},
        ],
      },
      items: const [peanutItem],
    );

    expect(result.hasAllergyMatch, isTrue);
    expect(result.warnings.join(' '), contains('Cảnh báo dị ứng'));
    expect(result.warnings.join(' '), contains('Đậu phộng'));
  });

  test('engine does not invent disease rules without approved threshold data', () {
    final result = engine.evaluate(
      healthContext: {
        'health_conditions': [
          {'condition_name': 'Tăng huyết áp', 'severity_level': 2},
        ],
      },
      items: const [peanutItem],
    );

    expect(result.hasAllergyMatch, isFalse);
    expect(result.warnings, isEmpty);
  });
}
