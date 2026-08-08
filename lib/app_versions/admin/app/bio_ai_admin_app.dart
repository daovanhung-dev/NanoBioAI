import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/router/admin_router.dart';
import 'package:nano_app/app_versions/admin/theme/admin_workspace_theme.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/l10n/app_localizations.dart';

class BioAIAdminApp extends ConsumerWidget {
  const BioAIAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiencePreferences =
        ref.watch(appExperiencePreferencesProvider).value ??
        AppExperiencePreferences.defaults;
    final textScaleFactor =
        ref.watch(appTextScaleControllerProvider).value?.preset.factor ??
        AppTextScalePreset.standard.factor;
    final isDarkMode =
        ref.watch(settingsPreferencesControllerProvider).value?.isDarkMode ??
        false;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).adminAppTitle,
      locale: AppLocalizationConfig.locale,
      supportedLocales: AppLocalizationConfig.supportedLocales,
      localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AppExperience.builderWithTextScale(
        context,
        child,
        presetFactor: textScaleFactor,
        preferences: experiencePreferences,
      ),
      theme: AdminWorkspaceTheme.light(AppTheme.lightTheme),
      darkTheme: AdminWorkspaceTheme.dark(AppTheme.darkTheme),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: adminRouter,
    );
  }
}
