import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class HealthChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  final String? emoji;
  final IconData? icon;

  final Gradient? gradient;
  final Color? activeColor;

  final bool enabled;

  final double? width;
  final double? height;

  final EdgeInsetsGeometry? padding;

  final Widget? trailing;
  final Widget? badge;

  const HealthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.gradient,
    this.activeColor,
    this.enabled = true,
    this.width,
    this.height,
    this.padding,
    this.trailing,
    this.badge,
  });

  @override
  State<HealthChip> createState() => _HealthChipState();
}

class _HealthChipState extends State<HealthChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  bool _hovered = false;
  bool _pressed = false;

  bool get _selected => widget.selected;

  bool get _enabled => widget.enabled;

  Gradient get _gradient =>
      widget.gradient ?? (_selected ? AppGradients.ai : AppGradients.surface);

  Color get _activeColor => widget.activeColor ?? AppColors.primary;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: AppDuration.press,
      lowerBound: 0.965,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _animateDown() {
    if (!_enabled) return;

    setState(() {
      _pressed = true;
    });

    _pressController.reverse();
  }

  void _animateUp() {
    if (!_enabled) return;

    setState(() {
      _pressed = false;
    });

    _pressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
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
        onTap: _enabled ? widget.onTap : null,
        onTapDown: (_) => _animateDown(),
        onTapUp: (_) => _animateUp(),
        onTapCancel: _animateUp,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _pressController,
          builder: (_, child) {
            return Transform.scale(scale: _pressController.value, child: child);
          },
          child: AnimatedContainer(
            duration: AppDuration.normal,
            curve: AppAnimations.smoothCurve,
            width: widget.width,
            height: widget.height,
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.cardPadding,
                  vertical: AppSpacing.medium,
                ),
            decoration: _buildDecoration(),
            child: AnimatedOpacity(
              duration: AppDuration.fast,
              opacity: _enabled ? 1 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.emoji != null) ...[
                    _EmojiAvatar(emoji: widget.emoji!, selected: _selected),
                    const SizedBox(width: AppSpacing.medium),
                  ],

                  if (widget.icon != null) ...[
                    _IconAvatar(icon: widget.icon!, selected: _selected),
                    const SizedBox(width: AppSpacing.medium),
                  ],

                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: AppDuration.normal,
                          curve: AppAnimations.smoothCurve,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          child: Text(
                            widget.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        if (_selected) ...[
                          const SizedBox(height: AppSpacing.xs),
                          AnimatedOpacity(
                            duration: AppDuration.normal,
                            opacity: _selected ? 1 : 0,
                            child: Text(
                              'AI optimized',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.82),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (widget.badge != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    widget.badge!,
                  ],

                  if (widget.trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    widget.trailing!,
                  ],

                  const SizedBox(width: AppSpacing.sm),

                  _SelectionIndicator(visible: _selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    if (_selected) {
      return AppDecoration.base(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        shadows: [
          ...AppShadows.primary,
          BoxShadow(
            color: _activeColor.withOpacity(_pressed ? 0.18 : 0.32),
            blurRadius: _hovered ? 34 : 24,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
        ],
      );
    }

    return AppDecoration.base(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(
        color: _hovered ? AppColors.primary.withOpacity(0.3) : AppColors.border,
        width: _hovered ? 1.4 : 1,
      ),
      shadows: _hovered ? AppShadows.soft : AppShadows.card,
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  final String emoji;
  final bool selected;

  const _EmojiAvatar({required this.emoji, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      curve: AppAnimations.smoothCurve,
      width: 54,
      height: 54,
      decoration: selected
          ? AppDecoration.glass(radius: AppRadius.lg, opacity: 0.14)
          : AppDecoration.container(
              color: AppColors.primarySoft,
              radius: AppRadius.lg,
            ),
      child: Center(
        child: AnimatedScale(
          duration: AppDuration.normal,
          scale: selected ? 1.08 : 1,
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _IconAvatar extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _IconAvatar({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      curve: AppAnimations.smoothCurve,
      width: 54,
      height: 54,
      decoration: selected
          ? AppDecoration.glass(radius: AppRadius.lg, opacity: 0.14)
          : AppDecoration.container(
              color: AppColors.primarySoft,
              radius: AppRadius.lg,
            ),
      child: Icon(
        icon,
        size: 24,
        color: selected ? Colors.white : AppColors.primary,
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool visible;

  const _SelectionIndicator({required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppDuration.normal,
      curve: AppAnimations.bounceCurve,
      scale: visible ? 1 : 0,
      child: AnimatedOpacity(
        duration: AppDuration.fast,
        opacity: visible ? 1 : 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 30,
              height: 30,
              decoration: AppDecoration.circle(
                color: Colors.white.withOpacity(0.18),
                shadows: AppShadows.glass,
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: AppDecoration.circle(
                  color: Colors.white.withOpacity(0.1),
                  shadows: const [],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
