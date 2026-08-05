import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Visual foundation for the NaBi Green Wellness onboarding experience.
class NabiPalette {
  const NabiPalette._();

  static const Color greenPrimary = AppColors.primary;
  static const Color greenDeep = AppColors.primaryDark;
  static const Color greenBright = AppColors.primaryLight;
  static const Color greenSoft = AppColors.primarySoft;
  static const Color mintSurface = AppColors.primarySubtle;
  static const Color pageBackground = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color ink = AppColors.textPrimary;
  static const Color mutedInk = AppColors.textSecondary;
  static const Color subtleInk = AppColors.textMuted;
  static const Color line = AppColors.border;
  static const Color focusRing = AppColors.primaryLight;

  static const Color energyYellow = AppColors.energyYellow;
  static const Color calmBlue = AppColors.secondary;
  static const Color careCoral = AppColors.careCoral;
  static const Color personalPurple = AppColors.tertiary;

  static const Color success = AppColors.success;
  static const Color successSoft = AppColors.successSoft;
  static const Color warning = AppColors.warning;
  static const Color warningSoft = AppColors.warningSoft;
  static const Color error = AppColors.error;
  static const Color errorSoft = AppColors.errorSoft;
  static const Color info = AppColors.secondaryDark;
  static const Color infoSoft = AppColors.secondarySoft;

  // Compatibility aliases for the existing presentation package.
  static const Color deepBlue = greenDeep;
  static const Color royalBlue = greenPrimary;
  static const Color skyBlue = calmBlue;
  static const Color cyan = greenBright;
  static const Color violet = personalPurple;
  static const Color amber = energyYellow;
  static const Color rose = careCoral;
  static const Color canvas = pageBackground;
  static const Color canvasDeep = mintSurface;

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDeep, greenPrimary, AppColors.primaryLight],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.success, AppColors.primaryLight],
  );

  static const LinearGradient selection = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDeep, greenPrimary],
  );

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surface, AppColors.inputBackground],
  );

  static const LinearGradient softBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintSurface, AppColors.cardAlt],
  );

  static const LinearGradient mintWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.cardAlt, mintSurface, pageBackground],
    stops: [0, 0.48, 1],
  );
}

enum NabiOnboardingMood {
  welcome,
  guide,
  goal,
  care,
  lifestyle,
  thinking,
  routine,
  consent,
  review,
  celebrate,
}

extension NabiOnboardingMoodVisual on NabiOnboardingMood {
  String get assetPath => switch (this) {
        NabiOnboardingMood.welcome =>
          'assets/images/nabi/onboarding/nabi_onboarding_intro.png',
        NabiOnboardingMood.guide =>
          'assets/images/nabi/onboarding/nabi_onboarding_basic_info.png',
        NabiOnboardingMood.goal =>
          'assets/images/nabi/onboarding/nabi_onboarding_goal.png',
        NabiOnboardingMood.care =>
          'assets/images/nabi/onboarding/nabi_onboarding_health_check.png',
        NabiOnboardingMood.lifestyle =>
          'assets/images/nabi/onboarding/nabi_onboarding_lifestyle.png',
        NabiOnboardingMood.thinking =>
          'assets/images/nabi/core/nabi_think.png',
        NabiOnboardingMood.routine =>
          'assets/images/nabi/daily/nabi_view_schedule.png',
        NabiOnboardingMood.consent =>
          'assets/images/nabi/core/nabi_idle_happy.png',
        NabiOnboardingMood.review =>
          'assets/images/nabi/onboarding/nabi_onboarding_review.png',
        NabiOnboardingMood.celebrate =>
          'assets/images/nabi/onboarding/nabi_plan_ready.png',
      };

  String get message => switch (this) {
        NabiOnboardingMood.welcome => 'Bắt đầu nhé?',
        NabiOnboardingMood.guide => 'Mình ghi lại nhé',
        NabiOnboardingMood.goal => 'Chọn điều quan trọng',
        NabiOnboardingMood.care => 'Mình đang lắng nghe',
        NabiOnboardingMood.lifestyle => 'Nhịp sống của bạn',
        NabiOnboardingMood.thinking => 'Chọn những gì đúng',
        NabiOnboardingMood.routine => 'Sắp xếp một ngày',
        NabiOnboardingMood.consent => 'Bạn luôn có quyền chọn',
        NabiOnboardingMood.review => 'Xem lại lần cuối',
        NabiOnboardingMood.celebrate => 'Lộ trình đã sẵn sàng',
      };

  Color get accent => switch (this) {
        NabiOnboardingMood.goal => NabiPalette.energyYellow,
        NabiOnboardingMood.care => NabiPalette.careCoral,
        NabiOnboardingMood.lifestyle => NabiPalette.calmBlue,
        NabiOnboardingMood.thinking => NabiPalette.personalPurple,
        NabiOnboardingMood.routine => NabiPalette.energyYellow,
        _ => NabiPalette.greenBright,
      };
}

bool nabiReducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Mint atmosphere with slow ambient drift. It automatically becomes static
/// when the platform requests reduced motion.
class NabiAmbientBackground extends StatefulWidget {
  final Widget child;
  final bool strong;

  const NabiAmbientBackground({
    super.key,
    required this.child,
    this.strong = false,
  });

  @override
  State<NabiAmbientBackground> createState() => _NabiAmbientBackgroundState();
}

class _NabiAmbientBackgroundState extends State<NabiAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nabiReducedMotion(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: NabiPalette.mintWash),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _WellnessAtmospherePainter(
                progress: _controller.value,
                strong: widget.strong,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _WellnessAtmospherePainter extends CustomPainter {
  final double progress;
  final bool strong;

  const _WellnessAtmospherePainter({
    required this.progress,
    required this.strong,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(progress * math.pi * 2) * 7;
    final green = Paint()
      ..color = NabiPalette.greenBright.withValues(alpha: strong ? 0.14 : 0.08);
    final yellow = Paint()
      ..color = NabiPalette.energyYellow.withValues(alpha: strong ? 0.11 : 0.06);
    final blue = Paint()
      ..color = NabiPalette.calmBlue.withValues(alpha: strong ? 0.09 : 0.045);

    canvas.drawCircle(Offset(size.width * 0.88 + drift, 90), 92, green);
    canvas.drawCircle(
      Offset(size.width * 0.08 - drift * 0.7, size.height * 0.42),
      64,
      yellow,
    );
    canvas.drawCircle(
      Offset(size.width * 0.83 - drift, size.height * 0.78),
      78,
      blue,
    );

    final dot = Paint()
      ..color = NabiPalette.greenPrimary.withValues(alpha: 0.055);
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 4; column++) {
        canvas.drawCircle(
          Offset(22 + column * 16, size.height - 92 + row * 14),
          1.8,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WellnessAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strong != strong;
}

class NabiGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final bool elevated;
  final Color? borderColor;
  final Color? shadowColor;

  const NabiGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.gradient,
    this.elevated = true,
    this.borderColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? NabiPalette.card,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? NabiPalette.line),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: (shadowColor ?? NabiPalette.greenDeep)
                      .withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}

class NabiMoodPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const NabiMoodPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? NabiPalette.greenPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: AppSpacing.tiny),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: NabiPalette.ink,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NabiCompanionAvatar extends StatefulWidget {
  final double size;
  final bool showStatus;
  final NabiOnboardingMood mood;
  final String? statusLabel;
  final bool hero;

  const NabiCompanionAvatar({
    super.key,
    this.size = 116,
    this.showStatus = true,
    this.mood = NabiOnboardingMood.welcome,
    this.statusLabel,
    this.hero = false,
  });

  @override
  State<NabiCompanionAvatar> createState() => _NabiCompanionAvatarState();
}

class _NabiCompanionAvatarState extends State<NabiCompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nabiReducedMotion(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.mood.accent;
    return Semantics(
      image: true,
      label: 'NaBi: ${widget.statusLabel ?? widget.mood.message}',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final lift = nabiReducedMotion(context)
              ? 0.0
              : math.sin(_controller.value * math.pi) * -4;
          final scale = nabiReducedMotion(context)
              ? 1.0
              : 1 + math.sin(_controller.value * math.pi) * 0.018;
          return Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: SizedBox(
          width: widget.size * 1.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size * (widget.hero ? 1.15 : 1.05),
                    height: widget.size * (widget.hero ? 1.15 : 1.05),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.28),
                          accent.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: widget.size,
                    height: widget.size,
                    padding: EdgeInsets.all(widget.size * 0.07),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface.withValues(alpha: 0.96),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.22),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: widget.hero ? 34 : 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: nabiReducedMotion(context)
                          ? Duration.zero
                          : AppDuration.bottomSheet,
                      child: Image.asset(
                        widget.mood.assetPath,
                        key: ValueKey(widget.mood),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.favorite_rounded,
                          color: NabiPalette.greenPrimary,
                          size: widget.size * 0.42,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.showStatus) ...[
                const SizedBox(height: AppSpacing.sm),
                NabiMoodPill(
                  icon: Icons.auto_awesome_rounded,
                  label: widget.statusLabel ?? widget.mood.message,
                  color: accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NabiAssistantMessage extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color accent;

  const NabiAssistantMessage({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.waving_hand_rounded,
    this.accent = NabiPalette.greenPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return NabiGlassPanel(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.sm),
      gradient: LinearGradient(
        colors: [
          accent.withValues(alpha: 0.11),
          AppColors.surface.withValues(alpha: 0.92),
        ],
      ),
      borderColor: accent.withValues(alpha: 0.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NabiPalette.mutedInk,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NabiPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isLoading;

  const NabiPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return _NabiPressScale(
      enabled: enabled,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            }
          : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: AnimatedContainer(
          duration: AppDuration.button,
          height: 48,
          decoration: BoxDecoration(
            gradient: enabled
                ? NabiPalette.button
                : const LinearGradient(
                    colors: [AppColors.textDisabled, AppColors.textHint],
                  ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: NabiPalette.greenPrimary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: AppColors.surface,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.buttonSmall.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(icon, color: AppColors.surface, size: 21),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NabiSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const NabiSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return _NabiPressScale(
      enabled: onPressed != null,
      onTap: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: NabiPalette.greenPrimary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: NabiPalette.greenDeep),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.buttonSmall.copyWith(
                  color: NabiPalette.greenDeep,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NabiStepHero extends StatelessWidget {
  final NabiOnboardingMood mood;
  final String? message;
  final Color? accent;
  final bool compact;

  const NabiStepHero({
    super.key,
    required this.mood,
    this.message,
    this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? mood.accent;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.13),
            NabiPalette.mintSurface.withValues(alpha: 0.86),
            AppColors.surface.withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          NabiCompanionAvatar(
            size: compact ? 58 : 72,
            mood: mood,
            showStatus: false,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ?? mood.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading5.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NabiCelebrationBurst extends StatefulWidget {
  final Widget child;

  const NabiCelebrationBurst({super.key, required this.child});

  @override
  State<NabiCelebrationBurst> createState() => _NabiCelebrationBurstState();
}

class _NabiCelebrationBurstState extends State<NabiCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !nabiReducedMotion(context)) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _CelebrationPainter(progress: _controller.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  final double progress;

  const _CelebrationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      NabiPalette.greenBright,
      NabiPalette.energyYellow,
      NabiPalette.careCoral,
      NabiPalette.calmBlue,
      NabiPalette.personalPurple,
    ];
    final eased = Curves.easeOutCubic.transform(progress);
    for (var index = 0; index < 18; index++) {
      final angle = (math.pi * 2 / 18) * index - math.pi / 2;
      final radius = eased * math.min(size.width, size.height) * 0.44;
      final center = Offset(size.width / 2, size.height * 0.31);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final paint = Paint()
        ..color = colors[index % colors.length]
            .withValues(
              alpha: (1 - progress).clamp(0.0, 1.0).toDouble(),
            );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -6, 6, 12),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _NabiPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const _NabiPressScale({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_NabiPressScale> createState() => _NabiPressScaleState();
}

class _NabiPressScaleState extends State<_NabiPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed && !nabiReducedMotion(context) ? 0.975 : 1,
        duration: AppDuration.tap,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
