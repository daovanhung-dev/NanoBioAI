import 'package:flutter/foundation.dart';

@immutable
class AppRadius {
  const AppRadius._();

  // ============================================================
  // BASE SCALE
  // ============================================================

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double circular = 9999;

  // ============================================================
  // SEMANTIC TOKENS
  // ============================================================

  static const double chip = sm;
  static const double badge = circular;

  static const double button = md;
  static const double buttonLarge = lg;
  static const double buttonSmall = sm;

  static const double card = lg;
  static const double cardLarge = xl;

  static const double input = md;
  static const double inputLarge = lg;

  static const double dialog = lg;
  static const double bottomSheet = xl;
  static const double sheetHandle = circular;

  static const double appBar = 0;
  static const double listTile = md;
  static const double avatar = circular;

  static const double image = lg;
  static const double imageLarge = xl;

  static const double pill = circular;
  static const double fab = circular;

  // ============================================================
  // HELPERS
  // ============================================================

  static double clamp(double value, {double min = 0, double max = circular}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
