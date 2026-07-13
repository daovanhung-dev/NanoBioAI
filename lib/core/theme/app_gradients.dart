import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF2C7BEA), Color(0xFF0D4EA6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryReverse = LinearGradient(
    colors: [Color(0xFF0D4EA6), Color(0xFF2C7BEA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoft = LinearGradient(
    colors: [Color(0xFFF6FAFF), Color(0xFFEAF3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [Color(0xFF1769E0), Color(0xFF6750A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumDark = LinearGradient(
    colors: [Color(0xFF173B67), Color(0xFF332761)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceAlt = LinearGradient(
    colors: [Color(0xFFF8FBFD), Color(0xFFF0F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurface = LinearGradient(
    colors: [Color(0xFF173244), Color(0xFF081723)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSurfaceElevated = LinearGradient(
    colors: [Color(0xFF214256), Color(0xFF102433)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF2AA981), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFC68811), Color(0xFF9A6200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFD84A62), Color(0xFFA8243B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient info = LinearGradient(
    colors: [Color(0xFF2D7DB7), Color(0xFF1261A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient health = LinearGradient(
    colors: [Color(0xFF35B995), Color(0xFF16825D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energy = LinearGradient(
    colors: [Color(0xFFE0A126), Color(0xFF9A6200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sleep = LinearGradient(
    colors: [Color(0xFF6D79D8), Color(0xFF4856B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meditation = LinearGradient(
    colors: [Color(0xFF7E71C8), Color(0xFF6750A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ai = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF1769E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient futuristic = LinearGradient(
    colors: [Color(0xFF12304A), Color(0xFF1769E0), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overlayTop = LinearGradient(
    colors: [Color(0xB312304A), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayBottom = LinearGradient(
    colors: [Colors.transparent, Color(0xB312304A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayLeft = LinearGradient(
    colors: [Color(0x9912304A), Colors.transparent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient overlayRight = LinearGradient(
    colors: [Colors.transparent, Color(0x9912304A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFF12304A), Color(0xFF1769E0), Color(0xFF0F766E)],
    stops: [0, 0.58, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dashboard = LinearGradient(
    colors: [Color(0xFF12304A), Color(0xFF174668)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient onboarding = LinearGradient(
    colors: [Color(0xFFF9FCFE), Color(0xFFEAF3FF), Color(0xFFE8F7F5)],
    stops: [0, .55, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient medicalBackground = LinearGradient(
    colors: [Color(0xFFF8FBFD), Color(0xFFF1F7FB), Color(0xFFF7FBFA)],
    stops: [0, .62, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [Color(0xE6FFFFFF), Color(0xBFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassDark = LinearGradient(
    colors: [Color(0xD9173244), Color(0xB3102433)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

  static LinearGradient opacity({
    required Color color,
    double opacityStart = 1,
    double opacityEnd = 0.7,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        color.withValues(alpha: opacityStart),
        color.withValues(alpha: opacityEnd),
      ],
    );
  }

  static LinearGradient adaptive({
    required bool darkMode,
    required LinearGradient light,
    required LinearGradient dark,
  }) {
    return darkMode ? dark : light;
  }
}
