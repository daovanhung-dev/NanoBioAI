import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nano_app/core/theme/theme.dart';

class OnboardingTextField extends StatefulWidget {
  final String label;
  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;

  final TextInputType keyboardType;
  final int maxLines;

  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final String? helperText;
  final String? errorText;

  final int? maxLength;

  final TextInputAction? textInputAction;

  final List<TextInputFormatter>? inputFormatters;

  final VoidCallback? onTap;

  final FocusNode? focusNode;

  final EdgeInsetsGeometry? contentPadding;

  final TextCapitalization textCapitalization;

  const OnboardingTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.maxLength,
    this.textInputAction,
    this.inputFormatters,
    this.onTap,
    this.focusNode,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<OnboardingTextField> createState() =>
      _OnboardingTextFieldState();
}

class _OnboardingTextFieldState
    extends State<OnboardingTextField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;

  late final FocusNode _focusNode;

  late final AnimationController _animationController;

  late final Animation<double> _scaleAnimation;

  late final Animation<double> _glowAnimation;

  bool _isFocused = false;

  bool _obscure = false;

  bool get _hasError =>
      widget.errorText != null &&
      widget.errorText!.trim().isNotEmpty;

  bool get _isMultiline => widget.maxLines > 1;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );

    _focusNode = widget.focusNode ?? FocusNode();

    _obscure = widget.obscureText;

    _animationController = AnimationController(
      vsync: this,
      duration: AppDuration.input,
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.015,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.smoothCurve,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.smoothCurve,
      ),
    );

    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (!mounted) return;

    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void didUpdateWidget(
    covariant OnboardingTextField oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    _controller.dispose();
    _animationController.dispose();

    super.dispose();
  }

  Color get _borderColor {
    if (_hasError) {
      return AppColors.error;
    }

    if (_isFocused) {
      return AppColors.primary;
    }

    return AppColors.border;
  }

  Gradient get _activeGradient {
    if (_hasError) {
      return AppGradients.danger;
    }

    return AppGradients.primary;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = AppSpacing.responsive(
      AppSpacing.md,
      screenWidth: screenWidth,
    );

    final verticalPadding = _isMultiline
        ? AppSpacing.responsive(
            18,
            screenWidth: screenWidth,
          )
        : AppSpacing.responsive(
            16,
            screenWidth: screenWidth,
          );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppDuration.fast,
                  width: 8,
                  height: 8,
                  decoration: AppDecoration.circle(
                    gradient: _isFocused
                        ? AppGradients.primary
                        : null,
                    color: _isFocused
                        ? null
                        : AppColors.border,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: AppDuration.fast,
                    curve: AppAnimations.smoothCurve,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _hasError
                          ? AppColors.error
                          : _isFocused
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(widget.label),
                  ),
                ),
              ],
            ),
          ),

          AnimatedContainer(
            duration: AppDuration.input,
            curve: AppAnimations.smoothCurve,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppRadius.xl,
              ),
              gradient: _isFocused
                  ? _activeGradient
                  : null,
              boxShadow: [
                ...(_isFocused
                    ? AppShadows.primary
                    : AppShadows.card),
                BoxShadow(
                  color: (_hasError
                          ? AppColors.error
                          : AppColors.primary)
                      .withOpacity(
                    0.12 * _glowAnimation.value,
                  ),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.4),
            child: AnimatedContainer(
              duration: AppDuration.input,
              curve: AppAnimations.smoothCurve,
              decoration: AppDecoration.container(
                color: widget.enabled
                    ? AppColors.surface
                    : AppColors.cardAlt,
                radius: AppRadius.xl,
                border: Border.all(
                  color: _isFocused
                      ? Colors.transparent
                      : _borderColor,
                ),
              ),
              child: Row(
                crossAxisAlignment: _isMultiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        top: _isMultiline
                            ? verticalPadding - 2
                            : 0,
                        right: AppSpacing.sm,
                      ),
                      child: AnimatedContainer(
                        duration: AppDuration.fast,
                        curve: AppAnimations.smoothCurve,
                        width: 46,
                        height: 46,
                        decoration: _isFocused
                            ? AppDecoration.primaryGradient(
                                radius: AppRadius.lg,
                              )
                            : AppDecoration.container(
                                color:
                                    AppColors.primarySoft,
                                radius: AppRadius.lg,
                              ),
                        child: IconTheme(
                          data: IconThemeData(
                            color: _isFocused
                                ? Colors.white
                                : AppColors.primary,
                            size: 22,
                          ),
                          child: widget.prefixIcon!,
                        ),
                      ),
                    ),

                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      obscureText: _obscure,
                      keyboardType: widget.keyboardType,
                      readOnly: widget.readOnly,
                      onTap: widget.onTap,
                      maxLength: widget.maxLength,
                      maxLines: widget.maxLines,
                      minLines: widget.maxLines,
                      textInputAction:
                          widget.textInputAction,
                      inputFormatters:
                          widget.inputFormatters,
                      textCapitalization:
                          widget.textCapitalization,
                      cursorColor: AppColors.primary,
                      style:
                          AppTypography.readable(
                        AppTextStyles.bodyLarge.copyWith(
                          color:
                              AppColors.textPrimary,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        hintText: widget.hint,
                        hintStyle:
                            AppTextStyles.bodyMedium
                                .copyWith(
                          color:
                              AppColors.textHint,
                          fontWeight:
                              FontWeight.w500,
                        ),
                        contentPadding:
                            widget.contentPadding ??
                                EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical:
                                      verticalPadding,
                                ),
                      ),
                    ),
                  ),

                  if (widget.obscureText)
                    Padding(
                      padding: EdgeInsets.only(
                        right: horizontalPadding,
                      ),
                      child: GestureDetector(
                        behavior:
                            HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppDuration.fast,
                          curve:
                              AppAnimations.smoothCurve,
                          width: 44,
                          height: 44,
                          decoration: _isFocused
                              ? AppDecoration.glass(
                                  radius:
                                      AppRadius.lg,
                                )
                              : AppDecoration.container(
                                  color: AppColors
                                      .primarySoft,
                                  radius:
                                      AppRadius.lg,
                                ),
                          child: Icon(
                            _obscure
                                ? AppIcons
                                    .visibilityOff
                                : AppIcons
                                    .visibility,
                            size: 20,
                            color:
                                AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  if (widget.suffixIcon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        right: horizontalPadding,
                      ),
                      child: widget.suffixIcon!,
                    ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: AppDuration.normal,
            curve: AppAnimations.smoothCurve,
            child: (_hasError ||
                    widget.helperText != null)
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration:
                              AppDecoration.circle(
                            color: _hasError
                                ? AppColors
                                    .errorSoft
                                : AppColors
                                    .primarySoft,
                          ),
                          child: Icon(
                            _hasError
                                ? AppIcons.error
                                : AppIcons.info,
                            size: 14,
                            color: _hasError
                                ? AppColors.error
                                : AppColors
                                    .primary,
                          ),
                        ),
                        const SizedBox(
                          width: AppSpacing.sm,
                        ),
                        Expanded(
                          child: Text(
                            _hasError
                                ? widget.errorText!
                                : widget.helperText ??
                                      '',
                            style: AppTextStyles
                                .bodySmall
                                .copyWith(
                              color: _hasError
                                  ? AppColors.error
                                  : AppColors
                                      .textSecondary,
                              fontWeight:
                                  FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}