import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_catalog_detail_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';

class MealDetailContent {
  const MealDetailContent({
    required this.mealName,
    required this.topicName,
    required this.description,
    required this.ingredients,
    required this.cookingSteps,
    required this.benefits,
    required this.servingSize,
    required this.allergenTags,
    required this.avoidConditionTags,
    required this.sourceLabel,
    required this.showNutrition,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.waterMl,
  });

  final String mealName;
  final String topicName;
  final String description;
  final List<String> ingredients;
  final List<String> cookingSteps;
  final String benefits;
  final String servingSize;
  final List<String> allergenTags;
  final List<String> avoidConditionTags;
  final String sourceLabel;
  final bool showNutrition;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int waterMl;

  bool get hasWarnings => allergenTags.isNotEmpty || avoidConditionTags.isNotEmpty;
  bool get hasRecipe => ingredients.isNotEmpty || cookingSteps.isNotEmpty;
}

abstract final class MealDetailContentFormatter {
  static MealDetailContent fromMeal(MealPlanEntity meal) {
    final detail = meal.catalogDetail;
    final mealName = _firstNonEmpty([detail?.mealName, meal.mealName]);
    final topicName = _firstNonEmpty([detail?.healthTopicName, meal.topicName]);
    final description = _description(detail, meal);
    final ingredients = _dedupeLines(
      detail != null && detail.ingredients.isNotEmpty
          ? detail.ingredients
          : meal.ingredients,
      sanitizeIngredient: true,
    );
    final cookingSteps = _cookingSteps(detail, meal);
    final benefits = _firstNonEmpty([detail?.benefits, meal.benefits]);
    final servingSize = _firstNonEmpty([detail?.servingSize, meal.servingSize]);
    final allergenTags = _dedupeLines(
      detail != null && detail.allergenTags.isNotEmpty
          ? detail.allergenTags
          : meal.allergenTags,
    );
    final avoidConditionTags = _dedupeLines(
      detail != null && detail.avoidConditionTags.isNotEmpty
          ? detail.avoidConditionTags
          : meal.conditionTags,
    );

    final nutritionMissing = detail != null &&
        detail.nutritionStatus.trim().toLowerCase() == 'missing_source_data';
    final calories = detail?.calories ?? meal.calories;
    final protein = detail?.protein ?? meal.protein;
    final carbs = detail?.carbs ?? meal.carbs;
    final fat = detail?.fat ?? meal.fat;
    final fiber = detail?.fiber ?? meal.fiber;
    final waterMl = detail?.waterMl ?? meal.waterMl;
    final hasPositiveNutrition = calories > 0 ||
        protein > 0 ||
        carbs > 0 ||
        fat > 0 ||
        fiber > 0 ||
        waterMl > 0;

    return MealDetailContent(
      mealName: mealName,
      topicName: topicName,
      description: description,
      ingredients: ingredients,
      cookingSteps: cookingSteps,
      benefits: benefits,
      servingSize: servingSize,
      allergenTags: allergenTags,
      avoidConditionTags: avoidConditionTags,
      sourceLabel: _sourceLabel(detail, meal),
      showNutrition: !nutritionMissing && hasPositiveNutrition,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      waterMl: waterMl,
    );
  }

  static String _description(
    MealCatalogDetailEntity? detail,
    MealPlanEntity meal,
  ) {
    final description = _firstNonEmpty([detail?.description, meal.description]);
    if (description.isEmpty) return '';

    final topicDescription = detail?.healthTopicDescription.trim() ?? '';
    if (topicDescription.isNotEmpty &&
        _normalizedText(description) == _normalizedText(topicDescription)) {
      return '';
    }

    return description;
  }

  static List<String> _cookingSteps(
    MealCatalogDetailEntity? detail,
    MealPlanEntity meal,
  ) {
    if (detail != null && detail.cookingSteps.isNotEmpty) {
      return _dedupeLines(detail.cookingSteps);
    }
    if (meal.cookingSteps.isNotEmpty) {
      return _dedupeLines(meal.cookingSteps);
    }

    final raw = _firstNonEmpty([
      detail?.cookingInstructions,
      meal.cookingInstructions,
    ]);
    return parseCookingInstructions(raw);
  }

  static List<String> parseCookingInstructions(String value) {
    var normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
    if (normalized.isEmpty) return const [];

    normalized = normalized.replaceAllMapped(
      RegExp(r'\s+(?=(?:bước\s*)?\d+[\.)\-:]\s*)', caseSensitive: false),
      (_) => '\n',
    );

    final values = normalized
        .split('\n')
        .expand((line) => line.split(RegExp(r'\s*[;•]\s*')))
        .map(_removeStepPrefix)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return _dedupeLines(values);
  }

  static String _sourceLabel(
    MealCatalogDetailEntity? detail,
    MealPlanEntity meal,
  ) {
    final source = _firstNonEmpty([detail?.sourceName, meal.provenanceSource]);
    if (source.isEmpty) return '';

    var label = source.trim();
    if (label == 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md') {
      label = 'Sức Khỏe Từ Nhà Bếp';
    } else {
      label = label
          .replaceFirst(RegExp(r'\.(md|pdf|txt)$', caseSensitive: false), '')
          .replaceAll('_', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final page = detail?.sourcePage;
    if (page != null && page > 0) {
      return '$label • Trang $page';
    }
    return label;
  }

  static List<String> _dedupeLines(
    Iterable<String> values, {
    bool sanitizeIngredient = false,
  }) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      var text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (sanitizeIngredient) {
        text = text.replaceFirst(RegExp(r'\s+:\s*$'), '').trim();
      }
      if (text.isEmpty) continue;
      final key = _normalizedText(text);
      if (!seen.add(key)) continue;
      result.add(text);
    }
    return List<String>.unmodifiable(result);
  }

  static String _removeStepPrefix(String value) {
    return value
        .trim()
        .replaceFirst(
          RegExp(r'^(?:bước\s*)?\d+[\.)\-:]?\s*', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'^[-–—]\s*'), '')
        .trim();
  }

  static String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _normalizedText(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[–—−]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ');
}
