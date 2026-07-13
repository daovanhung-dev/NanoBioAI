import 'package:flutter/material.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_navigation_coordinator.dart';
import 'package:nano_app/l10n/app_localizations.dart';

class BioAIV1App extends StatefulWidget {
  const BioAIV1App({super.key});

  @override
  State<BioAIV1App> createState() => _BioAIV1AppState();
}

class _BioAIV1AppState extends State<BioAIV1App> {
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
