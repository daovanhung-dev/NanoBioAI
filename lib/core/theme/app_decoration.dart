import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppDecoration {
  AppDecoration._();

  // =========================
  // CARD DECORATIONS
  // =========================

  static BoxDecoration card({
    Color? color,
    double? radius,
    List<BoxShadow>? shadows,
    Border? border,
    Gradient? gradient,
    DecorationImage? image,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(
        radius ?? AppRadius.lg,
      ),
      boxShadow: shadows ?? AppShadows.glass,
      border: border,
      gradient: gradient,
      image: image,
    );
  }

  // =========================
  // CONTAINER DECORATIONS
  // =========================

  static BoxDecoration container({
    Color? color,
    double? radius,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(
        radius ?? AppRadius.md,
      ),
      border: border,
      boxShadow: shadows,
    );
  }

  // =========================
  // INPUT DECORATIONS
  // =========================

  static BoxDecoration input({
    Color? color,
    double? radius,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(
        radius ?? AppRadius.md,
      ),
      border: Border.all(
        color: borderColor ?? AppColors.border,
        width: borderWidth,
      ),
    );
  }

  // =========================
  // GRADIENT DECORATIONS
  // =========================

  static BoxDecoration gradient({
    required List<Color> colors,
    double? radius,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(
        radius ?? AppRadius.lg,
      ),
      boxShadow: shadows,
    );
  }

  // =========================
  // GLASSMORPHISM
  // =========================

  static BoxDecoration glass({
    double opacity = 0.1,
    double blurRadius = 10,
    double? radius,
    Color borderColor = Colors.white24,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(
        radius ?? AppRadius.lg,
      ),
      border: Border.all(
        color: borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: blurRadius,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // =========================
  // CIRCLE DECORATION
  // =========================

  static BoxDecoration circle({
    Color? color,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      gradient: gradient,
      boxShadow: shadows,
    );
  }

  // =========================
  // BORDER DECORATIONS
  // =========================

  static BoxDecoration outlined({
    Color? color,
    Color? borderColor,
    double? radius,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color ?? Colors.transparent,
      borderRadius: BorderRadius.circular(
        radius ?? AppRadius.md,
      ),
      border: Border.all(
        color: borderColor ?? AppColors.primary,
        width: borderWidth,
      ),
    );
  }

  // =========================
  // COMMON PRESETS
  // =========================

  static final BoxDecoration primaryCard = card();

  static final BoxDecoration elevatedCard = card(
    shadows: AppShadows.glass,
  );

  static final BoxDecoration roundedCard = card(
    radius: AppRadius.xl,
  );

  static final BoxDecoration primaryGradient = gradient(
    colors: [
      AppColors.primary,
      AppColors.primaryDark,
    ],
  );
}