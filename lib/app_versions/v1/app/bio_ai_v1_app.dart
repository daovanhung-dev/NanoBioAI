import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';
import 'package:nano_app/l10n/app_localizations.dart';

class BioAIV1App extends ConsumerStatefulWidget {
  const BioAIV1App({super.key});

  @override
  ConsumerState<BioAIV1App> createState() => _BioAIV1AppState();
}

class _BioAIV1AppState extends ConsumerState<BioAIV1App> {
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
    final textScaleFactor = ref
            .watch(appTextScaleControllerProvider)
            .value
            ?.preset
            .factor ??
        AppTextScalePreset.standard.factor;
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
      ),

      theme: AppTheme.lightTheme,

      routerConfig: v1Router,
    );
  }

  void _openNotificationUri(Uri uri) {
    if (mounted) v1Router.go(uri.toString());
  }

  @override
  void dispose() {
    NotificationNavigationCoordinator.unregister(_notificationNavigator);
    super.dispose();
  }
}
