import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class AppTypography {
  const AppTypography._();

  // =========================================================
  // Font Family
  // =========================================================

  static const String fontFamily = 'Poppins';

  // =========================================================
  // Font Weights
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
  // Line Heights
  // =========================================================

  static const double tight = 1.1;
  static const double normal = 1.4;
  static const double relaxed = 1.6;

  // =========================================================
  // Letter Spacing
  // =========================================================

  static const double tightSpacing = -0.5;
  static const double normalSpacing = 0;
  static const double wideSpacing = 0.5;
  static const double extraWideSpacing = 1;

  // =========================================================
  // Helpers
  // =========================================================

  static TextStyle style({
    double fontSize = 14,
    FontWeight fontWeight = regular,
    Color color = Colors.black,
    double height = normal,
    double letterSpacing = normalSpacing,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }
}