import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v3/router/v3_router.dart';
import 'package:nano_app/core/theme/app_theme.dart';

class BioAIV3App extends StatelessWidget {
  const BioAIV3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BioAI V3',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: v3Router,
    );
  }
}
