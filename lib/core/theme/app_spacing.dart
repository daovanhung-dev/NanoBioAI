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
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
  static const double xxxl = 56;
  static const double xxxxl = 80;

  // ============================================================
  // MICRO SPACING
  // ============================================================

  static const double micro = 2;
  static const double tiny = 4;
  static const double small = 8;
  static const double medium = 16;
  static const double large = 20;
  static const double extraLarge = 20;
  static const double huge = 28;
  static const double massive = 40;

  // ============================================================
  // SEMANTIC SPACING
  // ============================================================

  // Compact-by-default layout values. Keep the base scale unchanged so legacy
  // call sites remain predictable while semantic spacing becomes denser.
  static const double pagePadding = 14;
  static const double pagePaddingLarge = 18;
  static const double sectionSpacing = 18;
  static const double sectionSpacingLarge = 24;

  static const double cardPadding = 14;
  static const double cardPaddingCompact = 10;
  static const double cardPaddingLarge = 18;

  static const double itemSpacing = 8;
  static const double itemSpacingCompact = 4;
  static const double itemSpacingLarge = 12;

  // Explicit compact tokens for feature pages that need maximum density.
  static const double compactPagePadding = 12;
  static const double compactSectionSpacing = 14;
  static const double compactCardPadding = 12;
  static const double compactItemSpacing = 6;
  static const double compactFormSpacing = 10;
  static const double compactListTilePadding = 12;

  static const double iconTextSpacing = xs;
  static const double iconTextSpacingLarge = sm;

  static const double buttonPadding = 12;
  static const double buttonPaddingHorizontal = 16;
  static const double buttonPaddingVertical = 10;

  static const double inputPaddingHorizontal = 14;
  static const double inputPaddingVertical = 12;

  static const double listTilePaddingHorizontal = 14;
  static const double listTilePaddingVertical = 4;

  static const double dialogPadding = 18;
  static const double bottomSheetPadding = 18;
  static const double sheetHandleSpacing = sm;

  static const double chipHorizontalPadding = sm;
  static const double chipVerticalPadding = xs;

  static const double appBarHorizontalPadding = md;
  static const double appBarVerticalPadding = sm;

  static const double screenHorizontalPadding = 14;
  static const double screenVerticalPadding = 14;

  static const double formFieldSpacing = 12;
  static const double formSectionSpacing = 22;

  static const double dividerSpacing = sm;
  static const double overlayInset = md;

  // ============================================================
  // COMPONENT TOKEN SIZES
  // ============================================================

  static const double touchTargetMin = 48;
  static const double buttonMinHeight = 44;
  static const double inputMinHeight = 48;
  static const double iconButtonSize = 48;
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
