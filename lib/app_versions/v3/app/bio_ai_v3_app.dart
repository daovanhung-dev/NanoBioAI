import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v3/router/v3_router.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/core/theme/app_experience_preferences.dart';
import 'package:nano_app/l10n/app_localizations.dart';

class BioAIV3App extends ConsumerStatefulWidget {
  const BioAIV3App({super.key});

  @override
  ConsumerState<BioAIV3App> createState() => _BioAIV3AppState();
}

class _BioAIV3AppState extends ConsumerState<BioAIV3App> {
  late final NotificationNavigator _notificationNavigator =
      _openNotificationUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationNavigationCoordinator.register(_notificationNavigator);
    });
  }

  @override
  Widget build(BuildContext context) {
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
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: v3Router,
    );
  }

  void _openNotificationUri(Uri uri) {
    if (mounted) v3Router.go(uri.toString());
  }

  @override
  void dispose() {
    NotificationNavigationCoordinator.unregister(_notificationNavigator);
    super.dispose();
  }
}
