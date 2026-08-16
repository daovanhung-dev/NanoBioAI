import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/meal_plan_nutrition_sync_columns.dart';

void main() {
  test('meal plan nutrition snapshot columns stay complete', () {
    expect(
      mealPlanNutritionSyncColumns,
      containsAll(<String>{
        'sugar_g',
        'saturated_fat_g',
        'sodium_mg',
        'cholesterol_mg',
        'potassium_mg',
        'calcium_mg',
        'iron_mg',
        'nutrition_status',
      }),
    );
  });

  test('local and remote snapshot filters include nutrition extension', () {
    final localSource = File(
      'lib/app_versions/v2/features/cloud_sync/data/datasources/'
      'sqlite_user_data_sync_local_datasource.dart',
    ).readAsStringSync();
    final remoteSource = File(
      'lib/app_versions/v2/features/cloud_sync/data/datasources/'
      'supabase_user_data_sync_remote_datasource.dart',
    ).readAsStringSync();

    expect(localSource, contains('mealPlanNutritionSyncColumns'));
    expect(remoteSource, contains('mealPlanNutritionSyncColumns'));
    expect(remoteSource, contains('_allowedCloudColumns'));
  });
}
