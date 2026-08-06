import 'package:flutter/widgets.dart';

import 'app_motion_policy.dart';

/// Supplies one motion policy to every NanoBio surface.
class AppMotionScope extends InheritedWidget {
  const AppMotionScope({
    super.key,
    required this.policy,
    required super.child,
  });

  final AppMotionPolicy policy;

  static AppMotionPolicy of(BuildContext context) {
    return maybeOf(context) ?? const AppMotionPolicy();
  }

  static AppMotionPolicy? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppMotionScope>()
        ?.policy;
  }

  static bool reduceMotionOf(BuildContext context) {
    final systemReduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return systemReduced || of(context).reduceMotion;
  }

  static Duration duration(
    BuildContext context,
    Duration normal, {
    Duration reduced = Duration.zero,
  }) {
    return reduceMotionOf(context) ? reduced : normal;
  }

  static double distance(BuildContext context, double normal) {
    if (reduceMotionOf(context)) return 0;
    return normal * of(context).distanceFactor;
  }

  @override
  bool updateShouldNotify(AppMotionScope oldWidget) {
    return oldWidget.policy.reduceMotion != policy.reduceMotion ||
        oldWidget.policy.performanceTier != policy.performanceTier;
  }
}
