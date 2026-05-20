import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppDecoration {
  AppDecoration._();

  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.primaryShadow,
  );
}
