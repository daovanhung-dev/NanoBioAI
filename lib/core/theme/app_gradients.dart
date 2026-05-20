import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
