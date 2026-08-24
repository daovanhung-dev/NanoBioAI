import 'food_scan_nutrition_resolver.dart';
import '../domain/entities/food_scan_models.dart';

class FoodScanHealthRuleResult {
  final List<String> warnings;
  final bool hasAllergyMatch;

  const FoodScanHealthRuleResult({
    required this.warnings,
    required this.hasAllergyMatch,
  });
}

/// Deterministic safety layer executed before the health AI prompt.
///
/// This engine deliberately avoids inventing clinical nutrient thresholds.
/// It only enforces facts already present in the user's profile: declared
/// allergies/restrictions and ingredients/allergens detected in the meal.
class FoodScanHealthRuleEngine {
  const FoodScanHealthRuleEngine();

  FoodScanHealthRuleResult evaluate({
    required Map<String, Object?> healthContext,
    required List<FoodScanItem> items,
  }) {
    final declaredAllergies = _names(
      healthContext['food_allergies'],
      keys: const ['allergy_name', 'name'],
    );
    final declaredRestrictions = _names(
      healthContext['food_restrictions'],
      keys: const ['item_name', 'name'],
    );

    final mealAllergens = <String>{};
    final mealIngredients = <String>{};
    for (final item in items) {
      mealAllergens.addAll(item.possibleAllergens);
      mealIngredients
        ..add(item.name)
        ..addAll(item.ingredients);
    }

    final warnings = <String>[];
    var allergyMatch = false;

    for (final allergy in declaredAllergies) {
      final match = mealAllergens.any((value) => _matches(value, allergy)) ||
          mealIngredients.any((value) => _matches(value, allergy));
      if (!match) continue;
      allergyMatch = true;
      warnings.add(
        'Cảnh báo dị ứng: món ăn có khả năng liên quan đến "$allergy" '
        'mà bạn đã khai báo. Không thể xác nhận thành phần chỉ bằng hình ảnh.',
      );
    }

    for (final restriction in declaredRestrictions) {
      final match = mealAllergens.any((value) => _matches(value, restriction)) ||
          mealIngredients.any((value) => _matches(value, restriction));
      if (!match) continue;
      warnings.add(
        'Hạn chế thực phẩm: món ăn có khả năng chứa/liên quan đến '
        '"$restriction" trong hồ sơ của bạn.',
      );
    }

    return FoodScanHealthRuleResult(
      warnings: warnings.toSet().take(20).toList(growable: false),
      hasAllergyMatch: allergyMatch,
    );
  }

  List<String> _names(Object? source, {required List<String> keys}) {
    if (source is! List) return const [];
    final result = <String>[];
    for (final row in source.whereType<Map>()) {
      for (final key in keys) {
        final value = row[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          result.add(value);
          break;
        }
      }
    }
    return result;
  }

  bool _matches(String left, String right) {
    final a = FoodScanNutritionResolver.normalizeFoodName(left);
    final b = FoodScanNutritionResolver.normalizeFoodName(right);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }
}
