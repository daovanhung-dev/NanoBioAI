import '../../domain/entities/meal_catalog_detail_entity.dart';
import '../../domain/entities/meal_plan_entity.dart';

class MealDetailContent {
  const MealDetailContent({
    required this.mealName,
    required this.description,
    required this.topicName,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.waterMl,
    required this.sugarG,
    required this.saturatedFatG,
    required this.sodiumMg,
    required this.cholesterolMg,
    required this.potassiumMg,
    required this.calciumMg,
    required this.ironMg,
    required this.nutritionStatus,
    required this.nutritionLabel,
    required this.showNutrition,
    required this.ingredients,
    required this.cookingSteps,
    required this.benefits,
    required this.allergenTags,
    required this.avoidConditionTags,
    required this.sourceLabel,
  });

  final String mealName;
  final String description;
  final String topicName;
  final String servingSize;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int waterMl;
  final double? sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final double? cholesterolMg;
  final double? potassiumMg;
  final double? calciumMg;
  final double? ironMg;
  final String nutritionStatus;
  final String nutritionLabel;
  final bool showNutrition;
  final List<String> ingredients;
  final List<String> cookingSteps;
  final String benefits;
  final List<String> allergenTags;
  final List<String> avoidConditionTags;
  final String sourceLabel;

  bool get hasRecipe => ingredients.isNotEmpty || cookingSteps.isNotEmpty;
  bool get hasWarnings => allergenTags.isNotEmpty || avoidConditionTags.isNotEmpty;
  bool get isEstimated => nutritionStatus == 'estimated_from_ingredients';
}

abstract final class MealDetailContentFormatter {
  static MealDetailContent fromMeal(MealPlanEntity meal) {
    final detail = meal.catalogDetail;
    final detailStatus = detail?.nutritionStatus.trim() ?? '';
    final snapshotStatus = meal.nutritionStatus.trim();
    final useCatalogNutrition =
        detail != null && detailStatus != 'missing_source_data';

    final calories = useCatalogNutrition ? detail.calories : meal.calories;
    final protein = useCatalogNutrition ? detail.protein : meal.protein;
    final carbs = useCatalogNutrition ? detail.carbs : meal.carbs;
    final fat = useCatalogNutrition ? detail.fat : meal.fat;
    final fiber = useCatalogNutrition ? detail.fiber : meal.fiber;
    final waterMl = useCatalogNutrition ? detail.waterMl : meal.waterMl;
    final sugarG = useCatalogNutrition ? detail.sugarG : meal.sugarG;
    final saturatedFatG =
        useCatalogNutrition ? detail.saturatedFatG : meal.saturatedFatG;
    final sodiumMg = useCatalogNutrition ? detail.sodiumMg : meal.sodiumMg;
    final cholesterolMg =
        useCatalogNutrition ? detail.cholesterolMg : meal.cholesterolMg;
    final potassiumMg =
        useCatalogNutrition ? detail.potassiumMg : meal.potassiumMg;
    final calciumMg = useCatalogNutrition ? detail.calciumMg : meal.calciumMg;
    final ironMg = useCatalogNutrition ? detail.ironMg : meal.ironMg;
    final effectiveStatus = detailStatus.isNotEmpty && useCatalogNutrition
        ? detailStatus
        : snapshotStatus.isNotEmpty
            ? snapshotStatus
            : _hasAnyNutrition(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugarG: sugarG,
                saturatedFatG: saturatedFatG,
                sodiumMg: sodiumMg,
                cholesterolMg: cholesterolMg,
                potassiumMg: potassiumMg,
                calciumMg: calciumMg,
                ironMg: ironMg,
              )
                ? 'snapshot'
                : 'missing_source_data';

    final ingredients = _preferList(detail?.ingredients, meal.ingredients);
    final cookingSteps = _preferList(
      detail?.cookingSteps,
      meal.cookingSteps.isNotEmpty
          ? meal.cookingSteps
          : _parseInstructions(meal.cookingInstructions),
    );

    return MealDetailContent(
      mealName: _prefer(detail?.mealName, meal.mealName),
      description: _prefer(detail?.description, meal.description),
      topicName: _prefer(detail?.healthTopicName, meal.topicName),
      servingSize: _prefer(detail?.servingSize, meal.servingSize),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      waterMl: waterMl,
      sugarG: sugarG,
      saturatedFatG: saturatedFatG,
      sodiumMg: sodiumMg,
      cholesterolMg: cholesterolMg,
      potassiumMg: potassiumMg,
      calciumMg: calciumMg,
      ironMg: ironMg,
      nutritionStatus: effectiveStatus,
      nutritionLabel: effectiveStatus == 'estimated_from_ingredients'
          ? 'Dinh dưỡng ước tính • 1 khẩu phần'
          : 'Dinh dưỡng • 1 khẩu phần',
      showNutrition: effectiveStatus != 'missing_source_data' &&
          _hasAnyNutrition(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugarG: sugarG,
            saturatedFatG: saturatedFatG,
            sodiumMg: sodiumMg,
            cholesterolMg: cholesterolMg,
            potassiumMg: potassiumMg,
            calciumMg: calciumMg,
            ironMg: ironMg,
          ),
      ingredients: ingredients,
      cookingSteps: cookingSteps,
      benefits: _prefer(detail?.benefits, meal.benefits),
      allergenTags: _preferList(detail?.allergenTags, meal.allergenTags),
      avoidConditionTags: _preferList(
        detail?.avoidConditionTags,
        meal.conditionTags,
      ),
      sourceLabel: _sourceLabel(detail, meal),
    );
  }

  static String _prefer(String? primary, String fallback) {
    final value = primary?.trim() ?? '';
    return value.isNotEmpty ? value : fallback.trim();
  }

  static List<String> _preferList(List<String>? primary, List<String> fallback) {
    final values = primary
            ?.map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (values.isNotEmpty) return values;
    return fallback
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _parseInstructions(String value) => value
      .replaceAll('\r', '\n')
      .split(RegExp(r'[\n;•]+'))
      .map(
        (line) => line.trim().replaceFirst(
              RegExp(
                r'^(?:bước\s*)?\d+[\.)\-:]?\s*',
                caseSensitive: false,
              ),
              '',
            ),
      )
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  static String _sourceLabel(
    MealCatalogDetailEntity? detail,
    MealPlanEntity meal,
  ) {
    if (detail != null) {
      final parts = <String>[
        detail.sourceName.trim(),
        if (detail.sourceChapter.trim().isNotEmpty) detail.sourceChapter.trim(),
        if (detail.sourceTopic.trim().isNotEmpty) detail.sourceTopic.trim(),
        if (detail.sourcePage != null) 'trang ${detail.sourcePage}',
      ].where((value) => value.isNotEmpty).toList(growable: false);
      if (parts.isNotEmpty) return parts.join(' • ');
    }
    return meal.provenanceSource.trim();
  }

  static bool _hasAnyNutrition({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required double? sugarG,
    required double? saturatedFatG,
    required double? sodiumMg,
    required double? cholesterolMg,
    required double? potassiumMg,
    required double? calciumMg,
    required double? ironMg,
  }) =>
      calories > 0 ||
      protein > 0 ||
      carbs > 0 ||
      fat > 0 ||
      fiber > 0 ||
      _positive(sugarG) ||
      _positive(saturatedFatG) ||
      _positive(sodiumMg) ||
      _positive(cholesterolMg) ||
      _positive(potassiumMg) ||
      _positive(calciumMg) ||
      _positive(ironMg);

  static bool _positive(double? value) => value != null && value > 0;
}
