import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nano_app/app_versions/v1/features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';

import '../data/datasources/settings_local_datasource.dart';
import '../data/models/settings_preferences_model.dart';
import '../domain/entities/settings_preferences_entity.dart';

final settingsLocalDatasourceProvider = Provider<SettingsLocalDatasource>((
  ref,
) {
  return const SettingsLocalDatasource();
});

final settingsCacheSizeProvider = FutureProvider<int>((ref) {
  return ref.read(settingsLocalDatasourceProvider).calculateCacheSize();
});

final settingsPreferencesControllerProvider =
    AsyncNotifierProvider<
      SettingsPreferencesController,
      SettingsPreferencesEntity
    >(SettingsPreferencesController.new);

void invalidateUserScopedProviders(WidgetRef ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardDynamicProvider);
  ref.invalidate(dailyHealthTrackingControllerProvider);
  ref.invalidate(lifestyleScheduleControllerProvider);
  ref.invalidate(mealPlanControllerProvider);
  ref.invalidate(getMealPlanProvider);
  ref.invalidate(nutritionSummaryProvider);
  ref.invalidate(settingsPreferencesControllerProvider);
  ref.invalidate(settingsCacheSizeProvider);
}

void invalidateUserScopedContainerProviders(Ref ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardDynamicProvider);
  ref.invalidate(dailyHealthTrackingControllerProvider);
  ref.invalidate(lifestyleScheduleControllerProvider);
  ref.invalidate(mealPlanControllerProvider);
  ref.invalidate(getMealPlanProvider);
  ref.invalidate(nutritionSummaryProvider);
  ref.invalidate(settingsPreferencesControllerProvider);
  ref.invalidate(settingsCacheSizeProvider);
}

class SettingsPreferencesController
    extends AsyncNotifier<SettingsPreferencesEntity> {
  late final SettingsLocalDatasource _datasource;

  @override
  Future<SettingsPreferencesEntity> build() async {
    _datasource = ref.read(settingsLocalDatasourceProvider);
    return _loadPreferences();
  }

  Future<void> setDarkMode(bool value) async {
    await _update((current) async {
      await _datasource.saveStringPreference(
        SettingsPreferencesModel.keyThemeMode,
        value ? 'dark' : 'light',
      );
      return current.copyWith(isDarkMode: value);
    });
  }

  Future<void> setPushEnabled(bool value) async {
    await _update((current) async {
      await _datasource.saveBoolPreference(
        SettingsPreferencesModel.keyPushEnabled,
        value,
      );
      return current.copyWith(pushEnabled: value);
    });
  }

  Future<void> clearCache() async {
    await _datasource.clearCache();
    ref.invalidate(settingsCacheSizeProvider);
  }

  Future<void> _update(
    Future<SettingsPreferencesEntity> Function(
      SettingsPreferencesEntity current,
    )
    updater,
  ) async {
    final current =
        state.whenOrNull(data: (value) => value) ?? await _loadPreferences();
    state = AsyncData(await updater(current));
  }

  Future<SettingsPreferencesEntity> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final model = SettingsPreferencesModel.fromPreferences(prefs);
    if (prefs.getString(SettingsPreferencesModel.keyLanguageCode) != 'vi') {
      await prefs.setString(SettingsPreferencesModel.keyLanguageCode, 'vi');
    }
    return model;
  }
}
