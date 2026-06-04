import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class OnboardingChip extends StatefulWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  final bool enabled;
  final double? width;
  final double? height;

  final Gradient? selectedGradient;
  final Color? selectedColor;

  final EdgeInsetsGeometry? padding;

  final Widget? trailing;
  final IconData? icon;
  final String? description;

  const OnboardingChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.width,
    this.height,
    this.selectedGradient,
    this.selectedColor,
    this.padding,
    this.trailing,
    this.icon,
    this.description,
  });

  @override
  State<OnboardingChip> createState() => _OnboardingChipState();
}

class _OnboardingChipState extends State<OnboardingChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _hovered = false;
  bool _pressed = false;

  bool get _selected => widget.selected;

  Gradient get _activeGradient =>
      widget.selectedGradient ?? AppGradients.primary;

  Color get _activeColor =>
      widget.selectedColor ?? AppColors.primary;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.button,
      lowerBound: 0.965,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animatePress(bool pressed) {
    if (!widget.enabled) return;

    setState(() {
      _pressed = pressed;
    });

    if (pressed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        widget.description != null &&
        widget.description!.trim().isNotEmpty;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: (_) => _animatePress(true),
        onTapUp: (_) => _animatePress(false),
        onTapCancel: () => _animatePress(false),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.scale(
              scale: _controller.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: AppDuration.normal,
            curve: AppAnimations.smoothCurve,
            width: widget.width,
            height: widget.height,
            padding:
                widget.padding ??
                const EdgeInsets.all(
                  AppSpacing.cardPadding,
                ),
            decoration: _buildDecoration(),
            child: AnimatedOpacity(
              duration: AppDuration.fast,
              opacity: widget.enabled ? 1 : 0.45,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeadingSection(
                    emoji: widget.emoji,
                    selected: _selected,
                    gradient: _activeGradient,
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (widget.icon != null) ...[
                              AnimatedContainer(
                                duration: AppDuration.fast,
                                width: 28,
                                height: 28,
                                decoration: AppDecoration.circle(
                                  color: _selected
                                      ? Colors.white.withOpacity(
                                          0.14,
                                        )
                                      : AppColors.primarySoft,
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 16,
                                  color: _selected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),

                              const SizedBox(
                                width: AppSpacing.sm,
                              ),
                            ],

                            Expanded(
                              child:
                                  AnimatedDefaultTextStyle(
                                duration:
                                    AppDuration.normal,
                                curve:
                                    AppAnimations.smoothCurve,
                                style:
                                    AppTextStyles.heading5
                                        .copyWith(
                                  color: _selected
                                      ? Colors.white
                                      : AppColors
                                          .textPrimary,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                                child: Text(
                                  widget.label,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            if (widget.trailing != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                ),
                                child: widget.trailing!,
                              ),

                            const SizedBox(
                              width: AppSpacing.sm,
                            ),

                            _SelectionIndicator(
                              visible: _selected,
                            ),
                          ],
                        ),

                        if (hasDescription) ...[
                          const SizedBox(
                            height: AppSpacing.sm,
                          ),

                          AnimatedDefaultTextStyle(
                            duration:
                                AppDuration.normal,
                            curve:
                                AppAnimations.smoothCurve,
                            style:
                                AppTextStyles.bodySmall
                                    .copyWith(
                              color: _selected
                                  ? Colors.white
                                      .withOpacity(0.82)
                                  : AppColors
                                      .textSecondary,
                              fontWeight:
                                  FontWeight.w500,
                              height: 1.45,
                            ),
                            child: Text(
                              widget.description!,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
        gradient: _activeGradient,
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        shadows: [
          ...AppShadows.primary,
          BoxShadow(
            color: _activeColor.withOpacity(
              _pressed ? 0.18 : 0.30,
            ),
            blurRadius: _hovered ? 34 : 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      );
    }

    return AppDecoration.card(
      color: Colors.white,
      radius: AppRadius.xl,
      border: Border.all(
        color: _hovered
            ? AppColors.primary.withOpacity(0.32)
            : AppColors.border.withOpacity(0.7),
        width: _hovered ? 1.4 : 1,
      ),
      shadows: _hovered
          ? AppShadows.soft
          : AppShadows.card,
    );
  }
}

class _LeadingSection extends StatelessWidget {
  final String emoji;
  final bool selected;
  final Gradient gradient;

  const _LeadingSection({
    required this.emoji,
    required this.selected,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      curve: AppAnimations.smoothCurve,
      width: 62,
      height: 62,
      decoration: AppDecoration.base(
        gradient: selected
            ? AppGradients.glass
            : AppGradients.primarySoft,
        borderRadius: BorderRadius.circular(
          AppRadius.lg,
        ),
        border: Border.all(
          color: selected
              ? Colors.white.withOpacity(0.12)
              : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Center(
        child: AnimatedScale(
          duration: AppDuration.normal,
          curve: AppAnimations.bounceCurve,
          scale: selected ? 1.12 : 1,
          child: Text(
            emoji,
            style: AppTextStyles.displaySmall.copyWith(
              fontSize: 28,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool visible;

  const _SelectionIndicator({
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDuration.normal,
      switchInCurve: AppAnimations.smoothCurve,
      switchOutCurve: AppAnimations.accelerateCurve,
      child: visible
          ? ClipRRect(
              key: const ValueKey('selected'),
              borderRadius: BorderRadius.circular(
                AppRadius.circular,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12,
                  sigmaY: 12,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: AppDecoration.circle(
                    color: Colors.white.withOpacity(
                      0.14,
                    ),
                    shadows: AppShadows.glass,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: AppDecoration.circle(
                      color: Colors.white,
                    ),
                    child: const Icon(
                      AppIcons.checkIn,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(
              key: ValueKey('unselected'),
              width: 30,
              height: 30,
            ),
    );
  }
}