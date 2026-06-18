import 'package:flutter/foundation.dart';

@immutable
class AppDuration {
  const AppDuration._();

  // ============================================================
  // BASE DURATIONS
  // ============================================================

  static const Duration instant = Duration(milliseconds: 0);

  static const Duration xFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration xSlow = Duration(milliseconds: 800);

  // ============================================================
  // MICRO INTERACTIONS
  // ============================================================

  static const Duration tap = Duration(milliseconds: 120);
  static const Duration hover = Duration(milliseconds: 160);
  static const Duration press = Duration(milliseconds: 90);
  static const Duration focus = Duration(milliseconds: 180);
  static const Duration ripple = Duration(milliseconds: 220);

  // ============================================================
  // COMPONENT ANIMATIONS
  // ============================================================

  static const Duration button = Duration(milliseconds: 180);
  static const Duration card = Duration(milliseconds: 240);
  static const Duration input = Duration(milliseconds: 200);
  static const Duration switcher = Duration(milliseconds: 300);
  static const Duration checkbox = Duration(milliseconds: 160);
  static const Duration progress = Duration(milliseconds: 450);

  // ============================================================
  // NAVIGATION / PAGE
  // ============================================================

  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalTransition = Duration(milliseconds: 320);
  static const Duration bottomSheet = Duration(milliseconds: 360);
  static const Duration dialog = Duration(milliseconds: 260);
  static const Duration navigation = Duration(milliseconds: 280);

  // ============================================================
  // FEEDBACK / STATUS
  // ============================================================

  static const Duration snackbar = Duration(milliseconds: 250);
  static const Duration toast = Duration(milliseconds: 220);
  static const Duration tooltip = Duration(milliseconds: 180);

  // ============================================================
  // LOADING / SHIMMER
  // ============================================================

  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Duration loading = Duration(milliseconds: 1000);
  static const Duration skeleton = Duration(milliseconds: 1200);
  static const Duration pulse = Duration(milliseconds: 1500);

  // ============================================================
  // HERO / PREMIUM MOTION
  // ============================================================

  static const Duration hero = Duration(milliseconds: 500);
  static const Duration onboarding = Duration(milliseconds: 700);
  static const Duration stagger = Duration(milliseconds: 80);

  // ============================================================
  // ACCESSIBILITY
  // ============================================================

  /// Slightly slower motion for better readability
  static const Duration readable = Duration(milliseconds: 450);

  /// Reduced motion alternative
  static const Duration reducedMotion = Duration(milliseconds: 120);

  // ============================================================
  // HELPERS
  // ============================================================

  static Duration scale(Duration duration, {double factor = 1}) {
    return Duration(milliseconds: (duration.inMilliseconds * factor).round());
  }

  static Duration adaptive({
    required bool reduceMotion,
    required Duration normal,
    Duration? reduced,
  }) {
    if (reduceMotion) {
      return reduced ?? reducedMotionDuration;
    }

    return normal;
  }

  static const Duration reducedMotionDuration = Duration(milliseconds: 120);

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
