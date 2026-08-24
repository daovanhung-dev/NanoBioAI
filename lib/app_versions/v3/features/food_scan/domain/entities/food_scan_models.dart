import 'dart:convert';

class FoodScanAccess {
  final String? userId;
  final FoodScanAccessStatus status;

  const FoodScanAccess({required this.userId, required this.status});

  bool get canUse => status == FoodScanAccessStatus.allowed && userId != null;
}

enum FoodScanAccessStatus { authRequired, plusRequired, allowed }

enum FoodScanPhase {
  idle,
  selectingImage,
  readyToAnalyze,
  analyzingVision,
  resolvingNutrition,
  evaluatingHealth,
  ready,
  saving,
  saved,
  error,
}

class NutritionEstimate {
  final double caloriesKcal;
  final double proteinG;
  final double carbohydratesG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? saturatedFatG;
  final double? monounsaturatedFatG;
  final double? polyunsaturatedFatG;
  final double? transFatG;
  final double? cholesterolMg;
  final double? potassiumMg;
  final double? calciumMg;
  final double? ironMg;
  final double? magnesiumMg;
  final double? phosphorusMg;
  final double? zincMg;
  final double? copperMg;
  final double? manganeseMg;
  final double? seleniumMcg;
  final double? vitaminAMcgRae;
  final double? vitaminCMg;
  final double? vitaminDMcg;
  final double? vitaminEMg;
  final double? vitaminKMcg;
  final double? vitaminB1Mg;
  final double? vitaminB2Mg;
  final double? vitaminB3Mg;
  final double? vitaminB5Mg;
  final double? vitaminB6Mg;
  final double? biotinB7Mcg;
  final double? folateB9Mcg;
  final double? vitaminB12Mcg;
  final double? cholineMg;
  final double? omega3G;
  final double? omega6G;
  final double? waterG;

  const NutritionEstimate({
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbohydratesG = 0,
    this.fatG = 0,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.saturatedFatG,
    this.monounsaturatedFatG,
    this.polyunsaturatedFatG,
    this.transFatG,
    this.cholesterolMg,
    this.potassiumMg,
    this.calciumMg,
    this.ironMg,
    this.magnesiumMg,
    this.phosphorusMg,
    this.zincMg,
    this.copperMg,
    this.manganeseMg,
    this.seleniumMcg,
    this.vitaminAMcgRae,
    this.vitaminCMg,
    this.vitaminDMcg,
    this.vitaminEMg,
    this.vitaminKMcg,
    this.vitaminB1Mg,
    this.vitaminB2Mg,
    this.vitaminB3Mg,
    this.vitaminB5Mg,
    this.vitaminB6Mg,
    this.biotinB7Mcg,
    this.folateB9Mcg,
    this.vitaminB12Mcg,
    this.cholineMg,
    this.omega3G,
    this.omega6G,
    this.waterG,
  });

  factory NutritionEstimate.fromJson(Map<String, Object?> json) {
    return NutritionEstimate(
      caloriesKcal: _double(json['calories_kcal']) ?? 0,
      proteinG: _double(json['protein_g']) ?? 0,
      carbohydratesG:
          _double(json['carbohydrates_g'] ?? json['carbs_g']) ?? 0,
      fatG: _double(json['fat_g']) ?? 0,
      fiberG: _double(json['fiber_g']),
      sugarG: _double(json['sugar_g']),
      sodiumMg: _double(json['sodium_mg']),
      saturatedFatG: _double(json['saturated_fat_g']),
      monounsaturatedFatG: _double(json['monounsaturated_fat_g']),
      polyunsaturatedFatG: _double(json['polyunsaturated_fat_g']),
      transFatG: _double(json['trans_fat_g']),
      cholesterolMg: _double(json['cholesterol_mg']),
      potassiumMg: _double(json['potassium_mg']),
      calciumMg: _double(json['calcium_mg']),
      ironMg: _double(json['iron_mg']),
      magnesiumMg: _double(json['magnesium_mg']),
      phosphorusMg: _double(json['phosphorus_mg']),
      zincMg: _double(json['zinc_mg']),
      copperMg: _double(json['copper_mg']),
      manganeseMg: _double(json['manganese_mg']),
      seleniumMcg: _double(json['selenium_mcg']),
      vitaminAMcgRae: _double(json['vitamin_a_mcg_rae']),
      vitaminCMg: _double(json['vitamin_c_mg']),
      vitaminDMcg: _double(json['vitamin_d_mcg']),
      vitaminEMg: _double(json['vitamin_e_mg']),
      vitaminKMcg: _double(json['vitamin_k_mcg']),
      vitaminB1Mg: _double(json['vitamin_b1_mg']),
      vitaminB2Mg: _double(json['vitamin_b2_mg']),
      vitaminB3Mg: _double(json['vitamin_b3_mg']),
      vitaminB5Mg: _double(json['vitamin_b5_mg']),
      vitaminB6Mg: _double(json['vitamin_b6_mg']),
      biotinB7Mcg: _double(json['biotin_b7_mcg']),
      folateB9Mcg: _double(json['folate_b9_mcg']),
      vitaminB12Mcg: _double(json['vitamin_b12_mcg']),
      cholineMg: _double(json['choline_mg']),
      omega3G: _double(json['omega3_g']),
      omega6G: _double(json['omega6_g']),
      waterG: _double(json['water_g']),
    ).sanitized();
  }

  NutritionEstimate sanitized() {
    double positive(double value) => value.isFinite && value > 0 ? value : 0;
    double? optional(double? value) =>
        value != null && value.isFinite && value >= 0 ? value : null;

    return NutritionEstimate(
      caloriesKcal: positive(caloriesKcal).clamp(0, 10000).toDouble(),
      proteinG: positive(proteinG).clamp(0, 1000).toDouble(),
      carbohydratesG: positive(carbohydratesG).clamp(0, 2000).toDouble(),
      fatG: positive(fatG).clamp(0, 1000).toDouble(),
      fiberG: optional(fiberG),
      sugarG: optional(sugarG),
      sodiumMg: optional(sodiumMg),
      saturatedFatG: optional(saturatedFatG),
      monounsaturatedFatG: optional(monounsaturatedFatG),
      polyunsaturatedFatG: optional(polyunsaturatedFatG),
      transFatG: optional(transFatG),
      cholesterolMg: optional(cholesterolMg),
      potassiumMg: optional(potassiumMg),
      calciumMg: optional(calciumMg),
      ironMg: optional(ironMg),
      magnesiumMg: optional(magnesiumMg),
      phosphorusMg: optional(phosphorusMg),
      zincMg: optional(zincMg),
      copperMg: optional(copperMg),
      manganeseMg: optional(manganeseMg),
      seleniumMcg: optional(seleniumMcg),
      vitaminAMcgRae: optional(vitaminAMcgRae),
      vitaminCMg: optional(vitaminCMg),
      vitaminDMcg: optional(vitaminDMcg),
      vitaminEMg: optional(vitaminEMg),
      vitaminKMcg: optional(vitaminKMcg),
      vitaminB1Mg: optional(vitaminB1Mg),
      vitaminB2Mg: optional(vitaminB2Mg),
      vitaminB3Mg: optional(vitaminB3Mg),
      vitaminB5Mg: optional(vitaminB5Mg),
      vitaminB6Mg: optional(vitaminB6Mg),
      biotinB7Mcg: optional(biotinB7Mcg),
      folateB9Mcg: optional(folateB9Mcg),
      vitaminB12Mcg: optional(vitaminB12Mcg),
      cholineMg: optional(cholineMg),
      omega3G: optional(omega3G),
      omega6G: optional(omega6G),
      waterG: optional(waterG),
    );
  }

  NutritionEstimate scale(double factor) {
    if (!factor.isFinite || factor <= 0) return const NutritionEstimate();
    double? s(double? value) => value == null ? null : value * factor;
    return NutritionEstimate(
      caloriesKcal: caloriesKcal * factor,
      proteinG: proteinG * factor,
      carbohydratesG: carbohydratesG * factor,
      fatG: fatG * factor,
      fiberG: s(fiberG),
      sugarG: s(sugarG),
      sodiumMg: s(sodiumMg),
      saturatedFatG: s(saturatedFatG),
      monounsaturatedFatG: s(monounsaturatedFatG),
      polyunsaturatedFatG: s(polyunsaturatedFatG),
      transFatG: s(transFatG),
      cholesterolMg: s(cholesterolMg),
      potassiumMg: s(potassiumMg),
      calciumMg: s(calciumMg),
      ironMg: s(ironMg),
      magnesiumMg: s(magnesiumMg),
      phosphorusMg: s(phosphorusMg),
      zincMg: s(zincMg),
      copperMg: s(copperMg),
      manganeseMg: s(manganeseMg),
      seleniumMcg: s(seleniumMcg),
      vitaminAMcgRae: s(vitaminAMcgRae),
      vitaminCMg: s(vitaminCMg),
      vitaminDMcg: s(vitaminDMcg),
      vitaminEMg: s(vitaminEMg),
      vitaminKMcg: s(vitaminKMcg),
      vitaminB1Mg: s(vitaminB1Mg),
      vitaminB2Mg: s(vitaminB2Mg),
      vitaminB3Mg: s(vitaminB3Mg),
      vitaminB5Mg: s(vitaminB5Mg),
      vitaminB6Mg: s(vitaminB6Mg),
      biotinB7Mcg: s(biotinB7Mcg),
      folateB9Mcg: s(folateB9Mcg),
      vitaminB12Mcg: s(vitaminB12Mcg),
      cholineMg: s(cholineMg),
      omega3G: s(omega3G),
      omega6G: s(omega6G),
      waterG: s(waterG),
    ).sanitized();
  }

  NutritionEstimate operator +(NutritionEstimate other) {
    double? addOptional(double? a, double? b) {
      if (a == null && b == null) return null;
      return (a ?? 0) + (b ?? 0);
    }

    return NutritionEstimate(
      caloriesKcal: caloriesKcal + other.caloriesKcal,
      proteinG: proteinG + other.proteinG,
      carbohydratesG: carbohydratesG + other.carbohydratesG,
      fatG: fatG + other.fatG,
      fiberG: addOptional(fiberG, other.fiberG),
      sugarG: addOptional(sugarG, other.sugarG),
      sodiumMg: addOptional(sodiumMg, other.sodiumMg),
      saturatedFatG: addOptional(saturatedFatG, other.saturatedFatG),
      monounsaturatedFatG:
          addOptional(monounsaturatedFatG, other.monounsaturatedFatG),
      polyunsaturatedFatG:
          addOptional(polyunsaturatedFatG, other.polyunsaturatedFatG),
      transFatG: addOptional(transFatG, other.transFatG),
      cholesterolMg: addOptional(cholesterolMg, other.cholesterolMg),
      potassiumMg: addOptional(potassiumMg, other.potassiumMg),
      calciumMg: addOptional(calciumMg, other.calciumMg),
      ironMg: addOptional(ironMg, other.ironMg),
      magnesiumMg: addOptional(magnesiumMg, other.magnesiumMg),
      phosphorusMg: addOptional(phosphorusMg, other.phosphorusMg),
      zincMg: addOptional(zincMg, other.zincMg),
      copperMg: addOptional(copperMg, other.copperMg),
      manganeseMg: addOptional(manganeseMg, other.manganeseMg),
      seleniumMcg: addOptional(seleniumMcg, other.seleniumMcg),
      vitaminAMcgRae: addOptional(vitaminAMcgRae, other.vitaminAMcgRae),
      vitaminCMg: addOptional(vitaminCMg, other.vitaminCMg),
      vitaminDMcg: addOptional(vitaminDMcg, other.vitaminDMcg),
      vitaminEMg: addOptional(vitaminEMg, other.vitaminEMg),
      vitaminKMcg: addOptional(vitaminKMcg, other.vitaminKMcg),
      vitaminB1Mg: addOptional(vitaminB1Mg, other.vitaminB1Mg),
      vitaminB2Mg: addOptional(vitaminB2Mg, other.vitaminB2Mg),
      vitaminB3Mg: addOptional(vitaminB3Mg, other.vitaminB3Mg),
      vitaminB5Mg: addOptional(vitaminB5Mg, other.vitaminB5Mg),
      vitaminB6Mg: addOptional(vitaminB6Mg, other.vitaminB6Mg),
      biotinB7Mcg: addOptional(biotinB7Mcg, other.biotinB7Mcg),
      folateB9Mcg: addOptional(folateB9Mcg, other.folateB9Mcg),
      vitaminB12Mcg: addOptional(vitaminB12Mcg, other.vitaminB12Mcg),
      cholineMg: addOptional(cholineMg, other.cholineMg),
      omega3G: addOptional(omega3G, other.omega3G),
      omega6G: addOptional(omega6G, other.omega6G),
      waterG: addOptional(waterG, other.waterG),
    ).sanitized();
  }

  Map<String, Object?> toJson() => {
    'calories_kcal': caloriesKcal,
    'protein_g': proteinG,
    'carbohydrates_g': carbohydratesG,
    'fat_g': fatG,
    'fiber_g': fiberG,
    'sugar_g': sugarG,
    'sodium_mg': sodiumMg,
    'saturated_fat_g': saturatedFatG,
    'monounsaturated_fat_g': monounsaturatedFatG,
    'polyunsaturated_fat_g': polyunsaturatedFatG,
    'trans_fat_g': transFatG,
    'cholesterol_mg': cholesterolMg,
    'potassium_mg': potassiumMg,
    'calcium_mg': calciumMg,
    'iron_mg': ironMg,
    'magnesium_mg': magnesiumMg,
    'phosphorus_mg': phosphorusMg,
    'zinc_mg': zincMg,
    'copper_mg': copperMg,
    'manganese_mg': manganeseMg,
    'selenium_mcg': seleniumMcg,
    'vitamin_a_mcg_rae': vitaminAMcgRae,
    'vitamin_c_mg': vitaminCMg,
    'vitamin_d_mcg': vitaminDMcg,
    'vitamin_e_mg': vitaminEMg,
    'vitamin_k_mcg': vitaminKMcg,
    'vitamin_b1_mg': vitaminB1Mg,
    'vitamin_b2_mg': vitaminB2Mg,
    'vitamin_b3_mg': vitaminB3Mg,
    'vitamin_b5_mg': vitaminB5Mg,
    'vitamin_b6_mg': vitaminB6Mg,
    'biotin_b7_mcg': biotinB7Mcg,
    'folate_b9_mcg': folateB9Mcg,
    'vitamin_b12_mcg': vitaminB12Mcg,
    'choline_mg': cholineMg,
    'omega3_g': omega3G,
    'omega6_g': omega6G,
    'water_g': waterG,
  };
}

class FoodScanItem {
  final String id;
  final String name;
  final String normalizedName;
  final double estimatedWeightGrams;
  final double confirmedWeightGrams;
  final String portionDescription;
  final String cookingMethod;
  final List<String> ingredients;
  final List<String> possibleAllergens;
  final double confidence;
  final NutritionEstimate nutrition;
  final String nutritionSource;
  final String? catalogCode;

  const FoodScanItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.estimatedWeightGrams,
    required this.confirmedWeightGrams,
    required this.portionDescription,
    required this.cookingMethod,
    required this.ingredients,
    required this.possibleAllergens,
    required this.confidence,
    required this.nutrition,
    required this.nutritionSource,
    this.catalogCode,
  });

  factory FoodScanItem.fromJson(Map<String, Object?> json) {
    final estimated = (_double(json['estimated_weight_g']) ?? 0)
        .clamp(0, 5000)
        .toDouble();
    return FoodScanItem(
      id: _string(json['id']) ?? '',
      name: _string(json['name']) ?? 'Món chưa xác định',
      normalizedName: _string(json['normalized_name'] ?? json['normalized_hint']) ?? '',
      estimatedWeightGrams: estimated,
      confirmedWeightGrams:
          (_double(json['confirmed_weight_g']) ?? estimated).clamp(0, 5000).toDouble(),
      portionDescription: _string(json['portion_description']) ?? '',
      cookingMethod: _string(json['cooking_method']) ?? '',
      ingredients: _strings(json['ingredients']),
      possibleAllergens: _strings(json['possible_allergens']),
      confidence: (_double(json['confidence']) ?? 0).clamp(0, 1).toDouble(),
      nutrition: NutritionEstimate.fromJson(
        _map(json['nutrition'] ?? json['fallback_nutrition']),
      ),
      nutritionSource: _string(json['nutrition_source']) ?? 'ai_fallback',
      catalogCode: _string(json['catalog_code']),
    );
  }

  FoodScanItem copyWith({
    String? name,
    String? normalizedName,
    double? confirmedWeightGrams,
    String? portionDescription,
    NutritionEstimate? nutrition,
    String? nutritionSource,
    String? catalogCode,
  }) {
    return FoodScanItem(
      id: id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      estimatedWeightGrams: estimatedWeightGrams,
      confirmedWeightGrams: confirmedWeightGrams ?? this.confirmedWeightGrams,
      portionDescription: portionDescription ?? this.portionDescription,
      cookingMethod: cookingMethod,
      ingredients: ingredients,
      possibleAllergens: possibleAllergens,
      confidence: confidence,
      nutrition: nutrition ?? this.nutrition,
      nutritionSource: nutritionSource ?? this.nutritionSource,
      catalogCode: catalogCode ?? this.catalogCode,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'normalized_name': normalizedName,
    'estimated_weight_g': estimatedWeightGrams,
    'confirmed_weight_g': confirmedWeightGrams,
    'portion_description': portionDescription,
    'cooking_method': cookingMethod,
    'ingredients': ingredients,
    'possible_allergens': possibleAllergens,
    'confidence': confidence,
    'nutrition': nutrition.toJson(),
    'nutrition_source': nutritionSource,
    'catalog_code': catalogCode,
  };
}

class FoodHealthEvaluation {
  final String status;
  final int? suitabilityScore;
  final String summary;
  final List<Map<String, Object?>> conditionReviews;
  final List<String> allergyWarnings;
  final List<String> suggestions;
  final String dailyGoalSummary;
  final List<String> dailyGoalNotes;
  final List<String> assumptions;
  final List<String> missingHealthData;
  final double confidence;

  const FoodHealthEvaluation({
    required this.status,
    required this.suitabilityScore,
    required this.summary,
    required this.conditionReviews,
    required this.allergyWarnings,
    required this.suggestions,
    required this.dailyGoalSummary,
    required this.dailyGoalNotes,
    required this.assumptions,
    required this.missingHealthData,
    required this.confidence,
  });

  const FoodHealthEvaluation.insufficient({
    this.summary = 'Chưa đủ dữ liệu để đánh giá mức độ phù hợp với sức khỏe.',
    this.allergyWarnings = const [],
    this.suggestions = const [],
    this.dailyGoalSummary = '',
    this.dailyGoalNotes = const [],
  }) : status = 'insufficientData',
       suitabilityScore = null,
       conditionReviews = const [],
       assumptions = const [],
       missingHealthData = const [],
       confidence = 0;

  factory FoodHealthEvaluation.fromJson(Map<String, Object?> json) {
    final overall = _map(json['overall']);
    final rawScore = _int(overall['suitability_score']);
    final conditions = json['conditions'];
    final dailyGoalReview = _map(json['daily_goal_review']);
    return FoodHealthEvaluation(
      status: _normalizeHealthStatus(_string(overall['status']) ?? 'thieu_du_lieu'),
      suitabilityScore: rawScore?.clamp(0, 100).toInt(),
      summary: _safeHealthText(
        _string(overall['summary_vi']) ??
            'Nabi chưa có đủ dữ liệu để đưa ra đánh giá chi tiết.',
      ),
      conditionReviews: conditions is List
          ? conditions.whereType<Map>().map((item) {
              final map = item.map(
                (key, value) => MapEntry(key.toString(), value),
              );
              return <String, Object?>{
                'condition_code': _string(map['condition_code']) ?? '',
                'condition_name': _string(map['condition_name']) ?? 'Tình trạng sức khỏe',
                'status': _normalizeHealthStatus(
                  _string(map['status']) ?? 'thieu_du_lieu',
                ),
                'reasons': _strings(map['reasons']).map(_safeHealthText).toList(),
                'nutrients_of_concern': map['nutrients_of_concern'] is List
                    ? List<Object?>.from(map['nutrients_of_concern'] as List)
                    : const <Object?>[],
                'ingredients_of_concern': _strings(map['ingredients_of_concern']),
                'suggested_adjustments': _strings(
                  map['suggested_adjustments'],
                ).map(_safeHealthText).toList(),
              };
            }).toList(growable: false)
          : const [],
      allergyWarnings: _parseAllergyWarnings(json['allergy_review']),
      suggestions: _strings(
        json['suggested_adjustments'],
      ).map(_safeHealthText).toList(growable: false),
      dailyGoalSummary: _safeHealthText(
        _string(dailyGoalReview['summary_vi']) ?? '',
      ),
      dailyGoalNotes: _parseDailyGoalNotes(dailyGoalReview['items']),
      assumptions: _strings(json['important_assumptions']),
      missingHealthData: _strings(json['missing_health_data']),
      confidence: (_double(json['confidence']) ?? 0).clamp(0, 1).toDouble(),
    );
  }

  Map<String, Object?> toJson() => {
    'status': status,
    'suitability_score': suitabilityScore,
    'summary': summary,
    'condition_reviews': conditionReviews,
    'allergy_warnings': allergyWarnings,
    'suggestions': suggestions,
    'daily_goal_summary': dailyGoalSummary,
    'daily_goal_notes': dailyGoalNotes,
    'assumptions': assumptions,
    'missing_health_data': missingHealthData,
    'confidence': confidence,
  };
}

class FoodScanResult {
  final String id;
  final String imageLocalPath;
  final String inputType;
  final bool isFoodImage;
  final double analysisConfidence;
  final List<FoodScanItem> items;
  final NutritionEstimate totalNutrition;
  final FoodHealthEvaluation healthEvaluation;
  final List<String> assumptions;
  final List<String> warnings;
  final DateTime createdAt;
  final String? nutritionLogId;

  const FoodScanResult({
    required this.id,
    required this.imageLocalPath,
    required this.inputType,
    required this.isFoodImage,
    required this.analysisConfidence,
    required this.items,
    required this.totalNutrition,
    required this.healthEvaluation,
    required this.assumptions,
    required this.warnings,
    required this.createdAt,
    this.nutritionLogId,
  });

  int get displayedCalories => totalNutrition.caloriesKcal.round();

  FoodScanResult copyWith({
    List<FoodScanItem>? items,
    NutritionEstimate? totalNutrition,
    FoodHealthEvaluation? healthEvaluation,
    String? nutritionLogId,
  }) {
    return FoodScanResult(
      id: id,
      imageLocalPath: imageLocalPath,
      inputType: inputType,
      isFoodImage: isFoodImage,
      analysisConfidence: analysisConfidence,
      items: items ?? this.items,
      totalNutrition: totalNutrition ?? this.totalNutrition,
      healthEvaluation: healthEvaluation ?? this.healthEvaluation,
      assumptions: assumptions,
      warnings: warnings,
      createdAt: createdAt,
      nutritionLogId: nutritionLogId ?? this.nutritionLogId,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'image_local_path': imageLocalPath,
    'input_type': inputType,
    'is_food_image': isFoodImage,
    'analysis_confidence': analysisConfidence,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'total_nutrition': totalNutrition.toJson(),
    'health_evaluation': healthEvaluation.toJson(),
    'assumptions': assumptions,
    'warnings': warnings,
    'created_at': createdAt.toUtc().toIso8601String(),
    'nutrition_log_id': nutritionLogId,
  };

  factory FoodScanResult.fromJson(Map<String, Object?> json) {
    final items = json['items'];
    return FoodScanResult(
      id: _string(json['id']) ?? '',
      imageLocalPath: _string(json['image_local_path']) ?? '',
      inputType: _string(json['input_type']) ?? 'unclear',
      isFoodImage: _bool(json['is_food_image'], fallback: true),
      analysisConfidence:
          (_double(json['analysis_confidence']) ?? 0).clamp(0, 1).toDouble(),
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) => FoodScanItem.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const [],
      totalNutrition: NutritionEstimate.fromJson(_map(json['total_nutrition'])),
      healthEvaluation: _healthFromStoredJson(json['health_evaluation']),
      assumptions: _strings(json['assumptions']),
      warnings: _strings(json['warnings']),
      createdAt:
          DateTime.tryParse(_string(json['created_at']) ?? '')?.toLocal() ??
          DateTime.now(),
      nutritionLogId: _string(json['nutrition_log_id']),
    );
  }

  String encode() => jsonEncode(toJson());

  factory FoodScanResult.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Food scan history payload must be an object.');
    }
    return FoodScanResult.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

FoodHealthEvaluation _healthFromStoredJson(Object? value) {
  final map = _map(value);
  if (map.containsKey('overall')) return FoodHealthEvaluation.fromJson(map);
  return FoodHealthEvaluation(
    status: _string(map['status']) ?? 'insufficientData',
    suitabilityScore: _int(map['suitability_score'])?.clamp(0, 100).toInt(),
    summary: _string(map['summary']) ?? 'Chưa đủ dữ liệu.',
    conditionReviews: map['condition_reviews'] is List
        ? (map['condition_reviews'] as List)
              .whereType<Map>()
              .map(
                (item) => item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              )
              .toList(growable: false)
        : const [],
    allergyWarnings: _strings(map['allergy_warnings']),
    suggestions: _strings(map['suggestions']),
    dailyGoalSummary: _string(map['daily_goal_summary']) ?? '',
    dailyGoalNotes: _strings(map['daily_goal_notes']),
    assumptions: _strings(map['assumptions']),
    missingHealthData: _strings(map['missing_health_data']),
    confidence: (_double(map['confidence']) ?? 0).clamp(0, 1).toDouble(),
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return <String, Object?>{};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .take(30)
      .toList(growable: false);
}

String _normalizeHealthStatus(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'phu_hop' || 'suitable' => 'suitable',
    'tuong_doi_phu_hop' || 'mostly_suitable' || 'mostlysuitable' =>
      'mostlySuitable',
    'can_nhac' || 'consider' => 'consider',
    'nen_han_che' || 'limit' => 'limit',
    'khong_phu_hop' || 'not_suitable' || 'notsuitable' => 'notSuitable',
    _ => 'insufficientData',
  };
}

String _safeHealthText(String value) {
  final lower = value.toLowerCase();
  const blocked = <String>[
    'ngừng thuốc',
    'dừng thuốc',
    'bỏ thuốc',
    '100% an toàn',
    'an toàn tuyệt đối',
    'chắc chắn chữa',
    'chữa khỏi',
  ];
  if (blocked.any(lower.contains)) {
    return 'Nabi không thể xác nhận nội dung y khoa này chỉ từ ảnh món ăn. '
        'Bạn nên trao đổi với bác sĩ hoặc chuyên gia dinh dưỡng nếu cần quyết định điều trị.';
  }
  return value.length <= 500 ? value : '${value.substring(0, 500)}…';
}

List<String> _parseDailyGoalNotes(Object? value) {
  if (value is! List) return const [];
  final notes = <String>[];
  for (final raw in value.take(20)) {
    if (raw is String && raw.trim().isNotEmpty) {
      notes.add(_safeHealthText(raw.trim()));
      continue;
    }
    if (raw is! Map) continue;
    final map = raw.map((key, item) => MapEntry(key.toString(), item));
    final label = _string(
      map['label'] ?? map['nutrient'] ?? map['name'] ?? map['metric'],
    );
    final current = _string(
      map['current'] ?? map['amount'] ?? map['value'] ?? map['consumed'],
    );
    final target = _string(map['target'] ?? map['goal']);
    final unit = _string(map['unit']);
    final assessment = _string(
      map['assessment_vi'] ?? map['reason'] ?? map['status'] ?? map['summary_vi'],
    );
    final buffer = <String>[];
    if (label != null) buffer.add(label);
    if (current != null || target != null) {
      final value = [
        if (current != null) current,
        if (target != null) '/ $target',
        if (unit != null) unit,
      ].join(' ');
      buffer.add(value);
    }
    if (assessment != null) buffer.add(_safeHealthText(assessment));
    if (buffer.isNotEmpty) notes.add(buffer.join(' • '));
  }
  return notes.take(20).toList(growable: false);
}

List<String> _parseAllergyWarnings(Object? value) {
  if (value is! List) return const [];
  final result = <String>[];
  for (final item in value.whereType<Map>()) {
    final map = item.map((key, value) => MapEntry(key.toString(), value));
    final allergy = _string(map['allergy']);
    final status = _string(map['status'])?.toLowerCase();
    final reason = _string(map['reason']);
    if (allergy == null || status == null) continue;
    if (status == 'detected' || status == 'possible') {
      result.add(
        reason == null || reason.isEmpty
            ? 'Món ăn có khả năng liên quan đến dị ứng $allergy.'
            : '$allergy: ${_safeHealthText(reason)}',
      );
    }
  }
  return result.take(20).toList(growable: false);
}
