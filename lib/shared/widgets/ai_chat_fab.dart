import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/constants/routes/route_names.dart';

class AIChatFAB extends StatefulWidget {
  const AIChatFAB({super.key});

  @override
  State<AIChatFAB> createState() => _AIChatFABState();
}

class _AIChatFABState extends State<AIChatFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _glowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: AppDuration.slow);

    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _glowAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Entrance animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });

    // Pulse animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _controller.status == AnimationStatus.completed) {
            _controller.repeat(reverse: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();

    setState(() {
      _isPressed = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });

        context.push(RoutePaths.aiChat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * (_isPressed ? 0.9 : 1.0),
          child: GestureDetector(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
            },
            onTap: _onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.ai,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(
                      0.3 * _glowAnimation.value,
                    ),
                    blurRadius: 24 * _glowAnimation.value,
                    spreadRadius: 4 * _glowAnimation.value,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(
                      0.2 * _glowAnimation.value,
                    ),
                    blurRadius: 16 * _glowAnimation.value,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating outer ring
                  Transform.rotate(
                    angle: _rotationAnimation.value * math.pi * 2,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Icon
                  Transform.rotate(
                    angle: _rotationAnimation.value * math.pi * 0.2,
                    child: Icon(AppIcons.aiChat, color: Colors.white, size: 28),
                  ),

                  // Pulse indicator
                  if (_controller.status == AnimationStatus.forward ||
                      _controller.status == AnimationStatus.reverse)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 8 * _glowAnimation.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
