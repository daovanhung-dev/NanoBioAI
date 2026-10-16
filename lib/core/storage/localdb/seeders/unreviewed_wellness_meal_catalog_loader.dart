import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ai_catalog_models.dart';

class UnreviewedWellnessMealCatalogLoader {
  const UnreviewedWellnessMealCatalogLoader._();

  static const assetPath = 'assets/data/nabi_3000_mon_viet_moi.json';
  static const expectedMealCount = 3000;

  static Future<List<MealCatalogItemModel>> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Wellness candidate catalog root is invalid.',
      );
    }
    final recipes = decoded['recipes'];
    if (recipes is! List) {
      throw const FormatException('Wellness candidate recipes are missing.');
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final meals = recipes
        .map((recipe) {
          if (recipe is! Map) {
            throw const FormatException(
              'Wellness candidate recipe must be an object.',
            );
          }
          return MealCatalogItemModel.fromSourceJson(
            Map<String, Object?>.from(recipe),
            timestamp: timestamp,
          );
        })
        .toList(growable: false);
    _validate(meals);
    return meals;
  }

  static void _validate(List<MealCatalogItemModel> meals) {
    if (meals.length != expectedMealCount) {
      throw FormatException(
        'Expected $expectedMealCount wellness candidates, got ${meals.length}.',
      );
    }
    final codes = <String>{};
    for (final meal in meals) {
      if (!meal.isUnreviewedWellnessScheduleCandidate) {
        throw FormatException(
          'Wellness candidate is incomplete or has unexpected review status: '
          '${meal.code}.',
        );
      }
      if (!codes.add(meal.code)) {
        throw FormatException(
          'Duplicate wellness candidate code: ${meal.code}.',
        );
      }
    }
  }
}
