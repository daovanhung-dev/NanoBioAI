import 'package:flutter/foundation.dart';

import '../app_colors.dart';

/// Legacy layer-2 static mapping for NaBi Green Wellness.
@immutable
class AppColorTokens {
  const AppColorTokens._();

  static const primary = AppColors.primary;
  static const primaryHover = AppColors.primaryDark;
  static const primaryLight = AppColors.primarySoft;
  static const secondary = AppColors.secondary;
  static const tertiary = AppColors.tertiary;

  static const success = AppColors.success;
  static const successLight = AppColors.successSoft;
  static const warning = AppColors.warning;
  static const warningLight = AppColors.warningSoft;
  static const error = AppColors.error;
  static const errorLight = AppColors.errorSoft;
  static const info = AppColors.info;
  static const infoLight = AppColors.infoSoft;

  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const surfaceElevated = AppColors.surfaceElevated;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textMuted = AppColors.textMuted;
  static const textInverse = AppColors.textInverse;
  static const border = AppColors.border;
  static const borderStrong = AppColors.outline;

  static const darkBackground = AppColors.darkBackground;
  static const darkSurface = AppColors.darkSurface;
  static const darkSurfaceElevated = AppColors.darkSurfaceElevated;
  static const darkTextPrimary = AppColors.darkTextPrimary;
  static const darkTextSecondary = AppColors.darkTextSecondary;
  static const darkTextMuted = AppColors.darkTextMuted;
  static const darkBorder = AppColors.darkBorderLight;
  static const darkBorderStrong = AppColors.darkOutline;
}
