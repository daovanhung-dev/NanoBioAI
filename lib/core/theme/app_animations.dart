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
}
