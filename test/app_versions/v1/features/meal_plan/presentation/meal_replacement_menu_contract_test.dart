import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal replacement UI is user-selected and never auto-replaces from the page', () {
    final source = File(
      'lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart',
    ).readAsStringSync();

    expect(source, contains('Các món phù hợp với bạn'));
    expect(source, contains('loadReplacementCandidates(meal.id)'));
    expect(source, contains('replaceMealByCatalogCode('));
    expect(source, contains("'Chọn món này'"));
    expect(source, contains('MealReplacementSyncStatus.synced'));
    expect(source, contains('MealReplacementSyncStatus.pending'));
    expect(source, isNot(contains('.replaceMealById(meal.id)')));
  });

  test('replacement path does not import or invoke AI services', () {
    final datasource = File(
      'lib/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart',
    ).readAsStringSync();

    for (final source in <String>[datasource, controller]) {
      expect(source, isNot(contains('AIService')));
      expect(source, isNot(contains('Gemini')));
      expect(source, isNot(contains('GeneratedPlanService')));
    }
  });
}
