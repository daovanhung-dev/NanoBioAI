import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal plan card and detail both render MealPhoto', () {
    final source = File(
      'lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart',
    ).readAsStringSync();

    expect(source, contains("presentation/widgets/meal_photo.dart"));
    expect('MealPhoto('.allMatches(source).length, greaterThanOrEqualTo(2));
  });

  test('MealPhoto resolves verified assets before building Image.asset', () {
    final source = File(
      'lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('MealImageResolver.resolveAssetPath(meal.mealName)'),
    );
    expect(source, contains('if (assetPath == null)'));
    expect(source, contains('Image.asset('));
    expect(source, contains('_MealPhotoFallback('));
  });
}
