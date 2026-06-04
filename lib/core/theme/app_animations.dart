import 'package:flutter/material.dart';

import 'app_duration.dart';

class AppAnimations {
  AppAnimations._();

  // ============================================================
  // CURVES
  // ============================================================

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  static const Curve decelerateCurve = Curves.easeOutCubic;
  static const Curve accelerateCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.fastOutSlowIn;

  // ============================================================
  // BASIC TRANSITIONS
  // ============================================================

  static Widget fade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(opacity: animation, child: child);
  }

  static Widget slide({
    required Widget child,
    required Animation<Offset> animation,
  }) {
    return SlideTransition(position: animation, child: child);
  }

  static Widget scale({
    required Widget child,
    required Animation<double> animation,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: animation,
      alignment: alignment,
      child: child,
    );
  }

  static Widget rotate({
    required Widget child,
    required Animation<double> animation,
  }) {
    return RotationTransition(turns: animation, child: child);
  }

  static Widget size({
    required Widget child,
    required Animation<double> animation,
    Axis axis = Axis.vertical,
  }) {
    return SizeTransition(sizeFactor: animation, axis: axis, child: child);
  }

  // ============================================================
  // COMBINED TRANSITIONS
  // ============================================================

  static Widget fadeScale({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.95,
  }) {
    final scaleAnimation = Tween<double>(
      begin: beginScale,
      end: 1,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: scaleAnimation, child: child),
    );
  }

  static Widget fadeSlide({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(0, 0.08),
  }) {
    final slideAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: smoothCurve));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }

  // ============================================================
  // ANIMATED BUILDERS
  // ============================================================

  static Widget animatedOpacity({
    required Widget child,
    required bool visible,
    Duration duration = AppDuration.normal,
    Curve curve = standardCurve,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  static Widget animatedScale({
    required Widget child,
    required bool active,
    Duration duration = AppDuration.fast,
    Curve curve = standardCurve,
    double inactiveScale = 0.95,
  }) {
    return AnimatedScale(
      scale: active ? 1 : inactiveScale,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  static Widget animatedContainer({
    required Widget child,
    required Duration duration,
    required Decoration decoration,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    Curve curve = standardCurve,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: decoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      child: child,
    );
  }

  // ============================================================
  // SWITCHERS
  // ============================================================

  static Widget switcher({
    required Widget child,
    Duration duration = AppDuration.normal,
    Curve switchInCurve = standardCurve,
    Curve switchOutCurve = standardCurve,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (child, animation) {
        return fadeScale(child: child, animation: animation);
      },
      child: child,
    );
  }

  // ============================================================
  // LIST / STAGGER HELPERS
  // ============================================================

  static Duration stagger(int index, {Duration base = AppDuration.stagger}) {
    return Duration(milliseconds: base.inMilliseconds * index);
  }

  // ============================================================
  // PAGE TRANSITIONS
  // ============================================================

  static Widget pageTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return fadeSlide(
      child: child,
      animation: animation,
      begin: const Offset(0.04, 0),
    );
  }

  static Widget modalTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return fadeScale(child: child, animation: animation, beginScale: 0.92);
  }

  static Widget bottomSheetTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: smoothCurve));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // ============================================================
  // HERO / PREMIUM
  // ============================================================

  static Widget floating({
    required Widget child,
    required Animation<double> animation,
  }) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(animation);

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // ============================================================
  // GENERIC WRAPPER
  // ============================================================

  static Widget transition({
    required Widget child,
    required Widget Function(Widget child) builder,
  }) {
    return builder(child);
  }

  // ============================================================
  // CURVED ANIMATION HELPERS
  // ============================================================

  static Animation<double> curved({
    required Animation<double> parent,
    Curve curve = standardCurve,
  }) {
    return CurvedAnimation(parent: parent, curve: curve);
  }

  static Animation<Offset> slideOffset({
    required Animation<double> parent,
    Offset begin = const Offset(0, 0.08),
    Offset end = Offset.zero,
    Curve curve = smoothCurve,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: parent, curve: curve));
  }

  static Animation<double> scaleTween({
    required Animation<double> parent,
    double begin = 0.95,
    double end = 1,
    Curve curve = smoothCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: parent, curve: curve));
  }
}
