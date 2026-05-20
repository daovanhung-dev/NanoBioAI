import 'package:flutter/foundation.dart';

@immutable
class AppDuration {
  const AppDuration._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  static const Duration xFast = Duration(milliseconds: 100);
  static const Duration xSlow = Duration(milliseconds: 800);
}