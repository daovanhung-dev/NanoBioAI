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
}
