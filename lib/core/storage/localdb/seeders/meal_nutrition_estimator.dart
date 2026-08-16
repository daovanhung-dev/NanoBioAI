import '../models/ai_catalog_models.dart';

class MealNutritionEstimate {
  const MealNutritionEstimate({
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
    required this.servingSize,
    required this.coverage,
  });

  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int waterMl;
  final double sugarG;
  final double saturatedFatG;
  final double sodiumMg;
  final double cholesterolMg;
  final double potassiumMg;
  final double calciumMg;
  final double ironMg;
  final String servingSize;
  final double coverage;
}

/// Deterministic, offline estimator for source recipes that do not contain
/// nutrition facts. Reference values are representative generic foods per
/// 100 g, curated from USDA FoodData Central. These values are estimates and
/// must never be presented as laboratory measurements or medical advice.
class MealNutritionEstimator {
  const MealNutritionEstimator._();

  static MealCatalogItemModel enrichIfMissing(MealCatalogItemModel item) {
    if (item.nutritionStatus != 'missing_source_data' ||
        item.ingredients.isEmpty) {
      return item;
    }
    final nutritionEstimate = estimate(
      ingredients: item.ingredients,
      mealName: item.mealName,
    );
    if (nutritionEstimate == null) return item;
    return item.copyWith(
      calories: nutritionEstimate.calories,
      protein: nutritionEstimate.protein,
      carbs: nutritionEstimate.carbs,
      fat: nutritionEstimate.fat,
      fiber: nutritionEstimate.fiber,
      waterMl: nutritionEstimate.waterMl,
      sugarG: nutritionEstimate.sugarG,
      saturatedFatG: nutritionEstimate.saturatedFatG,
      sodiumMg: nutritionEstimate.sodiumMg,
      cholesterolMg: nutritionEstimate.cholesterolMg,
      potassiumMg: nutritionEstimate.potassiumMg,
      calciumMg: nutritionEstimate.calciumMg,
      ironMg: nutritionEstimate.ironMg,
      servingSize: nutritionEstimate.servingSize,
      nutritionStatus: 'estimated_from_ingredients',
    );
  }

  static MealNutritionEstimate? estimate({
    required List<String> ingredients,
    required String mealName,
  }) {
    var totals = const _Totals();
    var matchedMass = 0.0;
    var quantifiedMass = 0.0;
    var liquidMl = 0.0;

    for (final raw in ingredients) {
      final text = _normalize(raw);
      if (text.isEmpty || _isUnquantifiedSeasoning(text)) continue;
      final food = _findFood(text);
      final quantity = _quantity(text, food);
      if (quantity == null || quantity.grams <= 0) continue;
      quantifiedMass += quantity.grams;
      if (quantity.liquidMl > 0) liquidMl += quantity.liquidMl;
      if (food == null) continue;
      matchedMass += quantity.grams;
      totals = totals + food.nutrients.scaled(quantity.grams / 100.0);
    }

    if (matchedMass <= 0) return null;
    final coverage = quantifiedMass <= 0 ? 1.0 : matchedMass / quantifiedMass;
    if (coverage < .45) return null;

    final servings = _estimateServings(
      mealName: mealName,
      totalMass: matchedMass,
      liquidMl: liquidMl,
    );
    final perServing = totals.scaled(1 / servings);
    final macroCalories =
        perServing.protein * 4 + perServing.carbs * 4 + perServing.fat * 9;
    final calories = perServing.calories > 0
        ? perServing.calories
        : macroCalories;
    if (calories < 5) return null;

    return MealNutritionEstimate(
      calories: calories.round(),
      protein: _round1(perServing.protein),
      carbs: _round1(perServing.carbs),
      fat: _round1(perServing.fat),
      fiber: _round1(perServing.fiber),
      waterMl: (liquidMl / servings).round(),
      sugarG: _round1(perServing.sugar),
      saturatedFatG: _round1(perServing.saturatedFat),
      sodiumMg: _round1(perServing.sodium),
      cholesterolMg: _round1(perServing.cholesterol),
      potassiumMg: _round1(perServing.potassium),
      calciumMg: _round1(perServing.calcium),
      ironMg: _round1(perServing.iron),
      servingSize: '1 khẩu phần (ước tính)',
      coverage: coverage.clamp(0, 1).toDouble(),
    );
  }

  static int _estimateServings({
    required String mealName,
    required double totalMass,
    required double liquidMl,
  }) {
    final name = _normalize(mealName);
    final drink = name.contains('sinh tố') ||
        name.contains('nước ép') ||
        name.contains('trà ') ||
        name.startsWith('trà') ||
        name.contains('sữa ');
    if (drink || liquidMl >= 150) return 1;
    final estimated = (totalMass / 350).ceil();
    return estimated.clamp(1, 4).toInt();
  }

  static _Food? _findFood(String text) {
    _Food? best;
    var bestLength = -1;
    for (final food in _foods) {
      for (final alias in food.aliases) {
        if (text.contains(alias) && alias.length > bestLength) {
          best = food;
          bestLength = alias.length;
        }
      }
    }
    return best;
  }

  static _Quantity? _quantity(String text, _Food? food) {
    final metric = RegExp(r'(\d+(?:[\.,]\d+)?)\s*(kg|g|ml|l)\b').firstMatch(text);
    if (metric != null) {
      final value = double.tryParse(metric.group(1)!.replaceAll(',', '.')) ?? 0;
      final unit = metric.group(2)!;
      switch (unit) {
        case 'kg':
          return _Quantity(value * 1000, 0);
        case 'g':
          return _Quantity(value, 0);
        case 'l':
          final ml = value * 1000;
          return _Quantity(ml * (food?.density ?? 1.0), ml);
        case 'ml':
          return _Quantity(value * (food?.density ?? 1.0), value);
      }
    }

    final count = _leadingCount(text);
    if (count == null) return null;
    final itemWeight = food?.itemWeightG ?? _genericHouseholdWeight(text);
    if (itemWeight == null) return null;
    final liquidMl = _looksLiquidMeasure(text) ? count * itemWeight : 0.0;
    return _Quantity(count * itemWeight * (food?.density ?? 1.0), liquidMl);
  }

  static double? _leadingCount(String text) {
    final normalized = text
        .replaceAll('½', '0.5')
        .replaceAll('¼', '0.25')
        .replaceAll('¾', '0.75');
    final fraction = RegExp(r'^\s*(\d+)\s*/\s*(\d+)').firstMatch(normalized);
    if (fraction != null) {
      final numerator = double.tryParse(fraction.group(1)!) ?? 0;
      final denominator = double.tryParse(fraction.group(2)!) ?? 1.0;
      return denominator == 0 ? null : numerator / denominator;
    }
    final number = RegExp(r'^\s*(\d+(?:[\.,]\d+)?)').firstMatch(normalized);
    return number == null
        ? null
        : double.tryParse(number.group(1)!.replaceAll(',', '.'));
  }

  static double? _genericHouseholdWeight(String text) {
    if (text.contains('thìa cà phê') || text.contains('muỗng cà phê')) return 5;
    if (text.contains('thìa') || text.contains('muỗng')) return 15;
    if (text.contains('chén') || text.contains('cốc')) return 180;
    if (text.contains('nắm')) return 35;
    if (text.contains('hộp')) return 100;
    if (text.contains('túi trà')) return 2;
    if (text.contains('nhánh')) return 10;
    if (text.contains('lá')) return 5;
    return null;
  }

  static bool _looksLiquidMeasure(String text) =>
      text.contains('chén') || text.contains('cốc') || text.contains('thìa');

  static bool _isUnquantifiedSeasoning(String text) =>
      text.startsWith('gia vị') ||
      text.contains('vừa ăn') ||
      text.contains('vừa đủ') ||
      text == 'muối' ||
      text == 'tiêu' ||
      text == 'đường';

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[–—−]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ');

  static double _round1(double value) => (value * 10).round() / 10;

  static const _foods = <_Food>[
    _Food(['dầu ô liu', 'dầu olive'], _Totals(calories: 884, fat: 100, saturatedFat: 13.8), density: .91, itemWeightG: 15),
    _Food(['dầu ăn', 'dầu thực vật'], _Totals(calories: 884, fat: 100, saturatedFat: 14), density: .92, itemWeightG: 15),
    _Food(['mật ong'], _Totals(calories: 304, carbs: 82.4, sugar: 82.1, potassium: 52, calcium: 6, iron: .4), density: 1.42, itemWeightG: 15),
    _Food(['hạt óc chó', 'quả óc chó', 'óc chó'], _Totals(calories: 654, protein: 15.2, carbs: 13.7, fat: 65.2, fiber: 6.7, sugar: 2.6, saturatedFat: 6.1, sodium: 2, potassium: 441, calcium: 98, iron: 2.9), itemWeightG: 4),
    _Food(['hạt điều'], _Totals(calories: 553, protein: 18.2, carbs: 30.2, fat: 43.9, fiber: 3.3, sugar: 5.9, saturatedFat: 7.8, sodium: 12, potassium: 660, calcium: 37, iron: 6.7), itemWeightG: 1.6),
    _Food(['hạnh nhân'], _Totals(calories: 579, protein: 21.2, carbs: 21.6, fat: 49.9, fiber: 12.5, sugar: 4.4, saturatedFat: 3.8, sodium: 1, potassium: 733, calcium: 269, iron: 3.7), itemWeightG: 1.2),
    _Food(['hạt chia'], _Totals(calories: 486, protein: 16.5, carbs: 42.1, fat: 30.7, fiber: 34.4, sugar: 0, saturatedFat: 3.3, sodium: 16, potassium: 407, calcium: 631, iron: 7.7), itemWeightG: 12),
    _Food(['mè', 'vừng'], _Totals(calories: 573, protein: 17.7, carbs: 23.4, fat: 49.7, fiber: 11.8, sugar: .3, saturatedFat: 7, sodium: 11, potassium: 468, calcium: 975, iron: 14.6), itemWeightG: 9),
    _Food(['đậu phộng', 'lạc'], _Totals(calories: 567, protein: 25.8, carbs: 16.1, fat: 49.2, fiber: 8.5, sugar: 4.7, saturatedFat: 6.8, sodium: 18, potassium: 705, calcium: 92, iron: 4.6)),
    _Food(['thịt bò'], _Totals(calories: 250, protein: 26, fat: 15, saturatedFat: 6, sodium: 72, cholesterol: 90, potassium: 318, calcium: 18, iron: 2.6)),
    _Food(['thịt gà', 'ức gà'], _Totals(calories: 165, protein: 31, fat: 3.6, saturatedFat: 1, sodium: 74, cholesterol: 85, potassium: 256, calcium: 15, iron: 1)),
    _Food(['thịt heo', 'thịt lợn'], _Totals(calories: 242, protein: 27.3, fat: 13.9, saturatedFat: 5.1, sodium: 62, cholesterol: 80, potassium: 423, calcium: 19, iron: .9)),
    _Food(['cá hồi'], _Totals(calories: 208, protein: 20.4, fat: 13.4, saturatedFat: 3.1, sodium: 59, cholesterol: 55, potassium: 363, calcium: 9, iron: .3)),
    _Food(['cá thu'], _Totals(calories: 205, protein: 18.6, fat: 13.9, saturatedFat: 3.3, sodium: 90, cholesterol: 70, potassium: 314, calcium: 12, iron: 1.6)),
    _Food(['cá '], _Totals(calories: 128, protein: 26, fat: 2.7, saturatedFat: .7, sodium: 56, cholesterol: 57, potassium: 380, calcium: 14, iron: .5)),
    _Food(['tôm'], _Totals(calories: 99, protein: 24, carbs: .2, fat: .3, sodium: 111, cholesterol: 189, potassium: 259, calcium: 70, iron: .5)),
    _Food(['hàu'], _Totals(calories: 68, protein: 7, carbs: 3.9, fat: 2.5, saturatedFat: .8, sodium: 90, cholesterol: 55, potassium: 156, calcium: 45, iron: 6.7)),
    _Food(['trứng'], _Totals(calories: 143, protein: 12.6, carbs: .7, fat: 9.5, sugar: .4, saturatedFat: 3.1, sodium: 142, cholesterol: 372, potassium: 138, calcium: 56, iron: 1.8), itemWeightG: 50),
    _Food(['đậu phụ', 'đậu hũ'], _Totals(calories: 76, protein: 8.1, carbs: 1.9, fat: 4.8, fiber: .3, sugar: .6, saturatedFat: .7, sodium: 7, potassium: 121, calcium: 350, iron: 5.4)),
    _Food(['gạo lứt'], _Totals(calories: 370, protein: 7.9, carbs: 77.2, fat: 2.9, fiber: 3.5, sugar: .9, sodium: 7, potassium: 223, calcium: 23, iron: 1.5)),
    _Food(['gạo nếp'], _Totals(calories: 370, protein: 6.8, carbs: 81.7, fat: .6, fiber: 2.8, sodium: 7, potassium: 77, calcium: 11, iron: 1.2)),
    _Food(['gạo tẻ', 'gạo trắng', 'gạo'], _Totals(calories: 365, protein: 7.1, carbs: 80, fat: .7, fiber: 1.3, sugar: .1, sodium: 5, potassium: 115, calcium: 28, iron: .8)),
    _Food(['yến mạch'], _Totals(calories: 389, protein: 16.9, carbs: 66.3, fat: 6.9, fiber: 10.6, sugar: 1, saturatedFat: 1.2, sodium: 2, potassium: 429, calcium: 54, iron: 4.7)),
    _Food(['khoai lang'], _Totals(calories: 86, protein: 1.6, carbs: 20.1, fat: .1, fiber: 3, sugar: 4.2, sodium: 55, potassium: 337, calcium: 30, iron: .6), itemWeightG: 130),
    _Food(['khoai tây'], _Totals(calories: 77, protein: 2, carbs: 17.5, fat: .1, fiber: 2.2, sugar: .8, sodium: 6, potassium: 425, calcium: 12, iron: .8), itemWeightG: 170),
    _Food(['đậu xanh'], _Totals(calories: 347, protein: 23.9, carbs: 62.6, fat: 1.2, fiber: 16.3, sugar: 6.6, saturatedFat: .3, sodium: 15, potassium: 1246, calcium: 132, iron: 6.7)),
    _Food(['đậu đỏ'], _Totals(calories: 329, protein: 19.9, carbs: 62.9, fat: .5, fiber: 12.7, sugar: 2.1, sodium: 5, potassium: 1254, calcium: 66, iron: 5)),
    _Food(['đậu đen'], _Totals(calories: 341, protein: 21.6, carbs: 62.4, fat: 1.4, fiber: 15.5, sugar: 2.1, sodium: 5, potassium: 1483, calcium: 123, iron: 5)),
    _Food(['hạt sen'], _Totals(calories: 324, protein: 15.4, carbs: 64.5, fat: 2, fiber: 7.9, sodium: 5, potassium: 1368, calcium: 163, iron: 3.5), itemWeightG: 2.5),
    _Food(['cải bó xôi', 'rau bina'], _Totals(calories: 23, protein: 2.9, carbs: 3.6, fat: .4, fiber: 2.2, sugar: .4, sodium: 79, potassium: 558, calcium: 99, iron: 2.7)),
    _Food(['cải xoăn', 'kale'], _Totals(calories: 35, protein: 2.9, carbs: 4.4, fat: 1.5, fiber: 4.1, sugar: 1, sodium: 53, potassium: 348, calcium: 254, iron: 1.6)),
    _Food(['bông cải xanh', 'súp lơ xanh'], _Totals(calories: 34, protein: 2.8, carbs: 6.6, fat: .4, fiber: 2.6, sugar: 1.7, sodium: 33, potassium: 316, calcium: 47, iron: .7)),
    _Food(['cà rốt'], _Totals(calories: 41, protein: .9, carbs: 9.6, fat: .2, fiber: 2.8, sugar: 4.7, sodium: 69, potassium: 320, calcium: 33, iron: .3), itemWeightG: 61),
    _Food(['củ dền'], _Totals(calories: 43, protein: 1.6, carbs: 9.6, fat: .2, fiber: 2.8, sugar: 6.8, sodium: 78, potassium: 325, calcium: 16, iron: .8), itemWeightG: 82),
    _Food(['bí đỏ', 'bí ngô'], _Totals(calories: 26, protein: 1, carbs: 6.5, fat: .1, fiber: .5, sugar: 2.8, sodium: 1, potassium: 340, calcium: 21, iron: .8)),
    _Food(['cà chua'], _Totals(calories: 18, protein: .9, carbs: 3.9, fat: .2, fiber: 1.2, sugar: 2.6, sodium: 5, potassium: 237, calcium: 10, iron: .3), itemWeightG: 123),
    _Food(['dưa leo', 'dưa chuột'], _Totals(calories: 15, protein: .7, carbs: 3.6, fat: .1, fiber: .5, sugar: 1.7, sodium: 2, potassium: 147, calcium: 16, iron: .3), itemWeightG: 200),
    _Food(['nấm đông cô', 'nấm hương'], _Totals(calories: 34, protein: 2.2, carbs: 6.8, fat: .5, fiber: 2.5, sugar: 2.4, sodium: 9, potassium: 304, calcium: 2, iron: .4)),
    _Food(['nấm'], _Totals(calories: 22, protein: 3.1, carbs: 3.3, fat: .3, fiber: 1, sugar: 2, sodium: 5, potassium: 318, calcium: 3, iron: .5)),
    _Food(['hành tím'], _Totals(calories: 72, protein: 2.5, carbs: 16.8, fat: .1, fiber: 3.2, sugar: 7.9, sodium: 12, potassium: 334, calcium: 37, iron: 1.2), itemWeightG: 25),
    _Food(['hành tây'], _Totals(calories: 40, protein: 1.1, carbs: 9.3, fat: .1, fiber: 1.7, sugar: 4.2, sodium: 4, potassium: 146, calcium: 23, iron: .2), itemWeightG: 110),
    _Food(['chuối'], _Totals(calories: 89, protein: 1.1, carbs: 22.8, fat: .3, fiber: 2.6, sugar: 12.2, sodium: 1, potassium: 358, calcium: 5, iron: .3), itemWeightG: 118),
    _Food(['quả bơ', 'trái bơ', 'bơ chín'], _Totals(calories: 160, protein: 2, carbs: 8.5, fat: 14.7, fiber: 6.7, sugar: .7, saturatedFat: 2.1, sodium: 7, potassium: 485, calcium: 12, iron: .6), itemWeightG: 136),
    _Food(['táo'], _Totals(calories: 52, protein: .3, carbs: 13.8, fat: .2, fiber: 2.4, sugar: 10.4, sodium: 1, potassium: 107, calcium: 6, iron: .1), itemWeightG: 182),
    _Food(['đu đủ'], _Totals(calories: 43, protein: .5, carbs: 10.8, fat: .3, fiber: 1.7, sugar: 7.8, sodium: 8, potassium: 182, calcium: 20, iron: .3), itemWeightG: 300),
    _Food(['dứa', 'thơm', 'khóm'], _Totals(calories: 50, protein: .5, carbs: 13.1, fat: .1, fiber: 1.4, sugar: 9.9, sodium: 1, potassium: 109, calcium: 13, iron: .3), itemWeightG: 165),
    _Food(['cam'], _Totals(calories: 47, protein: .9, carbs: 11.8, fat: .1, fiber: 2.4, sugar: 9.4, sodium: 0, potassium: 181, calcium: 40, iron: .1), itemWeightG: 131),
    _Food(['bưởi'], _Totals(calories: 42, protein: .8, carbs: 10.7, fat: .1, fiber: 1.6, sugar: 7, sodium: 0, potassium: 135, calcium: 22, iron: .1), itemWeightG: 230),
    _Food(['chanh'], _Totals(calories: 29, protein: 1.1, carbs: 9.3, fat: .3, fiber: 2.8, sugar: 2.5, sodium: 2, potassium: 138, calcium: 26, iron: .6), itemWeightG: 58),
    _Food(['sữa chua'], _Totals(calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3, sugar: 4.7, saturatedFat: 2.1, sodium: 46, cholesterol: 13, potassium: 155, calcium: 121, iron: .1), itemWeightG: 100),
    _Food(['sữa hạnh nhân'], _Totals(calories: 15, protein: .6, carbs: .6, fat: 1.2, fiber: .3, sugar: .2, saturatedFat: .1, sodium: 72, potassium: 67, calcium: 184, iron: .3), density: 1),
    _Food(['nước dừa'], _Totals(calories: 19, protein: .7, carbs: 3.7, fat: .2, fiber: 1.1, sugar: 2.6, sodium: 105, potassium: 250, calcium: 24, iron: .3), density: 1),
    _Food(['nước'], _Totals(), density: 1),
    _Food(['gừng'], _Totals(calories: 80, protein: 1.8, carbs: 17.8, fat: .8, fiber: 2, sugar: 1.7, sodium: 13, potassium: 415, calcium: 16, iron: .6), itemWeightG: 10),
    _Food(['nghệ'], _Totals(calories: 312, protein: 9.7, carbs: 67.1, fat: 3.3, fiber: 22.7, sugar: 3.2, sodium: 38, potassium: 2080, calcium: 168, iron: 55), itemWeightG: 8),
  ];
}

class _Food {
  const _Food(
    this.aliases,
    this.nutrients, {
    this.density = 1,
    this.itemWeightG,
  });

  final List<String> aliases;
  final _Totals nutrients;
  final double density;
  final double? itemWeightG;
}

class _Quantity {
  const _Quantity(this.grams, this.liquidMl);
  final double grams;
  final double liquidMl;
}

class _Totals {
  const _Totals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.saturatedFat = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.potassium = 0,
    this.calcium = 0,
    this.iron = 0,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double saturatedFat;
  final double sodium;
  final double cholesterol;
  final double potassium;
  final double calcium;
  final double iron;

  _Totals scaled(double factor) => _Totals(
        calories: calories * factor,
        protein: protein * factor,
        carbs: carbs * factor,
        fat: fat * factor,
        fiber: fiber * factor,
        sugar: sugar * factor,
        saturatedFat: saturatedFat * factor,
        sodium: sodium * factor,
        cholesterol: cholesterol * factor,
        potassium: potassium * factor,
        calcium: calcium * factor,
        iron: iron * factor,
      );

  _Totals operator +(_Totals other) => _Totals(
        calories: calories + other.calories,
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
        fiber: fiber + other.fiber,
        sugar: sugar + other.sugar,
        saturatedFat: saturatedFat + other.saturatedFat,
        sodium: sodium + other.sodium,
        cholesterol: cholesterol + other.cholesterol,
        potassium: potassium + other.potassium,
        calcium: calcium + other.calcium,
        iron: iron + other.iron,
      );
}
