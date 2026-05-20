import 'package:flutter/foundation.dart';

@immutable
class AppSpacing {
  const AppSpacing._();

  // Base scale
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Semantic spacing
  static const double pagePadding = md;
  static const double sectionSpacing = lg;
  static const double cardPadding = md;
  static const double itemSpacing = sm;
  static const double iconTextSpacing = xs;
  static const double buttonPadding = md;

  // Helpers
  static double scale(double value) => value;
}