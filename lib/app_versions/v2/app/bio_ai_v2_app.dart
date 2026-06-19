import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v2/router/v2_router.dart';
import 'package:nano_app/core/theme/app_theme.dart';

class BioAIV2App extends StatelessWidget {
  const BioAIV2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BioAI V2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: v2Router,
    );
  }
}
