import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';

/// Resolves bundled food photography extracted from "Sức Khỏe Từ Nhà Bếp".
///
/// Images are keyed by a deterministic, accent-free slug of the displayed dish
/// name. Repeated recipes therefore reuse the same local WebP asset without
/// changing the meal-plan persistence contract.
abstract final class MealImageResolver {
  static const String assetRoot = 'assets/images/meals/pdf_health_book';

  static String assetPathFor(MealPlanEntity meal) {
    return assetPathForName(meal.mealName);
  }

  static String assetPathForName(String mealName) {
    return '$assetRoot/${slugFor(mealName)}.webp';
  }

  static String slugFor(String value) {
    var result = value.trim().toLowerCase();
    result = result
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'unknown_meal' : result;
  }
}
