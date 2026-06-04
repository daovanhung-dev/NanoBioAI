import 'package:flutter/foundation.dart';

@immutable
class AppSpacing {
  const AppSpacing._();

  // ============================================================
  // BASE SCALE
  // ============================================================

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
  static const double xxxxl = 96;

  // ============================================================
  // MICRO SPACING
  // ============================================================

  static const double micro = 2;
  static const double tiny = 6;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 20;
  static const double huge = 24;
  static const double massive = 32;

  // ============================================================
  // SEMANTIC SPACING
  // ============================================================

  static const double pagePadding = md;
  static const double pagePaddingLarge = lg;
  static const double sectionSpacing = lg;
  static const double sectionSpacingLarge = xl;

  static const double cardPadding = md;
  static const double cardPaddingCompact = sm;
  static const double cardPaddingLarge = lg;

  static const double itemSpacing = sm;
  static const double itemSpacingCompact = xs;
  static const double itemSpacingLarge = md;

  static const double iconTextSpacing = xs;
  static const double iconTextSpacingLarge = sm;

  static const double buttonPadding = md;
  static const double buttonPaddingHorizontal = lg;
  static const double buttonPaddingVertical = sm;

  static const double inputPaddingHorizontal = md;
  static const double inputPaddingVertical = md;

  static const double listTilePaddingHorizontal = md;
  static const double listTilePaddingVertical = sm;

  static const double dialogPadding = lg;
  static const double bottomSheetPadding = lg;
  static const double sheetHandleSpacing = sm;

  static const double chipHorizontalPadding = sm;
  static const double chipVerticalPadding = xs;

  static const double appBarHorizontalPadding = md;
  static const double appBarVerticalPadding = sm;

  static const double screenHorizontalPadding = md;
  static const double screenVerticalPadding = md;

  static const double formFieldSpacing = md;
  static const double formSectionSpacing = xl;

  static const double dividerSpacing = sm;
  static const double overlayInset = md;

  // ============================================================
  // COMPONENT TOKEN SIZES
  // ============================================================

  static const double touchTargetMin = 48;
  static const double buttonMinHeight = 48;
  static const double inputMinHeight = 56;
  static const double iconButtonSize = 40;
  static const double avatarSizeSmall = 32;
  static const double avatarSizeMedium = 40;
  static const double avatarSizeLarge = 56;

  // ============================================================
  // CONTAINER PADDING PRESETS
  // ============================================================

  static const double containerPaddingSm = 12;
  static const double containerPaddingMd = 16;
  static const double containerPaddingLg = 20;
  static const double containerPaddingXl = 24;

  // ============================================================
  // LAYOUT HELPERS
  // ============================================================

  static double scale(double value) => value;

  static double adaptive(
    double value, {
    required double screenWidth,
    double baseWidth = 375,
    double min = 0.85,
    double max = 1.20,
  }) {
    final factor = (screenWidth / baseWidth).clamp(min, max);
    return value * factor;
  }

  static double responsive(
    double value, {
    required double screenWidth,
    double baseWidth = 375,
  }) {
    return adaptive(value, screenWidth: screenWidth, baseWidth: baseWidth);
  }

  static double spaceBetween({required int count, double itemSize = sm}) {
    if (count <= 1) return 0;
    return (count - 1) * itemSize;
  }
}
