import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

class MealCandidateSelector {
  const MealCandidateSelector();

  List<MealCatalogItemModel> eligibleMeals({
    required Iterable<MealCatalogItemModel> catalog,
    required NutritionProfileEntity profile,
    String? mealType,
    Set<String> excludedCodes = const {},
  }) {
    final normalizedType = mealType?.trim().toLowerCase() ?? '';
    final isSlotScopedSelection = normalizedType.isNotEmpty;
    final restrictions = profile.restrictions
        .where((item) => item.isActive)
        .map((item) => _normalize(item.itemName))
        .where((item) => item.isNotEmpty)
        .toSet();
    final conditionTokens = <String>{
      _normalize(profile.currentStatus),
      ...profile.symptoms
          .where((item) => item.isActive)
          .map((item) => _normalize(item.symptomType)),
    }..removeWhere((item) => item.isEmpty);

    final candidates = catalog.where((meal) {
      if (!meal.isActive) return false;
      if (_isFixtureCode(meal.code)) return false;
      if (excludedCodes.contains(meal.code)) return false;

      // Full-plan generation intentionally forwards every active Supabase meal
      // to the AI. The user's health profile is part of the prompt, so catalog
      // approval/eligibility flags do not remove codes before AI analysis.
      if (!isSlotScopedSelection) return true;

      // Manual replacement remains slot-aware and keeps local safety checks.
      if (meal.mealType != normalizedType &&
          meal.mealType != 'unclassified') {
        return false;
      }
      if (_conflictsWithRestrictions(meal, restrictions)) return false;
      if (_conflictsWithConditions(meal, conditionTokens)) return false;
      return true;
    }).toList(growable: false)
      ..sort((left, right) => left.code.compareTo(right.code));
    return candidates;
  }

  MealCatalogItemModel? replacementFor({
    required Iterable<MealCatalogItemModel> catalog,
    required NutritionProfileEntity profile,
    required String mealType,
    required String currentCode,
    required int replacementCount,
  }) {
    final candidates = eligibleMeals(
      catalog: catalog,
      profile: profile,
      mealType: mealType,
      excludedCodes: {currentCode},
    );
    if (candidates.isEmpty) return null;
    return candidates[replacementCount % candidates.length];
  }

  bool _conflictsWithRestrictions(
    MealCatalogItemModel meal,
    Set<String> restrictions,
  ) {
    if (restrictions.isEmpty) return false;
    final searchable = <String>{
      _normalize(meal.mealName),
      _normalize(meal.description),
      ...meal.ingredients.map(_normalize),
      ...meal.allergenTags.map(_normalize),
    }.where((item) => item.isNotEmpty);
    for (final restriction in restrictions) {
      for (final value in searchable) {
        if (value.contains(restriction) || restriction.contains(value)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _conflictsWithConditions(
    MealCatalogItemModel meal,
    Set<String> conditionTokens,
  ) {
    if (conditionTokens.isEmpty || meal.avoidConditionTags.isEmpty) {
      return false;
    }
    final avoid = meal.avoidConditionTags.map(_normalize);
    for (final condition in conditionTokens) {
      for (final tag in avoid) {
        if (tag.isNotEmpty &&
            (condition.contains(tag) || tag.contains(condition))) {
          return true;
        }
      }
    }
    return false;
  }


  bool _isFixtureCode(String code) {
    return code.trim().toLowerCase().startsWith('fixture-');
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
