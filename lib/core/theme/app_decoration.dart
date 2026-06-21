import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppDecoration {
  AppDecoration._();

  // ============================================================
  // BASE DECORATION
  // ============================================================

  static BoxDecoration base({
    Color? color,
    Gradient? gradient,
    Border? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? shadows,
    DecorationImage? image,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      border: border,
      borderRadius: shape == BoxShape.circle ? null : borderRadius,
      boxShadow: shadows,
      image: image,
      shape: shape,
    );
  }

  // ============================================================
  // CARD DECORATIONS
  // ============================================================

  static BoxDecoration card({
    Color? color,
    double? radius,
    List<BoxShadow>? shadows,
    Border? border,
    Gradient? gradient,
    DecorationImage? image,
  }) {
    return base(
      color: color ?? AppColors.card,
      gradient: gradient,
      image: image,
      border: border,
      shadows: shadows ?? AppShadows.card,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.card),
    );
  }

  static BoxDecoration elevatedCard({Color? color, double? radius}) {
    return card(color: color, radius: radius, shadows: AppShadows.cardRaised);
  }

  static BoxDecoration premiumCard({Gradient? gradient}) {
    return card(
      gradient: gradient ?? AppGradients.surface,
      shadows: AppShadows.floating,
      radius: AppRadius.xl,
    );
  }

  // ============================================================
  // CONTAINER
  // ============================================================

  static BoxDecoration container({
    Color? color,
    double? radius,
    Border? border,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return base(
      color: color ?? AppColors.surface,
      gradient: gradient,
      border: border,
      shadows: shadows,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  static BoxDecoration input({
    Color? color,
    double? radius,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
  }) {
    return base(
      color: color ?? AppColors.inputBackground,
      shadows: shadows,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.input),
      border: Border.all(
        color: borderColor ?? AppColors.border,
        width: borderWidth,
      ),
    );
  }

  static BoxDecoration focusedInput({Color? color}) {
    return input(
      color: color,
      borderColor: AppColors.primary,
      borderWidth: 1.4,
      shadows: AppShadows.focus,
    );
  }

  static BoxDecoration errorInput() {
    return input(borderColor: AppColors.error);
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  static BoxDecoration button({
    Color? color,
    Gradient? gradient,
    double? radius,
    List<BoxShadow>? shadows,
  }) {
    return base(
      color: gradient == null ? (color ?? AppColors.primary) : null,
      gradient: gradient,
      shadows: shadows ?? AppShadows.button,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.button),
    );
  }

  static BoxDecoration outlinedButton({
    Color borderColor = AppColors.primary,
    Color background = Colors.transparent,
    double borderWidth = 1.2,
  }) {
    return base(
      color: background,
      border: Border.all(color: borderColor, width: borderWidth),
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
  }

  // ============================================================
  // GRADIENTS
  // ============================================================

  static BoxDecoration gradient({
    required List<Color> colors,
    double? radius,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<BoxShadow>? shadows,
  }) {
    return base(
      gradient: LinearGradient(begin: begin, end: end, colors: colors),
      shadows: shadows,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
    );
  }

  static BoxDecoration primaryGradient({double? radius}) {
    return base(
      gradient: AppGradients.primary,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
      shadows: AppShadows.primary,
    );
  }

  static BoxDecoration premiumGradient({double? radius}) {
    return base(
      gradient: AppGradients.premium,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.xl),
      shadows: AppShadows.floating,
    );
  }

  // ============================================================
  // GLASSMORPHISM
  // ============================================================

  static BoxDecoration glass({
    double opacity = 0.08,
    double? radius,
    Color borderColor = const Color(0x33FFFFFF),
    List<BoxShadow>? shadows,
  }) {
    return base(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
      border: Border.all(color: borderColor),
      shadows: shadows ?? AppShadows.glass,
    );
  }

  static BoxDecoration glassDark({double opacity = 0.12, double? radius}) {
    return base(
      color: Colors.black.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
      border: Border.all(color: const Color(0x22FFFFFF)),
      shadows: AppShadows.darkMd,
    );
  }

  // ============================================================
  // MODAL / SHEET
  // ============================================================

  static BoxDecoration dialog({Color? color}) {
    return base(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.dialog),
      shadows: AppShadows.dialog,
    );
  }

  static BoxDecoration bottomSheet({Color? color}) {
    return base(
      color: color ?? AppColors.card,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
      shadows: AppShadows.bottomSheet,
    );
  }

  // ============================================================
  // CIRCLE
  // ============================================================

  static BoxDecoration circle({
    Color? color,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return base(
      color: gradient == null ? color : null,
      gradient: gradient,
      shadows: shadows,
      shape: BoxShape.circle,
    );
  }

  // ============================================================
  // OUTLINED
  // ============================================================

  static BoxDecoration outlined({
    Color? color,
    Color? borderColor,
    double? radius,
    double borderWidth = 1,
  }) {
    return base(
      color: color ?? Colors.transparent,
      borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
      border: Border.all(
        color: borderColor ?? AppColors.primary,
        width: borderWidth,
      ),
    );
  }

  // ============================================================
  // COMMON PRESETS
  // ============================================================

  static final BoxDecoration primaryCard = card();

  static final BoxDecoration roundedCard = card(radius: AppRadius.xl);

  static final BoxDecoration floatingCard = elevatedCard();

  static final BoxDecoration primaryButton = button();

  static final BoxDecoration premiumSurface = premiumCard();

  static final BoxDecoration onboardingHero = premiumGradient();

  // ============================================================
  // HELPERS
  // ============================================================

  static BorderRadius radius(double value) {
    return BorderRadius.circular(value);
  }

  static Border border({Color color = AppColors.border, double width = 1}) {
    return Border.all(color: color, width: width);
  }

  static BoxDecoration adaptive({
    required bool darkMode,
    required BoxDecoration light,
    required BoxDecoration dark,
  }) {
    return darkMode ? dark : light;
  }
}
