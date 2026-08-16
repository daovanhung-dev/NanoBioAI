import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ai_catalog_models.dart';
import 'meal_nutrition_estimator.dart';

class SourceMealCatalogLoader {
  const SourceMealCatalogLoader._();

  static const assetPath = 'assets/data/meal_catalog_v1.json';

  static Future<List<MealCatalogItemModel>> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Meal catalog root must be an object.');
    }
    final recipes = decoded['recipes'];
    if (recipes is! List) {
      throw const FormatException('Meal catalog recipes must be a list.');
    }
    final timestamp = DateTime.now().toUtc().toIso8601String();
    return recipes
        .whereType<Map>()
        .map(
          (recipe) => MealCatalogItemModel.fromSourceJson(
            Map<String, Object?>.from(recipe),
            timestamp: timestamp,
          ),
        )
        .map(MealNutritionEstimator.enrichIfMissing)
        .toList(growable: false);
  }
}
