import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

enum MealCandidateSelectionPolicy {
  /// Require reviewed constraint and nutrition evidence for personalized picks.
  strict,

  /// Build a general wellness schedule when legacy recipes lack health evidence.
  /// Explicit allergies and foods to avoid remain hard eligibility constraints.
  wellnessSchedule,
}

class MealCandidateSelector {
  const MealCandidateSelector();

  static const _allergenAliases = <String, Set<String>>{
    'peanut': {'peanut', 'groundnut', 'lac', 'dau phong'},
    'tree_nut': {
      'tree nut',
      'almond',
      'cashew',
      'walnut',
      'hazelnut',
      'pistachio',
      'hạnh nhân',
      'hat dieu',
      'oc cho',
    },
    'milk': {'milk', 'dairy', 'sua', 'casein', 'whey'},
    'egg': {'egg', 'trung'},
    'soy': {'soy', 'soya', 'soybean', 'dau nanh', 'dau tuong'},
    'fish': {'fish', 'ca'},
    'shellfish': {
      'shellfish',
      'shrimp',
      'prawn',
      'crab',
      'lobster',
      'tom',
      'cua',
      'ghe',
    },
    'wheat_gluten': {
      'wheat',
      'gluten',
      'barley',
      'rye',
      'lua mi',
      'bot mi',
      'lua mach',
    },
    'sesame': {'sesame', 'vung', 'me'},
  };

  List<MealCatalogItemModel> eligibleMeals({
    required Iterable<MealCatalogItemModel> catalog,
    required NutritionProfileEntity profile,
    String? mealType,
    Set<String> conditions = const {},
    Set<String> goals = const {},
    Set<String> additionalAllergies = const {},
    bool unparsedAllergyDetails = false,
    Set<String> excludedCodes = const {},
    int? limit,
    MealCandidateSelectionPolicy selectionPolicy =
        MealCandidateSelectionPolicy.strict,
  }) {
    final normalizedType = normalizeMealCatalogType(mealType ?? '');
    final restrictions = profile.restrictions
        .where((item) => item.isActive)
        .where((item) => _normalize(item.itemName).isNotEmpty)
        .toList(growable: false);
    final allergyRestrictions =
        restrictions
            .where(
              (item) => const {
                'allergy',
                'intolerance',
              }.contains(_normalize(item.type)),
            )
            .map((item) => _normalize(item.itemName))
            .where((item) => item.isNotEmpty && !_isNoConstraint(item))
            .toSet()
          ..addAll(
            additionalAllergies
                .map(_normalize)
                .where((item) => item.isNotEmpty && !_isNoConstraint(item)),
          );
    final avoidRestrictions = restrictions
        .where((item) => _normalize(item.type) == 'avoid')
        .map((item) => _normalize(item.itemName))
        .where((item) => item.isNotEmpty && !_isNoConstraint(item))
        .toSet();
    final conditionTokens = conditions
        .map(_normalize)
        .where((value) => value.isNotEmpty && !_isNoConstraint(value))
        .toSet();
    final currentStatus = _normalize(profile.currentStatus);
    if (currentStatus.isNotEmpty && !_isNoConstraint(currentStatus)) {
      conditionTokens.add(currentStatus);
    }
    final hasUnsupportedAllergy = allergyRestrictions.any(
      (value) => _canonicalAllergen(value) == null,
    );
    final goalTokens = {
      ...goals.map(_normalize),
      ...profile.goals
          .where((goal) => goal.isActive)
          .map((goal) => _normalize('${goal.code} ${goal.name}')),
    }..removeWhere((value) => value.isEmpty || _isNoConstraint(value));
    final needsVerifiedNutrition = goalTokens.any(
      (goal) => _containsGoal(goal, const {
        'maintain weight',
        'lose weight',
        'gain weight',
        'lose belly fat',
        'gain muscle',
        'balanced nutrition',
      }),
    );
    final needsConditionReview = goalTokens.any(
      (goal) => _containsGoal(goal, const {
        'stable blood sugar',
        'stable blood pressure',
        'heart health',
        'joint health',
        'improve digestion',
      }),
    );
    final enforceReviewedWellnessEvidence =
        selectionPolicy == MealCandidateSelectionPolicy.strict;
    final anyPersonalConstraint =
        allergyRestrictions.isNotEmpty ||
        avoidRestrictions.isNotEmpty ||
        unparsedAllergyDetails ||
        (enforceReviewedWellnessEvidence &&
            (conditionTokens.isNotEmpty ||
                needsVerifiedNutrition ||
                needsConditionReview));

    final candidates = catalog
        .where((meal) {
          final isSelectable =
              selectionPolicy == MealCandidateSelectionPolicy.wellnessSchedule
              ? meal.isSelectableForGeneralWellnessSchedule
              : meal.isSelectableForMealPlanAi;
          if (!isSelectable || meal.code.trim().isEmpty) {
            return false;
          }
          if (_isFixtureCode(meal.code) || excludedCodes.contains(meal.code)) {
            return false;
          }
          if (normalizedType.isNotEmpty &&
              normalizeMealCatalogType(meal.mealType) != normalizedType &&
              normalizeMealCatalogType(meal.mealType) != 'unclassified') {
            return false;
          }
          if (unparsedAllergyDetails) return false;
          if (hasUnsupportedAllergy) return false;
          if (!anyPersonalConstraint) return true;

          // Empty/unreviewed tags are unknown. Do not use them to infer safety.
          if (enforceReviewedWellnessEvidence &&
              (conditionTokens.isNotEmpty || needsConditionReview) &&
              meal.constraintMetadataStatus != 'verified') {
            return false;
          }
          if (avoidRestrictions.isNotEmpty &&
              (meal.constraintMetadataStatus != 'verified' ||
                  meal.ingredients.isEmpty)) {
            return false;
          }
          if (enforceReviewedWellnessEvidence &&
              needsVerifiedNutrition &&
              !_hasRequiredNutritionForGoals(meal, goalTokens)) {
            return false;
          }
          if (allergyRestrictions.isNotEmpty &&
              !const {
                'verified_none',
                'verified_present',
              }.contains(meal.allergenVerificationStatus)) {
            return false;
          }
          if (allergyRestrictions.isNotEmpty &&
              meal.allergenVerificationStatus == 'verified_present' &&
              (meal.allergenTags.isEmpty ||
                  meal.allergenTags.any(
                    (tag) => _canonicalAllergen(tag) == null,
                  ))) {
            return false;
          }
          if (_conflictsWithAllergies(meal, allergyRestrictions)) return false;
          if (_conflictsWithAvoidFoods(meal, avoidRestrictions)) return false;
          if ((enforceReviewedWellnessEvidence ||
                  meal.constraintMetadataStatus == 'verified') &&
              _conflictsWithConditions(meal, conditionTokens)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    final ranked = [...candidates]
      ..sort((left, right) {
        final score = _rank(
          right,
          profile: profile,
          mealType: normalizedType,
        ).compareTo(_rank(left, profile: profile, mealType: normalizedType));
        if (score != 0) return score;
        return left.code.compareTo(right.code);
      });
    if (limit == null || ranked.length <= limit) return ranked;
    return ranked.take(limit).toList(growable: false);
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

  int _rank(
    MealCatalogItemModel meal, {
    required NutritionProfileEntity profile,
    required String mealType,
  }) {
    var score = 0;
    if (mealType.isNotEmpty &&
        normalizeMealCatalogType(meal.mealType) == mealType) {
      score += 100;
    }
    if (meal.servingQuantity != null && meal.servingUnit.isNotEmpty) score += 5;
    if (meal.verifiedNutrients != null) score += 4;
    if (meal.ingredients.isNotEmpty) score += 3;
    if (meal.metadataStatus == 'source_verified') score += 2;
    final searchable = _searchable(meal);
    for (final goal in profile.goals.where((item) => item.isActive)) {
      final normalizedGoal = _normalize('${goal.code} ${goal.name}');
      if (normalizedGoal.isNotEmpty && searchable.contains(normalizedGoal)) {
        score += 2;
      }
    }
    for (final rule in profile.preferenceRules.where(
      (item) => item.isActive && item.preferenceLevel == 'preferred',
    )) {
      final preference = _normalize(rule.itemName);
      if (preference.isNotEmpty && searchable.contains(preference)) score += 1;
    }
    return score;
  }

  bool _conflictsWithAllergies(
    MealCatalogItemModel meal,
    Set<String> restrictions,
  ) {
    if (restrictions.isEmpty) return false;
    final requested = restrictions
        .map(_canonicalAllergen)
        .whereType<String>()
        .toSet();
    final tags = meal.allergenTags
        .map(_canonicalAllergen)
        .whereType<String>()
        .toSet();
    return requested.any(tags.contains);
  }

  bool _conflictsWithAvoidFoods(
    MealCatalogItemModel meal,
    Set<String> avoidFoods,
  ) {
    if (avoidFoods.isEmpty) return false;
    final ingredients = meal.ingredients
        .map(_normalize)
        .where((s) => s.isNotEmpty);
    for (final avoidFood in avoidFoods) {
      if (ingredients.any((ingredient) => _overlaps(ingredient, avoidFood))) {
        return true;
      }
    }
    return false;
  }

  bool _conflictsWithConditions(
    MealCatalogItemModel meal,
    Set<String> conditions,
  ) {
    if (conditions.isEmpty) return false;
    final avoidTags = meal.avoidConditionTags.map(_normalize).toSet();
    return conditions.any(
      (condition) => avoidTags.any((tag) => _overlaps(tag, condition)),
    );
  }

  Set<String> _searchable(MealCatalogItemModel meal) => {
    _normalize(meal.mealName),
    _normalize(meal.description),
    ...meal.ingredients.map(_normalize),
    ...meal.allergenTags.map(_normalize),
  }..removeWhere((item) => item.isEmpty);

  bool _overlaps(String left, String right) =>
      left == right || left.contains(right) || right.contains(left);

  bool _hasRequiredNutritionForGoals(
    MealCatalogItemModel meal,
    Set<String> goals,
  ) {
    final nutrition = meal.verifiedNutrients;
    if (nutrition == null) return false;
    final needsProtein = goals.any(
      (goal) =>
          _containsGoal(goal, const {'gain muscle', 'balanced nutrition'}),
    );
    final needsEnergy = goals.any(
      (goal) => _containsGoal(goal, const {
        'maintain weight',
        'lose weight',
        'gain weight',
        'lose belly fat',
      }),
    );
    if (needsEnergy && nutrition['energy_kcal'] == null) return false;
    if (needsProtein && nutrition['protein_g'] == null) return false;
    return true;
  }

  bool _containsGoal(String value, Set<String> codesOrNames) =>
      codesOrNames.any((goal) => value.contains(goal));

  bool _isNoConstraint(String value) => const {
    'none',
    'no',
    'no issue',
    'no special issue',
    'khong',
    'khong co',
    'khong co van de dac biet',
    'không có dị ứng',
    'khong co di ung',
    'không',
    'không có',
    'không có vấn đề đặc biệt',
  }.contains(value);

  bool _isFixtureCode(String code) =>
      code.trim().toLowerCase().startsWith('fixture-');

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  String? _canonicalAllergen(String value) {
    final normalized = _normalize(value);
    for (final entry in _allergenAliases.entries) {
      if (entry.key == normalized ||
          entry.value.any((alias) => _normalize(alias) == normalized)) {
        return entry.key;
      }
    }
    return null;
  }
}
