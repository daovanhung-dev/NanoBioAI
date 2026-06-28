import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/admin/router/admin_router.dart';
import 'package:nano_app/core/theme/theme.dart';

class BioAIAdminApp extends StatelessWidget {
  const BioAIAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NanoBio Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: adminRouter,
    );
  }
}
