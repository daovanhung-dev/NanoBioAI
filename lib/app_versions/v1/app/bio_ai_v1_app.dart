import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';

class BioAIV1App extends StatelessWidget {
  const BioAIV1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BioAI',
      debugShowCheckedModeBanner: false,
      builder: AppExperience.builder,

      theme: AppTheme.lightTheme,

      routerConfig: v1Router,
    );
  }
}
