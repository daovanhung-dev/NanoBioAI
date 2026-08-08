import 'package:flutter/material.dart';

import '../foundation/motion.dart';
import '../foundation/radius.dart';
import '../foundation/shadows.dart';

@immutable
class AppRadiusTokens {
  const AppRadiusTokens._();

  static const double button = RadiusFoundation.radius12;
  static const double card = RadiusFoundation.radius20;
  static const double input = RadiusFoundation.radius14;
  static const double chip = RadiusFoundation.radiusFull;
  static const double badge = RadiusFoundation.radiusFull;
  static const double dialog = RadiusFoundation.radius24;
  static const double avatar = RadiusFoundation.radiusFull;
}

@immutable
class AppShadowTokens {
  const AppShadowTokens._();

  static const List<BoxShadow> card = ShadowFoundation.shadowSm;
  static const List<BoxShadow> cardDark = ShadowFoundation.shadowSmDark;
  static const List<BoxShadow> cardElevated = ShadowFoundation.shadowMd;
  static const List<BoxShadow> cardElevatedDark = ShadowFoundation.shadowMdDark;
  static const List<BoxShadow> dialog = ShadowFoundation.shadowLg;
  static const List<BoxShadow> button = ShadowFoundation.shadowSm;
}

@immutable
class AppMotionTokens {
  const AppMotionTokens._();

  static const Duration press = MotionFoundation.press;
  static const Duration button = MotionFoundation.fast;
  static const Duration chip = MotionFoundation.fast;
  static const Duration input = MotionFoundation.fast;
  static const Duration card = MotionFoundation.normal;
  static const Duration state = MotionFoundation.normal;
  static const Duration dialog = MotionFoundation.normal;
  static const Duration page = MotionFoundation.emphasized;
  static const Duration loading = Duration(milliseconds: 1000);
  static const Duration skeleton = Duration(milliseconds: 1250);
  static const Duration shimmer = MotionFoundation.shimmer;
  static const Duration pulse = MotionFoundation.pulse;

  static const Curve defaultCurve = MotionFoundation.standard;
  static const Curve enterCurve = MotionFoundation.decelerate;
  static const Curve exitCurve = MotionFoundation.accelerate;
  static const Curve emphasizedCurve = MotionFoundation.emphasizedCurve;

  static const double buttonPressedScale = MotionFoundation.buttonPressedScale;
  static const double cardPressedScale = MotionFoundation.cardPressedScale;
  static const double chipPressedScale = MotionFoundation.chipPressedScale;
}
