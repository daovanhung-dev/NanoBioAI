import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named gradients for the Nabi Blue Wellness visual language.
///
/// Gradients are reserved for hero, primary CTA, celebration and focused
/// progress. Routine data cards should remain solid surfaces.
@immutable
class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.ctaStart, AppColors.ctaEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryReverse = LinearGradient(
    colors: [AppColors.ctaEnd, AppColors.ctaStart],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoft = LinearGradient(
    colors: [AppColors.surface, AppColors.primarySubtle],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [AppColors.primary, AppColors.tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumDark = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [AppColors.surface, AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceAlt = LinearGradient(
    colors: [AppColors.surface, AppColors.surfaceSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurface = LinearGradient(
    colors: [AppColors.darkSurfaceElevated, AppColors.darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSurfaceElevated = LinearGradient(
    colors: [AppColors.darkCardAlt, AppColors.darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.success, AppColors.wellnessGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFFC857), Color(0xFFB7791F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFFF7D75), Color(0xFFC64A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient info = LinearGradient(
    colors: [Color(0xFF6AC5F0), Color(0xFF247CA8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient health = success;

  static const LinearGradient energy = LinearGradient(
    colors: [Color(0xFFFFD982), Color(0xFFFFC857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sleep = LinearGradient(
    colors: [Color(0xFF9DDCF5), Color(0xFF58B9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meditation = LinearGradient(
    colors: [Color(0xFFBEB6FF), Color(0xFF8B7CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ai = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient futuristic = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overlayTop = LinearGradient(
    colors: [AppColors.overlayGradient, AppColors.overlayTransparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayBottom = LinearGradient(
    colors: [AppColors.overlayTransparent, AppColors.overlayStrong],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayLeft = LinearGradient(
    colors: [AppColors.overlayGradient, AppColors.overlayTransparent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient overlayRight = LinearGradient(
    colors: [AppColors.overlayTransparent, AppColors.overlayGradient],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primary],
    stops: [0, .56, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dashboard = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onboarding = LinearGradient(
    colors: [AppColors.surface, AppColors.primarySubtle],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient medicalBackground = LinearGradient(
    colors: [AppColors.background, AppColors.surface, AppColors.primarySubtle],
    stops: [0, .58, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [Color(0xEFFFFFFF), Color(0xBFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassDark = LinearGradient(
    colors: [AppColors.darkSurfaceElevated, AppColors.darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
