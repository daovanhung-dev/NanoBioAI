import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class OnboardingStepShell extends StatefulWidget {
  final int stepIndex;

  final int totalSteps;

  final String title;

  final String subtitle;

  final Widget child;

  final Widget? footer;

  final VoidCallback? onBack;

  final VoidCallback? onNext;

  final String? nextLabel;

  final bool showBack;

  final bool isScrollable;

  final bool showFloatingBackground;

  final bool safeArea;

  final EdgeInsetsGeometry? padding;

  const OnboardingStepShell({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.totalSteps = 7,
    this.footer,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.showBack = true,
    this.isScrollable = true,
    this.showFloatingBackground = true,
    this.safeArea = true,
    this.padding,
  });

  @override
  State<OnboardingStepShell>
      createState() =>
          _OnboardingStepShellState();
}

class _OnboardingStepShellState
    extends State<OnboardingStepShell>
    with TickerProviderStateMixin {
  late final AnimationController
      _backgroundController;

  late final AnimationController
      _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 14),
    )..repeat();

    _floatingController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (widget.stepIndex + 1) /
            widget.totalSteps;

    final content = Stack(
      children: [
        if (widget
            .showFloatingBackground) ...[
          Positioned.fill(
            child: AnimatedBuilder(
              animation:
                  _backgroundController,
              builder:
                  (context, child) {
                return CustomPaint(
                  painter:
                      _ShellBackgroundPainter(
                    animation:
                        _backgroundController
                            .value,
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: -120,
            right: -80,
            child: _FloatingOrb(
              controller:
                  _floatingController,
              size: 260,
              color: AppColors.primary
                  .withOpacity(0.08),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -90,
            child: _FloatingOrb(
              controller:
                  _floatingController,
              size: 320,
              color: AppColors.secondary
                  .withOpacity(0.08),
            ),
          ),
        ],

        Positioned.fill(
          child: Padding(
            padding:
                widget.padding ??
                    const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      20,
                    ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _AnimatedAppear(
                  delay: 0,
                  child: _TopBar(
                    progress: progress,
                    stepIndex:
                        widget.stepIndex,
                    totalSteps:
                        widget.totalSteps,
                    onBack:
                        widget.showBack
                            ? widget.onBack
                            : null,
                  ),
                ),

                if (widget.title
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 28,
                  ),

                  _AnimatedAppear(
                    delay: 100,
                    child: _HeaderSection(
                      title:
                          widget.title,
                      subtitle:
                          widget.subtitle,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Expanded(
                  child:
                      widget.isScrollable
                          ? SingleChildScrollView(
                              physics:
                                  const BouncingScrollPhysics(),
                              child:
                                  _AnimatedAppear(
                                delay: 180,
                                child:
                                    widget.child,
                              ),
                            )
                          : _AnimatedAppear(
                              delay: 180,
                              child:
                                  widget.child,
                            ),
                ),

                if (widget.footer !=
                    null) ...[
                  const SizedBox(
                    height: 20,
                  ),
                  widget.footer!,
                ],

                if (widget.onNext !=
                        null &&
                    widget.footer ==
                        null) ...[
                  const SizedBox(
                    height: 24,
                  ),

                  _AnimatedAppear(
                    delay: 260,
                    child: _ContinueButton(
                      label:
                          widget.nextLabel ??
                              'Tiếp tục',
                      onPressed:
                          widget.onNext!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.safeArea) {
      return SafeArea(
        child: content,
      );
    }

    return content;
  }
}

class _HeaderSection
    extends StatelessWidget {
  final String title;

  final String subtitle;

  const _HeaderSection({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration:
          AppDecoration.glass(
        opacity: 0.82,
        blurRadius: 24,
        radius: AppRadius.xxl,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient:
                      AppGradients.primary,
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.lg,
                  ),
                  boxShadow:
                      AppShadows.primary,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.circular,
                  ),
                  border: Border.all(
                    color: AppColors.primary
                        .withOpacity(
                      0.12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .psychology_alt_rounded,
                      color:
                          AppColors.primary,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'BioAI',
                      style:
                          AppTextStyles
                              .labelMedium
                              .copyWith(
                        color:
                            AppColors
                                .primary,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            title,
            style:
                AppTextStyles
                    .displaySmall
                    .copyWith(
              fontWeight:
                  FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            subtitle,
            style:
                AppTextStyles
                    .bodyLarge
                    .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final double progress;

  final int stepIndex;

  final int totalSteps;

  final VoidCallback? onBack;

  const _TopBar({
    required this.progress,
    required this.stepIndex,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          _GlassIconButton(
            icon:
                Icons.arrow_back_rounded,
            onTap: onBack!,
          )
        else
          const SizedBox(
            width: 54,
          ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  Text(
                    'Bước ${stepIndex + 1}/$totalSteps',
                    style:
                        AppTextStyles
                            .labelLarge
                            .copyWith(
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${(progress * 100).round()}%',
                    style:
                        AppTextStyles
                            .labelLarge
                            .copyWith(
                      color:
                          AppColors
                              .primary,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  999,
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .border
                            .withOpacity(
                              0.35,
                            ),
                      ),
                    ),

                    FractionallySizedBox(
                      widthFactor: progress,
                      child:
                          AnimatedContainer(
                        duration:
                            AppDuration
                                .normal,
                        curve:
                            Curves
                                .easeOutCubic,
                        height: 12,
                        decoration:
                            BoxDecoration(
                          gradient:
                              AppGradients
                                  .primary,
                          boxShadow:
                              AppShadows
                                  .primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueButton
    extends StatefulWidget {
  final String label;

  final VoidCallback onPressed;

  const _ContinueButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_ContinueButton>
      createState() =>
          _ContinueButtonState();
}

class _ContinueButtonState
    extends State<_ContinueButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration:
              AppDuration.normal,
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient:
                AppGradients.primary,
            borderRadius:
                BorderRadius.circular(
              AppRadius.xl,
            ),
            boxShadow:
                _hovered
                    ? [
                      ...AppShadows
                          .primary,
                      BoxShadow(
                        blurRadius: 28,
                        spreadRadius: -8,
                        offset:
                            const Offset(
                          0,
                          16,
                        ),
                        color: AppColors
                            .primary
                            .withOpacity(
                          0.34,
                        ),
                      ),
                    ]
                    : AppShadows.primary,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style:
                    AppTextStyles
                        .labelLarge
                        .copyWith(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(width: 12),

              AnimatedContainer(
                duration:
                    AppDuration.normal,
                transform:
                    Matrix4.translationValues(
                  _hovered ? 4 : 0,
                  0,
                  0,
                ),
                child: const Icon(
                  Icons
                      .arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton
    extends StatefulWidget {
  final IconData icon;

  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GlassIconButton>
      createState() =>
          _GlassIconButtonState();
}

class _GlassIconButtonState
    extends State<_GlassIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:
              AppDuration.normal,
          width: 54,
          height: 54,
          decoration:
              AppDecoration.glass(
            opacity:
                _hovered ? 0.95 : 0.82,
            blurRadius: 18,
            radius: AppRadius.lg,
            borderColor:
                _hovered
                    ? AppColors.primary
                    : AppColors.border
                        .withOpacity(
                          0.35,
                        ),
          ),
          child: Icon(
            widget.icon,
            color:
                AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AnimatedAppear
    extends StatefulWidget {
  final Widget child;

  final int delay;

  const _AnimatedAppear({
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedAppear>
      createState() =>
          _AnimatedAppearState();
}

class _AnimatedAppearState
    extends State<_AnimatedAppear>
    with
        SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  late final Animation<double>
      _opacity;

  late final Animation<Offset>
      _offset;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 700,
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _offset =
        Tween<Offset>(
      begin:
          const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
            Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds:
            widget.delay,
      ),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _FloatingOrb
    extends StatelessWidget {
  final AnimationController
      controller;

  final double size;

  final Color color;

  const _FloatingOrb({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(
                      controller
                              .value *
                          math.pi *
                          2,
                    ) *
                    16,
            math.cos(
                      controller
                              .value *
                          math.pi *
                          2,
                    ) *
                    16,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _ShellBackgroundPainter
    extends CustomPainter {
  final double animation;

  const _ShellBackgroundPainter({
    required this.animation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final rect =
        Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final paint = Paint()
      ..shader =
          LinearGradient(
        begin:
            Alignment.topLeft,
        end:
            Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft
              .withOpacity(0.06),
          Colors.white,
        ],
        transform:
            GradientRotation(
          animation * math.pi,
        ),
      ).createShader(rect);

    canvas.drawRect(
      rect,
      paint,
    );

    final gridPaint =
        Paint()
          ..color = AppColors
              .primary
              .withOpacity(
                0.025,
              )
          ..strokeWidth = 1;

    for (
      double i = 0;
      i < size.width;
      i += 42
    ) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(
          i,
          size.height,
        ),
        gridPaint,
      );
    }

    for (
      double i = 0;
      i < size.height;
      i += 42
    ) {
      canvas.drawLine(
        Offset(0, i),
        Offset(
          size.width,
          i,
        ),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
    _ShellBackgroundPainter
        oldDelegate,
  ) {
    return oldDelegate
            .animation !=
        animation;
  }
}