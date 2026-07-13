import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/admin/router/admin_router.dart';
import 'package:nano_app/core/localization/app_localization_config.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/l10n/app_localizations.dart';

class BioAIAdminApp extends StatelessWidget {
  const BioAIAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).adminAppTitle,
      locale: AppLocalizationConfig.locale,
      supportedLocales: AppLocalizationConfig.supportedLocales,
      localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      builder: AppExperience.builder,
      theme: AppTheme.lightTheme,
      routerConfig: adminRouter,
    );
  }
}
