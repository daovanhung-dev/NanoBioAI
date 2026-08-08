import 'dart:async';

import 'package:flutter/material.dart';

import '../motion/app_motion_scope.dart';
import 'app_duration.dart';
import 'foundation/motion.dart';

/// Spatial page transition shared by User, Admin, Sale and paid surfaces.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst || AppMotionScope.reduceMotionOf(context)) {
      return child;
    }

    final incoming = CurvedAnimation(
      parent: animation,
      curve: MotionFoundation.decelerate,
      reverseCurve: MotionFoundation.accelerate,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: MotionFoundation.standard,
      reverseCurve: MotionFoundation.standard,
    );
    final distance = AppMotionScope.distance(
      context,
      MotionFoundation.pageDistanceFraction,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.965).animate(outgoing),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.995).animate(outgoing),
        child: FadeTransition(
          opacity: incoming,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(distance, distance * 0.4),
              end: Offset.zero,
            ).animate(incoming),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: MotionFoundation.incomingPageScale,
                end: 1,
              ).animate(incoming),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reveals a view once with the standard Aura fade/slide treatment.
class AppViewMotion extends StatefulWidget {
  const AppViewMotion({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.022),
    this.duration = AppDuration.normal,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  @override
  State<AppViewMotion> createState() => _AppViewMotionState();
}

class _AppViewMotionState extends State<AppViewMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant AppViewMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AppMotionScope.reduceMotionOf(context)) {
      _controller.value = 1;
      return;
    }

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: MotionFoundation.decelerate,
    );
    final distanceFactor = AppMotionScope.of(context).distanceFactor;

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset * distanceFactor,
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Fade-through state change that preserves layout continuity.
class AppStateSwitcher extends StatelessWidget {
  const AppStateSwitcher({
    super.key,
    required this.child,
    this.duration = AppDuration.switcher,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppMotionScope.duration(context, duration);
    return AnimatedSwitcher(
      duration: effectiveDuration,
      reverseDuration: effectiveDuration,
      switchInCurve: MotionFoundation.decelerate,
      switchOutCurve: MotionFoundation.accelerate,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (transitionChild, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MotionFoundation.decelerate,
          reverseCurve: MotionFoundation.accelerate,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: transitionChild,
          ),
        );
      },
      child: child,
    );
  }
}

/// Direction-aware switcher for onboarding steps, dates and tab bodies.
class AppDirectionalSwitcher extends StatefulWidget {
  const AppDirectionalSwitcher({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppDuration.switcher,
  });

  final int index;
  final Widget child;
  final Duration duration;

  @override
  State<AppDirectionalSwitcher> createState() => _AppDirectionalSwitcherState();
}

class _AppDirectionalSwitcherState extends State<AppDirectionalSwitcher> {
  double _direction = 1;

  @override
  void didUpdateWidget(covariant AppDirectionalSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _direction = widget.index >= oldWidget.index ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppMotionScope.duration(context, widget.duration);
    final distance = AppMotionScope.distance(context, 0.035);

    return AnimatedSwitcher(
      duration: effectiveDuration,
      reverseDuration: effectiveDuration,
      switchInCurve: MotionFoundation.decelerate,
      switchOutCurve: MotionFoundation.accelerate,
      transitionBuilder: (transitionChild, animation) {
        final isIncoming = transitionChild.key == widget.child.key;
        final begin = isIncoming
            ? Offset(distance * _direction, 0)
            : Offset(-distance * _direction, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: transitionChild,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Adds compact tactile scale feedback without owning the tap action.
class AppPressScale extends StatefulWidget {
  const AppPressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = MotionFoundation.buttonPressedScale,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<AppPressScale> createState() => _AppPressScaleState();
}

class _AppPressScaleState extends State<AppPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotionScope.reduceMotionOf(context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
        duration: AppMotionScope.duration(context, AppDuration.press),
        curve: MotionFoundation.decelerate,
        child: widget.child,
      ),
    );
  }
}
