import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppGradients {
  const AppGradients._();

  // =========================
  // Primary Gradients
  // =========================

  static const LinearGradient primary = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryReverse = LinearGradient(
    colors: [
      AppColors.secondary,
      AppColors.primary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // =========================
  // Surface Gradients
  // =========================

  static const LinearGradient darkSurface = LinearGradient(
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF121212),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // =========================
  // Overlay Gradients
  // =========================

  static const LinearGradient overlayTop = LinearGradient(
    colors: [
      Colors.black54,
      Colors.transparent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayBottom = LinearGradient(
    colors: [
      Colors.transparent,
      Colors.black54,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // =========================
  // Helpers
  // =========================

  static LinearGradient custom({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
      stops: stops,
      tileMode: tileMode,
    );
  }
}