import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings provider centralizes user-scoped cache invalidation', () {
    final source = File(
      'lib/app_versions/v1/features/settings/providers/settings_provider.dart',
    ).readAsStringSync();

    expect(source, contains('invalidateUserScopedProviders'));
    expect(source, contains('dashboardProvider'));
    expect(source, contains('dashboardDynamicProvider'));
    expect(source, contains('dailyHealthTrackingControllerProvider'));
    expect(source, contains('lifestyleScheduleControllerProvider'));
    expect(source, contains('mealPlanControllerProvider'));
    expect(source, contains('getMealPlanProvider'));
    expect(source, contains('nutritionSummaryProvider'));
    expect(source, contains('settingsPreferencesControllerProvider'));
    expect(source, contains('settingsCacheSizeProvider'));
  });
}
