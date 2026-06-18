import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppTransitions {
  static CustomTransitionPage fadeTransition({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
