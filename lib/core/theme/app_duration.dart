import 'package:flutter/foundation.dart';

import 'foundation/motion.dart';

/// Semantic duration facade kept stable for the whole application.
@immutable
class AppDuration {
  const AppDuration._();

  static const Duration instant = MotionFoundation.instant;
  static const Duration xFast = MotionFoundation.xFast;
  static const Duration fast = MotionFoundation.fast;
  static const Duration normal = MotionFoundation.normal;
  static const Duration emphasized = MotionFoundation.emphasized;
  static const Duration animation = normal;
  static const Duration slow = MotionFoundation.slow;
  static const Duration xSlow = MotionFoundation.xSlow;

  static const Duration tap = MotionFoundation.xFast;
  static const Duration hover = MotionFoundation.fast;
  static const Duration press = MotionFoundation.press;
  static const Duration focus = MotionFoundation.fast;
  static const Duration ripple = MotionFoundation.normal;

  static const Duration button = MotionFoundation.fast;
  static const Duration card = MotionFoundation.normal;
  static const Duration input = MotionFoundation.fast;
  static const Duration switcher = MotionFoundation.normal;
  static const Duration checkbox = MotionFoundation.fast;
  static const Duration progress = MotionFoundation.emphasized;

  static const Duration pageTransition = MotionFoundation.emphasized;
  static const Duration modalTransition = MotionFoundation.emphasized;
  static const Duration bottomSheet = MotionFoundation.emphasized;
  static const Duration dialog = MotionFoundation.normal;
  static const Duration navigation = MotionFoundation.normal;

  static const Duration snackbar = MotionFoundation.normal;
  static const Duration toast = MotionFoundation.fast;
  static const Duration tooltip = MotionFoundation.fast;

  static const Duration shimmer = MotionFoundation.shimmer;
  static const Duration loading = Duration(milliseconds: 1000);
  static const Duration skeleton = Duration(milliseconds: 1250);
  static const Duration pulse = MotionFoundation.pulse;

  static const Duration hero = MotionFoundation.slow;
  static const Duration onboarding = MotionFoundation.slow;
  static const Duration stagger = Duration(milliseconds: 64);

  static const Duration readable = MotionFoundation.emphasized;
  static const Duration reducedMotion = MotionFoundation.xFast;
  static const Duration reducedMotionDuration = reducedMotion;

  static Duration scale(Duration duration, {double factor = 1}) {
    return Duration(milliseconds: (duration.inMilliseconds * factor).round());
  }

  static Duration adaptive({
    required bool reduceMotion,
    required Duration normal,
    Duration? reduced,
  }) {
    return reduceMotion ? (reduced ?? reducedMotionDuration) : normal;
  }

  static Duration clamp(
    Duration duration, {
    Duration min = xFast,
    Duration max = xSlow,
  }) {
    final ms = duration.inMilliseconds.clamp(
      min.inMilliseconds,
      max.inMilliseconds,
    );
    return Duration(milliseconds: ms);
  }
}
