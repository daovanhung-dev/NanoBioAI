import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';
import 'package:nano_app/app_versions/v3/router/v3_router.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/l10n/app_localizations.dart';

class BioAIV3App extends StatefulWidget {
  const BioAIV3App({super.key});

  @override
  State<BioAIV3App> createState() => _BioAIV3AppState();
}

class _BioAIV3AppState extends State<BioAIV3App> {
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
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: AppLocalizationConfig.locale,
      supportedLocales: AppLocalizationConfig.supportedLocales,
      localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      builder: AppExperience.builder,
      theme: AppTheme.lightTheme,
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
