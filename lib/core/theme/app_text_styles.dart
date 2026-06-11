import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Roboto';

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    Color? color,
    double letterSpacing = 0,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontStyle: fontStyle,
    );
  }

  // ============================================================
  // DISPLAY
  // ============================================================

  static TextStyle get displayLarge => _base(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => _base(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get displaySmall => _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // ============================================================
  // HEADINGS
  // ============================================================

  static TextStyle get heading1 => _base(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading2 => _base(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading3 => _base(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading4 => _base(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading5 => _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ============================================================
  // BODY
  // ============================================================

  static TextStyle get bodyLarge => _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodySmall => _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textHint,
  );

  static TextStyle get bodyEmphasis => _base(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================================
  // LABEL
  // ============================================================

  static TextStyle get labelLarge => _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => _base(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static TextStyle get labelSmall => _base(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.3,
    color: AppColors.textHint,
  );

  static TextStyle get overline => _base(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.8,
    color: AppColors.textHint,
  );

  // ============================================================
  // BUTTON / CTA
  // ============================================================

  static TextStyle get button => _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Colors.white,
  );

  static TextStyle get buttonSmall => _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Colors.white,
  );

  static TextStyle get buttonText => _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.primary,
  );

  // ============================================================
  // SUPPORT / META
  // ============================================================

  static TextStyle get caption => _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textHint,
  );

  static TextStyle get helper => _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static TextStyle get chipLabel => _base(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputLabel => _base(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textSecondary,
  );

  static TextStyle get inputHint => _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textHint,
  );

  static TextStyle get appBarTitle => _base(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get sectionTitle => _base(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get sectionSubtitle => _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // ============================================================
  // DYNAMIC HELPERS
  // ============================================================

  static TextStyle custom({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color = AppColors.textPrimary,
    double height = 1.4,
    double letterSpacing = 0,
    String? fontFamily,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily ?? AppTextStyles.fontFamily,
      fontStyle: fontStyle,
    );
  }

  static TextStyle primary(TextStyle style) =>
      style.copyWith(color: AppColors.textPrimary);

  static TextStyle secondary(TextStyle style) =>
      style.copyWith(color: AppColors.textSecondary);

  static TextStyle muted(TextStyle style) =>
      style.copyWith(color: AppColors.textHint);

  static TextStyle inverse(TextStyle style) =>
      style.copyWith(color: Colors.white);

  static TextStyle success(TextStyle style) =>
      style.copyWith(color: AppColors.success);

  static TextStyle warning(TextStyle style) =>
      style.copyWith(color: AppColors.warning);

  static TextStyle error(TextStyle style) =>
      style.copyWith(color: AppColors.error);

  static TextStyle brand(TextStyle style) =>
      style.copyWith(color: AppColors.primary);
}
