import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class AIChatFAB extends StatefulWidget {
  final double size;
  final bool showStatusDot;
  final String tooltip;
  final VoidCallback? onPressed;

  const AIChatFAB({
    super.key,
    this.size = 64,
    this.showStatusDot = true,
    this.tooltip = 'Nabiở đây khi bạn cần',
    this.onPressed,
  });

  @override
  State<AIChatFAB> createState() => _AIChatFABState();
}

class _AIChatFABState extends State<AIChatFAB> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _breathingController;
  late final AnimationController _orbitController;

  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _entranceScale = Tween<double>(begin: .72, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _entranceOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathingController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _openAiChat() async {
    HapticFeedback.mediumImpact();

    setState(() => _isPressed = true);

    await Future<void>.delayed(const Duration(milliseconds: 90));

    if (!mounted) return;

    setState(() => _isPressed = false);
    final onPressed = widget.onPressed;
    if (onPressed != null) {
      onPressed();
    } else {
      context.push(V1RoutePaths.aiChat);
    }
  }

  void _handleTapDown(TapDownDetails _) {
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapEnd() {
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 450),
        child: Semantics(
          label: 'Mở Nabichat, nơi Nabicó thể lắng nghe và đồng hành cùng bạn.',
          hint: 'Chạm hai lần để bắt đầu trò chuyện.',
          button: true,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _breathingController,
              _orbitController,
            ]),
            builder: (context, _) {
              final breath = _breathingController.value;
              final glow = lerpDouble(.82, 1.12, breath)!;
              final floatY = lerpDouble(0, -2, breath)!;
              final pressedScale = _isPressed ? .92 : 1.0;

              return Opacity(
                opacity: _entranceOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.scale(
                    scale: _entranceScale.value * pressedScale,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _handleTapDown,
                      onTapUp: (_) => _handleTapEnd(),
                      onTapCancel: _handleTapEnd,
                      onTap: _openAiChat,
                      child: _NamiChatBubble(
                        size: widget.size,
                        glow: glow,
                        orbitProgress: _orbitController.value,
                        showStatusDot: widget.showStatusDot,
                        isPressed: _isPressed,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DraggableAIChatButton extends StatefulWidget {
  final double bottomReserve;
  final bool showLabel;
  final bool visible;
  final VoidCallback? onPressed;

  const DraggableAIChatButton({
    super.key,
    this.bottomReserve = 24,
    this.showLabel = true,
    this.visible = true,
    this.onPressed,
  });

  @override
  State<DraggableAIChatButton> createState() => _DraggableAIChatButtonState();
}

class _DraggableAIChatButtonState extends State<DraggableAIChatButton> {
  static const double _buttonWidth = 96;
  static const double _buttonHeight = 94;

  Offset? _offset;

  Offset _defaultOffset(Size size, EdgeInsets padding) {
    return Offset(
      _clamp(
        size.width - _buttonWidth - AppSpacing.md,
        AppSpacing.md,
        size.width - _buttonWidth - AppSpacing.md,
      ),
      _clamp(
        size.height - _buttonHeight - widget.bottomReserve - padding.bottom,
        padding.top + AppSpacing.md,
        size.height - _buttonHeight - widget.bottomReserve,
      ),
    );
  }

  Offset _clampOffset(Offset offset, Size size, EdgeInsets padding) {
    final minX = AppSpacing.md;
    final maxX = size.width - _buttonWidth - AppSpacing.md;
    final minY = padding.top + AppSpacing.md;
    final maxY = size.height - _buttonHeight - widget.bottomReserve;
    return Offset(_clamp(offset.dx, minX, maxX), _clamp(offset.dy, minY, maxY));
  }

  double _clamp(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: AppDuration.fast,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final padding = MediaQuery.paddingOf(context);
            final currentOffset = _offset ?? _defaultOffset(size, padding);

            return Stack(
              children: [
                Positioned(
                  left: currentOffset.dx,
                  top: currentOffset.dy,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (_) => HapticFeedback.selectionClick(),
                    onPanUpdate: (details) {
                      setState(() {
                        _offset = _clampOffset(
                          currentOffset + details.delta,
                          size,
                          padding,
                        );
                      });
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _offset = _defaultOffset(size, padding));
                    },
                    child: SizedBox(
                      width: _buttonWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AIChatFAB(onPressed: widget.onPressed),
                          if (widget.showLabel) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: AppShadows.md,
                              ),
                              child: Text(
                                'Hỏi Nabi',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NamiChatBubble extends StatelessWidget {
  final double size;
  final double glow;
  final double orbitProgress;
  final bool showStatusDot;
  final bool isPressed;

  const _NamiChatBubble({
    required this.size,
    required this.glow,
    required this.orbitProgress,
    required this.showStatusDot,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * .76;
    final iconSize = size * .42;

    return AnimatedContainer(
      duration: AppDuration.fast,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.ai,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22 * glow),
            blurRadius: 28 * glow,
            spreadRadius: 2.5 * glow,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: .16 * glow),
            blurRadius: 18 * glow,
            spreadRadius: 1.5,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NamiOrbitPainter(
                progress: orbitProgress,
                opacity: isPressed ? .95 : .72,
              ),
            ),
          ),

          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.35, -.45),
                radius: .9,
                colors: [
                  Colors.white.withValues(alpha: .32),
                  Colors.white.withValues(alpha: .08),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .22),
                width: 1,
              ),
            ),
          ),

          AnimatedScale(
            scale: isPressed ? .94 : 1,
            duration: AppDuration.fast,
            curve: Curves.easeOutCubic,
            child: Icon(
              AppIcons.aiChat,
              color: Colors.white,
              size: iconSize,
              shadows: [
                Shadow(
                  color: AppColors.primary.withValues(alpha: .35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          if (showStatusDot)
            Positioned(
              top: size * .16,
              right: size * .16,
              child: _NamiStatusDot(glow: glow),
            ),

          Positioned(
            bottom: size * .15,
            child: Container(
              width: size * .22,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamiStatusDot extends StatelessWidget {
  final double glow;

  const _NamiStatusDot({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: .42),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .78),
            blurRadius: 8 * glow,
            spreadRadius: 1.5,
          ),
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: .34),
            blurRadius: 14 * glow,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _NamiOrbitPainter extends CustomPainter {
  final double progress;
  final double opacity;

  const _NamiOrbitPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 2.2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .18 * opacity);

    final sparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(progress * math.pi * 2),
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: .92 * opacity),
          Colors.white.withValues(alpha: .18 * opacity),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, .38, .72, 1],
      ).createShader(rect);

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      rect,
      progress * math.pi * 2,
      math.pi * .9,
      false,
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NamiOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
