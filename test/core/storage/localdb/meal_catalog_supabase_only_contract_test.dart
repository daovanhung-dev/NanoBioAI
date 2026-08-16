import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active bundle no longer requires is_plan_eligible', () {
    final source = File(
      'lib/core/storage/localdb/daos/ai_catalog_dao.dart',
    ).readAsStringSync();

    expect(source, contains('getActiveMeals(planEligibleOnly: false)'));
    expect(source, contains('bool planEligibleOnly = false'));
  });

  test('Supabase refresh replaces the complete local meal cache', () {
    final source = File(
      'lib/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart',
    ).readAsStringSync();

    expect(source, contains(".from('meal_catalog')"));
    expect(source, contains(".eq('is_active', true)"));
    expect(source, contains('replaceMeals(remoteItems)'));
    expect(source, isNot(contains('upsertMeals(remoteItems)')));
  });

  test('meal generation entry points refresh Supabase before generation', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final controllerSource = File(
      'lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart',
    ).readAsStringSync();

    expect(mainSource, contains('_refreshRequiredMealCatalog'));
    expect(
      mainSource,
      contains('MealCatalogCacheRefreshService.refreshFromInitializedSupabase'),
    );
    expect(controllerSource, contains('_refreshRequiredSupabaseMealCatalog'));
    expect(
      controllerSource,
      contains('MealCatalogCacheRefreshService.refreshFromInitializedSupabase'),
    );
  });

  test('legacy local seeds cannot survive a successful Supabase refresh', () {
    final daoSource = File(
      'lib/core/storage/localdb/daos/ai_catalog_dao.dart',
    ).readAsStringSync();
    final refreshSource = File(
      'lib/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart',
    ).readAsStringSync();

    expect(daoSource, contains('txn.delete(MealCatalogTable.tableName)'));
    expect(refreshSource, contains('replaceMeals(remoteItems)'));
  });
}
