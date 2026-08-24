import '../domain/entities/food_scan_models.dart';

class FoodScanResolvedNutrition {
  final List<FoodScanItem> items;
  final NutritionEstimate total;

  const FoodScanResolvedNutrition({required this.items, required this.total});
}

/// Hybrid nutrition resolver.
///
/// Vision AI determines food identity and an estimated portion. For common
/// foods, deterministic internal per-100g references override the AI's core
/// calories/macros/minerals. AI values remain only as fallback and as optional
/// enrichment for nutrients not present in the internal record.
class FoodScanNutritionResolver {
  const FoodScanNutritionResolver();

  FoodScanResolvedNutrition resolve(List<FoodScanItem> sourceItems) {
    final items = <FoodScanItem>[];
    var total = const NutritionEstimate();

    for (final source in sourceItems) {
      final resolved = resolveItem(source);
      items.add(resolved);
      total = total + resolved.nutrition;
    }

    return FoodScanResolvedNutrition(items: items, total: total.sanitized());
  }

  FoodScanItem resolveItem(FoodScanItem source) {
    final match = _match(source.normalizedName.isNotEmpty
        ? source.normalizedName
        : source.name);
    if (match == null || source.confirmedWeightGrams <= 0) {
      return source.copyWith(nutritionSource: 'ai_fallback');
    }

    final internal = match.nutritionPer100g.scale(
      source.confirmedWeightGrams / 100,
    );
    final merged = _preferInternal(internal, source.nutrition);
    final allergens = <String>{...source.possibleAllergens, ...match.allergens};

    return FoodScanItem(
      id: source.id,
      name: source.name,
      normalizedName: source.normalizedName,
      estimatedWeightGrams: source.estimatedWeightGrams,
      confirmedWeightGrams: source.confirmedWeightGrams,
      portionDescription: source.portionDescription,
      cookingMethod: source.cookingMethod,
      ingredients: source.ingredients,
      possibleAllergens: allergens.toList(growable: false),
      confidence: source.confidence,
      nutrition: merged,
      nutritionSource: 'internal_catalog',
      catalogCode: match.code,
    );
  }

  FoodScanItem recalculate(FoodScanItem source, double newWeightGrams) {
    final safeWeight = newWeightGrams.clamp(1, 5000).toDouble();
    final baseWeight = source.confirmedWeightGrams > 0
        ? source.confirmedWeightGrams
        : source.estimatedWeightGrams;
    final scaledAi = baseWeight > 0
        ? source.nutrition.scale(safeWeight / baseWeight)
        : source.nutrition;
    return resolveItem(
      source.copyWith(
        confirmedWeightGrams: safeWeight,
        nutrition: scaledAi,
      ),
    );
  }

  NutritionEstimate _preferInternal(
    NutritionEstimate internal,
    NutritionEstimate ai,
  ) {
    double? prefer(double? trusted, double? fallback) => trusted ?? fallback;
    return NutritionEstimate(
      caloriesKcal: internal.caloriesKcal > 0
          ? internal.caloriesKcal
          : ai.caloriesKcal,
      proteinG: internal.proteinG > 0 ? internal.proteinG : ai.proteinG,
      carbohydratesG: internal.carbohydratesG > 0
          ? internal.carbohydratesG
          : ai.carbohydratesG,
      fatG: internal.fatG > 0 ? internal.fatG : ai.fatG,
      fiberG: prefer(internal.fiberG, ai.fiberG),
      sugarG: prefer(internal.sugarG, ai.sugarG),
      sodiumMg: prefer(internal.sodiumMg, ai.sodiumMg),
      saturatedFatG: prefer(internal.saturatedFatG, ai.saturatedFatG),
      monounsaturatedFatG:
          prefer(internal.monounsaturatedFatG, ai.monounsaturatedFatG),
      polyunsaturatedFatG:
          prefer(internal.polyunsaturatedFatG, ai.polyunsaturatedFatG),
      transFatG: prefer(internal.transFatG, ai.transFatG),
      cholesterolMg: prefer(internal.cholesterolMg, ai.cholesterolMg),
      potassiumMg: prefer(internal.potassiumMg, ai.potassiumMg),
      calciumMg: prefer(internal.calciumMg, ai.calciumMg),
      ironMg: prefer(internal.ironMg, ai.ironMg),
      magnesiumMg: prefer(internal.magnesiumMg, ai.magnesiumMg),
      phosphorusMg: prefer(internal.phosphorusMg, ai.phosphorusMg),
      zincMg: prefer(internal.zincMg, ai.zincMg),
      copperMg: prefer(internal.copperMg, ai.copperMg),
      manganeseMg: prefer(internal.manganeseMg, ai.manganeseMg),
      seleniumMcg: prefer(internal.seleniumMcg, ai.seleniumMcg),
      vitaminAMcgRae: prefer(internal.vitaminAMcgRae, ai.vitaminAMcgRae),
      vitaminCMg: prefer(internal.vitaminCMg, ai.vitaminCMg),
      vitaminDMcg: prefer(internal.vitaminDMcg, ai.vitaminDMcg),
      vitaminEMg: prefer(internal.vitaminEMg, ai.vitaminEMg),
      vitaminKMcg: prefer(internal.vitaminKMcg, ai.vitaminKMcg),
      vitaminB1Mg: prefer(internal.vitaminB1Mg, ai.vitaminB1Mg),
      vitaminB2Mg: prefer(internal.vitaminB2Mg, ai.vitaminB2Mg),
      vitaminB3Mg: prefer(internal.vitaminB3Mg, ai.vitaminB3Mg),
      vitaminB5Mg: prefer(internal.vitaminB5Mg, ai.vitaminB5Mg),
      vitaminB6Mg: prefer(internal.vitaminB6Mg, ai.vitaminB6Mg),
      biotinB7Mcg: prefer(internal.biotinB7Mcg, ai.biotinB7Mcg),
      folateB9Mcg: prefer(internal.folateB9Mcg, ai.folateB9Mcg),
      vitaminB12Mcg: prefer(internal.vitaminB12Mcg, ai.vitaminB12Mcg),
      cholineMg: prefer(internal.cholineMg, ai.cholineMg),
      omega3G: prefer(internal.omega3G, ai.omega3G),
      omega6G: prefer(internal.omega6G, ai.omega6G),
      waterG: prefer(internal.waterG, ai.waterG),
    ).sanitized();
  }

  _FoodReference? _match(String rawName) {
    final normalized = normalizeFoodName(rawName);
    if (normalized.isEmpty) return null;

    _FoodReference? best;
    var bestScore = 0.0;
    for (final item in _catalog) {
      for (final alias in item.aliases) {
        final normalizedAlias = normalizeFoodName(alias);
        double score;
        if (normalized == normalizedAlias) {
          score = 1;
        } else if (normalized.contains(normalizedAlias) ||
            normalizedAlias.contains(normalized)) {
          score = 0.9;
        } else {
          score = _tokenScore(normalized, normalizedAlias);
        }
        if (score > bestScore) {
          best = item;
          bestScore = score;
        }
      }
    }
    return bestScore >= 0.68 ? best : null;
  }

  double _tokenScore(String a, String b) {
    final left = a.split(' ').where((value) => value.length > 1).toSet();
    final right = b.split(' ').where((value) => value.length > 1).toSet();
    if (left.isEmpty || right.isEmpty) return 0;
    final intersection = left.intersection(right).length;
    final union = left.union(right).length;
    return union == 0 ? 0 : intersection / union;
  }

  static String normalizeFoodName(String value) {
    var text = value.toLowerCase().trim();
    const replacements = <String, String>{
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _FoodReference {
  final String code;
  final List<String> aliases;
  final NutritionEstimate nutritionPer100g;
  final List<String> allergens;

  const _FoodReference({
    required this.code,
    required this.aliases,
    required this.nutritionPer100g,
    this.allergens = const [],
  });
}

/// Internal deterministic references per 100g for common foods.
/// The list intentionally stays conservative: unmatched/compound dishes keep
/// AI fallback rather than pretending a weak match is exact.
const _catalog = <_FoodReference>[
  _FoodReference(
    code: 'rice_white_cooked',
    aliases: ['cơm trắng', 'cơm', 'gạo trắng nấu chín'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 130, proteinG: 2.4, carbohydratesG: 28.2, fatG: 0.3,
      fiberG: 0.4, sugarG: 0.1, sodiumMg: 1, potassiumMg: 35,
      calciumMg: 10, ironMg: 0.2, magnesiumMg: 12,
    ),
  ),
  _FoodReference(
    code: 'rice_brown_cooked',
    aliases: ['cơm gạo lứt', 'gạo lứt nấu chín'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 123, proteinG: 2.7, carbohydratesG: 25.6, fatG: 1,
      fiberG: 1.6, sugarG: 0.2, sodiumMg: 4, potassiumMg: 86,
      calciumMg: 3, ironMg: 0.6, magnesiumMg: 39,
    ),
  ),
  _FoodReference(
    code: 'chicken_breast_cooked',
    aliases: ['ức gà', 'thịt gà', 'gà luộc', 'gà nướng'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 165, proteinG: 31, carbohydratesG: 0, fatG: 3.6,
      saturatedFatG: 1, sodiumMg: 74, cholesterolMg: 85,
      potassiumMg: 256, calciumMg: 15, ironMg: 1,
    ),
  ),
  _FoodReference(
    code: 'beef_cooked',
    aliases: ['thịt bò', 'bò luộc', 'bò xào', 'bò nướng'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 250, proteinG: 26, carbohydratesG: 0, fatG: 15,
      saturatedFatG: 6, sodiumMg: 72, cholesterolMg: 90,
      potassiumMg: 318, calciumMg: 18, ironMg: 2.6,
    ),
  ),
  _FoodReference(
    code: 'pork_cooked',
    aliases: ['thịt heo', 'thịt lợn', 'heo luộc', 'lợn luộc'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 242, proteinG: 27.3, carbohydratesG: 0, fatG: 13.9,
      saturatedFatG: 5.1, sodiumMg: 62, cholesterolMg: 80,
      potassiumMg: 423, calciumMg: 19, ironMg: 0.9,
    ),
  ),
  _FoodReference(
    code: 'salmon',
    aliases: ['cá hồi'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 208, proteinG: 20.4, carbohydratesG: 0, fatG: 13.4,
      saturatedFatG: 3.1, sodiumMg: 59, cholesterolMg: 55,
      potassiumMg: 363, calciumMg: 9, ironMg: 0.3, omega3G: 2.2,
    ),
  ),
  _FoodReference(
    code: 'mackerel',
    aliases: ['cá thu'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 205, proteinG: 18.6, carbohydratesG: 0, fatG: 13.9,
      saturatedFatG: 3.3, sodiumMg: 90, cholesterolMg: 70,
      potassiumMg: 314, calciumMg: 12, ironMg: 1.6, omega3G: 2.5,
    ),
  ),
  _FoodReference(
    code: 'shrimp',
    aliases: ['tôm', 'tôm luộc', 'tôm hấp'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 99, proteinG: 24, carbohydratesG: 0.2, fatG: 0.3,
      sodiumMg: 111, cholesterolMg: 189, potassiumMg: 259,
      calciumMg: 70, ironMg: 0.5,
    ),
    allergens: ['động vật có vỏ'],
  ),
  _FoodReference(
    code: 'egg_whole',
    aliases: ['trứng gà', 'trứng', 'trứng luộc'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 143, proteinG: 12.6, carbohydratesG: 0.7, fatG: 9.5,
      sugarG: 0.4, saturatedFatG: 3.1, sodiumMg: 142,
      cholesterolMg: 372, potassiumMg: 138, calciumMg: 56, ironMg: 1.8,
    ),
    allergens: ['trứng'],
  ),
  _FoodReference(
    code: 'tofu',
    aliases: ['đậu phụ', 'đậu hũ'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 76, proteinG: 8.1, carbohydratesG: 1.9, fatG: 4.8,
      fiberG: 0.3, sugarG: 0.6, saturatedFatG: 0.7, sodiumMg: 7,
      potassiumMg: 121, calciumMg: 350, ironMg: 5.4,
    ),
    allergens: ['đậu nành'],
  ),
  _FoodReference(
    code: 'banana',
    aliases: ['chuối', 'chuối chín'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 89, proteinG: 1.1, carbohydratesG: 22.8, fatG: 0.3,
      fiberG: 2.6, sugarG: 12.2, sodiumMg: 1, potassiumMg: 358,
      magnesiumMg: 27, vitaminCMg: 8.7, vitaminB6Mg: 0.4,
    ),
  ),
  _FoodReference(
    code: 'apple',
    aliases: ['táo', 'táo tây'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 52, proteinG: 0.3, carbohydratesG: 13.8, fatG: 0.2,
      fiberG: 2.4, sugarG: 10.4, sodiumMg: 1, potassiumMg: 107,
      vitaminCMg: 4.6,
    ),
  ),
  _FoodReference(
    code: 'guava',
    aliases: ['ổi'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 68, proteinG: 2.6, carbohydratesG: 14.3, fatG: 1,
      fiberG: 5.4, sugarG: 8.9, sodiumMg: 2, potassiumMg: 417,
      vitaminCMg: 228,
    ),
  ),
  _FoodReference(
    code: 'papaya',
    aliases: ['đu đủ', 'đu đủ chín'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 43, proteinG: 0.5, carbohydratesG: 10.8, fatG: 0.3,
      fiberG: 1.7, sugarG: 7.8, sodiumMg: 8, potassiumMg: 182,
      vitaminCMg: 60.9,
    ),
  ),
  _FoodReference(
    code: 'sweet_potato',
    aliases: ['khoai lang', 'khoai lang luộc', 'khoai lang hấp'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 86, proteinG: 1.6, carbohydratesG: 20.1, fatG: 0.1,
      fiberG: 3, sugarG: 4.2, sodiumMg: 55, potassiumMg: 337,
      calciumMg: 30, ironMg: 0.6, magnesiumMg: 25,
    ),
  ),
  _FoodReference(
    code: 'corn_boiled',
    aliases: ['bắp luộc', 'ngô luộc', 'bắp', 'ngô'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 96, proteinG: 3.4, carbohydratesG: 21, fatG: 1.5,
      fiberG: 2.4, sugarG: 4.5, sodiumMg: 1, potassiumMg: 218,
      magnesiumMg: 26,
    ),
  ),
  _FoodReference(
    code: 'spinach',
    aliases: ['cải bó xôi', 'rau chân vịt', 'spinach'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 23, proteinG: 2.9, carbohydratesG: 3.6, fatG: 0.4,
      fiberG: 2.2, sugarG: 0.4, sodiumMg: 79, potassiumMg: 558,
      calciumMg: 99, ironMg: 2.7, magnesiumMg: 79,
      vitaminAMcgRae: 469, vitaminCMg: 28.1, vitaminKMcg: 483,
    ),
  ),
  _FoodReference(
    code: 'broccoli',
    aliases: ['bông cải xanh', 'súp lơ xanh', 'broccoli'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 34, proteinG: 2.8, carbohydratesG: 6.6, fatG: 0.4,
      fiberG: 2.6, sugarG: 1.7, sodiumMg: 33, potassiumMg: 316,
      calciumMg: 47, ironMg: 0.7, vitaminCMg: 89.2, vitaminKMcg: 102,
    ),
  ),
  _FoodReference(
    code: 'cucumber',
    aliases: ['dưa leo', 'dưa chuột'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 15, proteinG: 0.7, carbohydratesG: 3.6, fatG: 0.1,
      fiberG: 0.5, sugarG: 1.7, sodiumMg: 2, potassiumMg: 147,
      waterG: 95.2,
    ),
  ),
  _FoodReference(
    code: 'tomato',
    aliases: ['cà chua'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 18, proteinG: 0.9, carbohydratesG: 3.9, fatG: 0.2,
      fiberG: 1.2, sugarG: 2.6, sodiumMg: 5, potassiumMg: 237,
      vitaminCMg: 13.7, waterG: 94.5,
    ),
  ),
  _FoodReference(
    code: 'peanut',
    aliases: ['đậu phộng', 'lạc', 'đậu phộng rang', 'lạc rang'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 567, proteinG: 25.8, carbohydratesG: 16.1, fatG: 49.2,
      fiberG: 8.5, sugarG: 4.7, saturatedFatG: 6.8, sodiumMg: 18,
      potassiumMg: 705, calciumMg: 92, ironMg: 4.6, magnesiumMg: 168,
    ),
    allergens: ['đậu phộng'],
  ),
  _FoodReference(
    code: 'cashew',
    aliases: ['hạt điều'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 553, proteinG: 18.2, carbohydratesG: 30.2, fatG: 43.9,
      fiberG: 3.3, sugarG: 5.9, saturatedFatG: 7.8, sodiumMg: 12,
      potassiumMg: 660, calciumMg: 37, ironMg: 6.7, magnesiumMg: 292,
    ),
    allergens: ['hạt cây'],
  ),
  _FoodReference(
    code: 'almond',
    aliases: ['hạnh nhân'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 579, proteinG: 21.2, carbohydratesG: 21.6, fatG: 49.9,
      fiberG: 12.5, sugarG: 4.4, saturatedFatG: 3.8, sodiumMg: 1,
      potassiumMg: 733, calciumMg: 269, ironMg: 3.7, magnesiumMg: 270,
    ),
    allergens: ['hạt cây'],
  ),
  _FoodReference(
    code: 'chia_seed',
    aliases: ['hạt chia'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 486, proteinG: 16.5, carbohydratesG: 42.1, fatG: 30.7,
      fiberG: 34.4, sugarG: 0, saturatedFatG: 3.3, sodiumMg: 16,
      potassiumMg: 407, calciumMg: 631, ironMg: 7.7, magnesiumMg: 335,
      omega3G: 17.8, omega6G: 5.8,
    ),
  ),
  _FoodReference(
    code: 'sesame',
    aliases: ['mè', 'vừng', 'hạt mè'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 573, proteinG: 17.7, carbohydratesG: 23.4, fatG: 49.7,
      fiberG: 11.8, sugarG: 0.3, saturatedFatG: 7, sodiumMg: 11,
      potassiumMg: 468, calciumMg: 975, ironMg: 14.6, magnesiumMg: 351,
    ),
    allergens: ['mè'],
  ),
  _FoodReference(
    code: 'milk_cow',
    aliases: ['sữa bò', 'sữa tươi'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 61, proteinG: 3.2, carbohydratesG: 4.8, fatG: 3.3,
      sugarG: 5, saturatedFatG: 1.9, sodiumMg: 43, cholesterolMg: 10,
      potassiumMg: 132, calciumMg: 113, vitaminB12Mcg: 0.5,
    ),
    allergens: ['sữa'],
  ),
  _FoodReference(
    code: 'yogurt_plain',
    aliases: ['sữa chua', 'sữa chua không đường'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 61, proteinG: 3.5, carbohydratesG: 4.7, fatG: 3.3,
      sugarG: 4.7, saturatedFatG: 2.1, sodiumMg: 46, cholesterolMg: 13,
      potassiumMg: 141, calciumMg: 121, vitaminB12Mcg: 0.4,
    ),
    allergens: ['sữa'],
  ),
  _FoodReference(
    code: 'soy_milk',
    aliases: ['sữa đậu nành'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 54, proteinG: 3.3, carbohydratesG: 6.3, fatG: 1.8,
      fiberG: 0.6, sugarG: 4, sodiumMg: 51, potassiumMg: 118,
      calciumMg: 25, ironMg: 0.6,
    ),
    allergens: ['đậu nành'],
  ),
  _FoodReference(
    code: 'olive_oil',
    aliases: ['dầu ô liu', 'dầu olive'],
    nutritionPer100g: NutritionEstimate(
      caloriesKcal: 884, proteinG: 0, carbohydratesG: 0, fatG: 100,
      saturatedFatG: 13.8, monounsaturatedFatG: 73, polyunsaturatedFatG: 10.5,
      vitaminEMg: 14.4, vitaminKMcg: 60,
    ),
  ),
];
