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

  final Color? selectedColor;

  final bool enabled;

  final double? width;

  final double? height;

  final EdgeInsetsGeometry? padding;

  final Widget? trailing;

  const HealthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.gradient,
    this.selectedColor,
    this.enabled = true,
    this.width,
    this.height,
    this.padding,
    this.trailing,
  });

  @override
  State<HealthChip> createState() =>
      _HealthChipState();
}

class _HealthChipState
    extends State<HealthChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _hovered = false;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.normal,
      lowerBound: 0.96,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(
    TapDownDetails details,
  ) {
    if (!widget.enabled) return;

    setState(() {
      _pressed = true;
    });

    _controller.reverse();
  }

  void _handleTapUp(
    TapUpDetails details,
  ) {
    if (!widget.enabled) return;

    setState(() {
      _pressed = false;
    });

    _controller.forward();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;

    setState(() {
      _pressed = false;
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool selected =
        widget.selected;

    final Gradient activeGradient =
        widget.gradient ??
            AppGradients.primary;

    final Color activeColor =
        widget.selectedColor ??
            AppColors.primary;

    return MouseRegion(
      cursor:
          widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
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
        onTap:
            widget.enabled
                ? widget.onTap
                : null,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _controller.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration:
                AppDuration.normal,
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            padding:
                widget.padding ??
                    const EdgeInsets.symmetric(
                      horizontal:
                          AppSpacing.lg,
                      vertical:
                          AppSpacing.md,
                    ),
            decoration: BoxDecoration(
              gradient:
                  selected
                      ? activeGradient
                      : null,
              color:
                  selected
                      ? null
                      : Colors.white,
              borderRadius:
                  BorderRadius.circular(
                AppRadius.xl,
              ),
              border: Border.all(
                color:
                    selected
                        ? Colors.transparent
                        : _hovered
                        ? AppColors.primary
                        : AppColors.border
                            .withOpacity(
                              0.6,
                            ),
                width: 1.4,
              ),
              boxShadow:
                  selected
                      ? [
                        ...AppShadows
                            .primary,
                        BoxShadow(
                          blurRadius:
                              24,
                          spreadRadius:
                              -6,
                          offset:
                              const Offset(
                                0,
                                10,
                              ),
                          color: activeColor
                              .withOpacity(
                                0.32,
                              ),
                        ),
                      ]
                      : [
                        BoxShadow(
                          blurRadius:
                              _hovered
                                  ? 20
                                  : 14,
                          spreadRadius:
                              -6,
                          offset:
                              const Offset(
                                0,
                                10,
                              ),
                          color: Colors
                              .black
                              .withOpacity(
                                _hovered
                                    ? 0.08
                                    : 0.04,
                              ),
                        ),
                      ],
            ),
            child: AnimatedOpacity(
              duration:
                  AppDuration.fast,
              opacity:
                  widget.enabled
                      ? 1
                      : 0.5,
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  if (widget.emoji !=
                      null) ...[
                    _EmojiContainer(
                      emoji:
                          widget.emoji!,
                      selected:
                          selected,
                    ),
                    const SizedBox(
                      width:
                          AppSpacing.md,
                    ),
                  ],

                  if (widget.icon !=
                      null) ...[
                    AnimatedContainer(
                      duration:
                          AppDuration.normal,
                      width: 42,
                      height: 42,
                      decoration:
                          BoxDecoration(
                            color:
                                selected
                                    ? Colors
                                        .white
                                        .withOpacity(
                                          0.16,
                                        )
                                    : AppColors
                                        .primarySoft,
                            borderRadius:
                                BorderRadius.circular(
                                  AppRadius.md,
                                ),
                          ),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color:
                            selected
                                ? Colors
                                    .white
                                : AppColors
                                    .primary,
                      ),
                    ),
                    const SizedBox(
                      width:
                          AppSpacing.md,
                    ),
                  ],

                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration:
                          AppDuration.normal,
                      style: AppTextStyles
                          .labelLarge
                          .copyWith(
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                selected
                                    ? Colors
                                        .white
                                    : AppColors
                                        .textPrimary,
                            height: 1.2,
                          ),
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    ),
                  ),

                  if (widget.trailing !=
                      null) ...[
                    const SizedBox(
                      width:
                          AppSpacing.md,
                    ),
                    widget.trailing!,
                  ],

                  if (selected) ...[
                    const SizedBox(
                      width:
                          AppSpacing.md,
                    ),
                    _SelectedIndicator(
                      selected:
                          selected,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiContainer
    extends StatelessWidget {
  final String emoji;

  final bool selected;

  const _EmojiContainer({
    required this.emoji,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            selected
                ? Colors.white
                    .withOpacity(0.14)
                : AppColors.primarySoft,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
      ),
      child: Center(
        child: AnimatedScale(
          duration:
              AppDuration.normal,
          scale:
              selected ? 1.08 : 1,
          child: Text(
            emoji,
            style:
                const TextStyle(
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedIndicator
    extends StatelessWidget {
  final bool selected;

  const _SelectedIndicator({
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration:
          AppDuration.normal,
      scale: selected ? 1 : 0,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          AppRadius.circular,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8,
            sigmaY: 8,
          ),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white
                    .withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}