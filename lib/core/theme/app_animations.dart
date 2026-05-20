import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  static Widget fade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget slide({
    required Widget child,
    required Animation<Offset> animation,
  }) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  static Widget scale({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  static Widget rotate({
    required Widget child,
    required Animation<double> animation,
  }) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  static Widget transition({
    required Widget child,
    required Widget Function(Widget child) builder,
  }) {
    return builder(child);
  }
}