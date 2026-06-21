import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

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
  final bool safeArea;

  const OnboardingStepShell({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.totalSteps = OnboardingCatalog.totalSteps,
    this.footer,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.showBack = true,
    this.isScrollable = true,
    this.safeArea = true,
  });

  @override
  State<OnboardingStepShell> createState() => _OnboardingStepShellState();
}

class _OnboardingStepShellState extends State<OnboardingStepShell>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
    final progress = (widget.stepIndex + 1) / widget.totalSteps;
    final hasHero =
        widget.title.trim().isNotEmpty || widget.subtitle.trim().isNotEmpty;

    final body = Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (_, __) {
              return CustomPaint(
                painter: _BackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -100,
          right: -60,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 260,
            gradient: AppGradients.primary,
          ),
        ),

        Positioned(
          bottom: -140,
          left: -90,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 320,
            gradient: AppGradients.ai,
            reverse: true,
          ),
        ),

        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.large,
            ),
            child: Column(
              children: [
                _FadeSlideIn(
                  delay: 0,
                  child: _TopBar(
                    progress: progress,
                    stepIndex: widget.stepIndex,
                    totalSteps: widget.totalSteps,
                    showBack: widget.showBack,
                    onBack: widget.onBack,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Expanded(
                  child: widget.isScrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              if (hasHero) ...[
                                _FadeSlideIn(
                                  delay: 80,
                                  child: _HeroHeader(
                                    title: widget.title,
                                    subtitle: widget.subtitle,
                                    progress: progress,
                                  ),
                                ),

                                const SizedBox(
                                  height: AppSpacing.sectionSpacingLarge,
                                ),
                              ],

                              _FadeSlideIn(delay: 160, child: widget.child),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (hasHero) ...[
                              _FadeSlideIn(
                                delay: 80,
                                child: _HeroHeader(
                                  title: widget.title,
                                  subtitle: widget.subtitle,
                                  progress: progress,
                                ),
                              ),

                              const SizedBox(
                                height: AppSpacing.sectionSpacingLarge,
                              ),
                            ],

                            Expanded(
                              child: _FadeSlideIn(
                                delay: 160,
                                child: widget.child,
                              ),
                            ),
                          ],
                        ),
                ),

                if (widget.footer != null) ...[
                  const SizedBox(height: AppSpacing.large),
                  widget.footer!,
                ],

                if (widget.onNext != null && widget.footer == null) ...[
                  const SizedBox(height: AppSpacing.large),

                  _FadeSlideIn(
                    delay: 240,
                    child: _PrimaryButton(
                      label: widget.nextLabel ?? 'Tiếp tục',
                      onPressed: widget.onNext!,
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
      return SafeArea(child: body);
    }

    return body;
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
          decoration: BoxDecoration(
            gradient: AppGradients.glass,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: AppShadows.floating,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: AppDecoration.primaryGradient(
                      radius: AppRadius.xl,
                    ),
                    child: const Icon(
                      AppIcons.health,
                      size: 34,
                      color: AppColors.textWhite,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: AppDecoration.glass(
                      radius: AppRadius.circular,
                      opacity: 0.18,
                      borderColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          AppIcons.chat,
                          color: AppColors.primary,
                          size: 18,
                        ),

                        const SizedBox(width: AppSpacing.iconTextSpacing),

                        Text(
                          'BioAI',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                title,
                style: AppTextStyles.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                subtitle,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppDecoration.glass(
                  radius: AppRadius.circular,
                  opacity: 0.12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: AppDecoration.primaryGradient(
                        radius: AppRadius.circular,
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final double progress;
  final int stepIndex;
  final int totalSteps;
  final bool showBack;
  final VoidCallback? onBack;

  const _TopBar({
    required this.progress,
    required this.stepIndex,
    required this.totalSteps,
    required this.showBack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          _GlassButton(icon: AppIcons.back, onTap: onBack)
        else
          const SizedBox(width: AppSpacing.touchTargetMin),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Bước ${stepIndex + 1}/$totalSteps',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    'Hồ sơ sức khỏe',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: AppDecoration.primaryGradient(
                      radius: AppRadius.circular,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDuration.button,
          curve: AppAnimations.smoothCurve,
          width: double.infinity,
          height: 52,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration:
              AppDecoration.primaryGradient(
                radius: AppRadius.buttonLarge,
              ).copyWith(
                boxShadow: _hovered
                    ? [
                        ...AppShadows.primary,
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 32,
                          spreadRadius: -6,
                          offset: const Offset(0, 18),
                        ),
                      ]
                    : AppShadows.primary,
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              AnimatedContainer(
                duration: AppDuration.fast,
                transform: Matrix4.translationValues(_hovered ? 5 : 0, 0, 0),
                child: const Icon(
                  AppIcons.forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          curve: AppAnimations.smoothCurve,
          width: 46,
          height: 46,
          decoration: AppDecoration.glass(
            radius: AppRadius.lg,
            opacity: _hovered ? 0.18 : 0.1,
            borderColor: _hovered ? AppColors.primary : AppColors.border,
          ),
          child: Icon(widget.icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlideIn({required this.child, required this.delay});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.onboarding,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.decelerateCurve,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAnimations.fadeSlide(child: widget.child, animation: _animation);
  }
}

class _FloatingOrb extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Gradient gradient;
  final bool reverse;

  const _FloatingOrb({
    required this.controller,
    required this.size,
    required this.gradient,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final value = controller.value;

        return Transform.translate(
          offset: Offset(
            math.sin(value * math.pi * 2) * (reverse ? -18 : 18),
            math.cos(value * math.pi * 2) * 16,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animation;

  const _BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        transform: GradientRotation(animation * math.pi),
        colors: [AppColors.background, AppColors.primarySoft, Colors.white],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
