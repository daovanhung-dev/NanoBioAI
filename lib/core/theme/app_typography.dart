import 'package:flutter/material.dart';

@immutable
class AppTypography {
  const AppTypography._();

  // =========================================================
  // FONT FAMILY
  // =========================================================

  static const String fontFamily = 'Poppins';

  /// Optional fallback fonts
  static const List<String> fallbackFonts = ['Roboto', 'Arial', 'sans-serif'];

  // =========================================================
  // FONT WEIGHTS
  // =========================================================

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // =========================================================
  // LINE HEIGHTS
  // =========================================================

  static const double ultraTight = 1.0;
  static const double tight = 1.15;
  static const double compact = 1.25;
  static const double normal = 1.4;
  static const double relaxed = 1.6;
  static const double loose = 1.8;

  // =========================================================
  // LETTER SPACING
  // =========================================================

  static const double ultraTightSpacing = -1;
  static const double tightSpacing = -0.5;
  static const double normalSpacing = 0;
  static const double mediumSpacing = 0.15;
  static const double wideSpacing = 0.5;
  static const double extraWideSpacing = 1;

  // =========================================================
  // FONT SIZES
  // =========================================================

  static const double displayXL = 48;
  static const double displayLG = 40;
  static const double displayMD = 36;
  static const double displaySM = 32;

  static const double headingXL = 28;
  static const double headingLG = 24;
  static const double headingMD = 20;
  static const double headingSM = 18;

  static const double bodyXL = 18;
  static const double bodyLG = 16;
  static const double bodyMD = 14;
  static const double bodySM = 12;

  static const double labelLG = 14;
  static const double labelMD = 12;
  static const double labelSM = 11;

  static const double caption = 10;

  // =========================================================
  // RESPONSIVE BREAKPOINTS
  // =========================================================

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // =========================================================
  // STYLE GENERATOR
  // =========================================================

  static TextStyle style({
    double fontSize = bodyMD,
    FontWeight fontWeight = regular,
    Color color = Colors.black,
    double height = normal,
    double letterSpacing = normalSpacing,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }

  // =========================================================
  // RESPONSIVE FONT SCALING
  // =========================================================

  static double responsive(BuildContext context, double size) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= tabletBreakpoint) {
      return size * 1.12;
    }

    if (width >= mobileBreakpoint) {
      return size * 1.05;
    }

    return size;
  }

  static double adaptive(
    double size, {
    required double screenWidth,
    double baseWidth = 375,
    double minScale = 0.92,
    double maxScale = 1.18,
  }) {
    final scale = (screenWidth / baseWidth).clamp(minScale, maxScale);

    return size * scale;
  }

  // =========================================================
  // SEMANTIC HELPERS
  // =========================================================

  static TextStyle display({required Color color, double size = displayLG}) {
    return style(
      fontSize: size,
      fontWeight: bold,
      color: color,
      height: compact,
      letterSpacing: tightSpacing,
    );
  }

  static TextStyle heading({required Color color, double size = headingLG}) {
    return style(
      fontSize: size,
      fontWeight: semiBold,
      color: color,
      height: normal,
    );
  }

  static TextStyle body({
    required Color color,
    double size = bodyMD,
    FontWeight fontWeight = regular,
  }) {
    return style(
      fontSize: size,
      fontWeight: fontWeight,
      color: color,
      height: relaxed,
    );
  }

  static TextStyle label({required Color color, double size = labelMD}) {
    return style(
      fontSize: size,
      fontWeight: medium,
      color: color,
      height: compact,
      letterSpacing: mediumSpacing,
    );
  }

  // =========================================================
  // SPECIALIZED HELPERS
  // =========================================================

  static TextStyle button({required Color color, double size = bodyLG}) {
    return style(
      fontSize: size,
      fontWeight: semiBold,
      color: color,
      height: compact,
    );
  }

  static TextStyle input({required Color color, double size = bodyMD}) {
    return style(
      fontSize: size,
      fontWeight: regular,
      color: color,
      height: normal,
    );
  }

  static TextStyle captionStyle({required Color color}) {
    return style(
      fontSize: bodySM,
      fontWeight: regular,
      color: color,
      height: compact,
      letterSpacing: mediumSpacing,
    );
  }

  static TextStyle overline({required Color color}) {
    return style(
      fontSize: caption,
      fontWeight: semiBold,
      color: color,
      height: compact,
      letterSpacing: extraWideSpacing,
    );
  }

  // =========================================================
  // READABILITY HELPERS
  // =========================================================

  static TextStyle elderlyFriendly(TextStyle style) {
    return style.copyWith(height: relaxed, letterSpacing: mediumSpacing);
  }

  static TextStyle readable(TextStyle style) {
    return style.copyWith(height: relaxed);
  }

  // =========================================================
  // UTILITY HELPERS
  // =========================================================

  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  static TextStyle underline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  static TextStyle strike(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }
}
