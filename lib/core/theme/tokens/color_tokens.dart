import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../foundation/colors.dart';

/// Layer-2 semantic color mapping for NaBi Blue Wellness.
@immutable
class AppColorTokens {
  const AppColorTokens._();

  static const primary = ColorFoundation.bluePrimary;
  static const primaryHover = ColorFoundation.blueDeep;
  static const primaryLight = ColorFoundation.blueSoft;
  static const secondary = ColorFoundation.sky500;
  static const tertiary = ColorFoundation.purple500;

  static const success = ColorFoundation.green500;
  static const successLight = ColorFoundation.successSoft;
  static const warning = ColorFoundation.amber600;
  static const warningLight = ColorFoundation.amberSoft;
  static const error = ColorFoundation.red500;
  static const errorLight = ColorFoundation.redSoft;
  static const info = ColorFoundation.sky600;
  static const infoLight = ColorFoundation.skySoft;

  static const background = ColorFoundation.slate50;
  static const surface = ColorFoundation.white;
  static const surfaceElevated = ColorFoundation.white;
  static const textPrimary = ColorFoundation.slate900;
  static const textSecondary = ColorFoundation.slate600;
  static const textMuted = ColorFoundation.slate500;
  static const textInverse = ColorFoundation.white;
  static const border = ColorFoundation.slate200;
  static const borderStrong = ColorFoundation.slate300;

  static const darkBackground = Color(0xFF07172B);
  static const darkSurface = Color(0xFF0D223D);
  static const darkSurfaceElevated = Color(0xFF123052);
  static const darkTextPrimary = Color(0xFFF4F8FF);
  static const darkTextSecondary = Color(0xFFC7D4E5);
  static const darkTextMuted = Color(0xFF91A4BC);
  static const darkBorder = Color(0xFF315678);
  static const darkBorderStrong = Color(0xFF4D7193);
}
