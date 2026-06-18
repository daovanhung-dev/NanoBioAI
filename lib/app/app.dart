import 'package:flutter/material.dart';
import 'package:nano_app/core/core.dart';

import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';

class BioAIApp extends StatelessWidget {
  const BioAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BioAI',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      routerConfig: appRouter,
    );
  }
}
