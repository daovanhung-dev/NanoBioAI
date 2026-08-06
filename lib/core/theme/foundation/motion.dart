import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Canonical primitive values for the Nabi Kinetic Aura motion language.
///
/// Feature code should consume semantic values from [AppDuration],
/// [AppMotionTokens] or the shared motion widgets instead of declaring raw
/// durations and curves.
@immutable
class MotionFoundation {
  const MotionFoundation._();

  // Micro interactions.
  static const Duration instant = Duration.zero;
  static const Duration press = Duration(milliseconds: 90);
  static const Duration xFast = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);

  // Component transitions.
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 360);

  // Spatial and celebration transitions.
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration xSlow = Duration(milliseconds: 680);

  // Repeating ambient effects. These remain intentionally slow and subtle.
  static const Duration shimmer = Duration(milliseconds: 1450);
  static const Duration pulse = Duration(milliseconds: 1700);

  // Curves.
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve emphasizedCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve decelerate = Cubic(0, 0, 0, 1);
  static const Curve accelerate = Cubic(0.3, 0, 1, 1);
  static const Curve easeIn = accelerate;
  static const Curve easeOut = decelerate;
  static const Curve easeInOut = standard;

  // Spatial distances expressed as logical pixels or fractional offsets.
  static const double microDistance = 2;
  static const double componentDistance = 8;
  static const double pageDistanceFraction = 0.028;

  // Tactile scales.
  static const double buttonPressedScale = 0.975;
  static const double cardPressedScale = 0.988;
  static const double chipPressedScale = 0.97;
  static const double incomingPageScale = 0.994;
}
