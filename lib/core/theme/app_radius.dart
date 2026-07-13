import 'package:flutter/foundation.dart';

@immutable
class AppRadius {
  const AppRadius._();

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double xxxl = 38;
  static const double circular = 9999;

  static const double chip = circular;
  static const double badge = circular;
  static const double button = md;
  static const double buttonLarge = lg;
  static const double buttonSmall = sm;
  static const double card = lg;
  static const double cardLarge = xl;
  static const double input = lg;
  static const double inputLarge = xl;
  static const double dialog = xl;
  static const double bottomSheet = xxl;
  static const double sheetHandle = circular;
  static const double appBar = 0;
  static const double listTile = md;
  static const double avatar = circular;
  static const double image = lg;
  static const double imageLarge = xl;
  static const double pill = circular;
  static const double fab = circular;

  static double clamp(double value, {double min = 0, double max = circular}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
