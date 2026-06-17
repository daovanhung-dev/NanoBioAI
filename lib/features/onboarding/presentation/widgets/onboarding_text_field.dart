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
  State<OnboardingTextField> createState() => _OnboardingTextFieldState();
}

class _OnboardingTextFieldState extends State<OnboardingTextField> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;

  bool _isFocused = false;
  bool _obscure = false;
  bool _hasText = false;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.trim().isNotEmpty;

  bool get _isMultiline => widget.maxLines > 1;

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscure = widget.obscureText;
    _hasText = widget.initialValue.trim().isNotEmpty;

    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant OnboardingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChanged);

      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }

      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
      _isFocused = _focusNode.hasFocus;
    }

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      final selectionOffset = widget.initialValue.length;
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: selectionOffset),
      );
      _hasText = widget.initialValue.trim().isNotEmpty;
    }

    if (widget.obscureText != oldWidget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);

    if (_ownsFocusNode) {
      _focusNode.dispose();
    }

    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;

    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleChanged(String value) {
    final hasText = value.trim().isNotEmpty;

    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    widget.onChanged(value);
  }

  Color get _labelColor {
    if (!widget.enabled) return AppColors.textDisabled;
    if (_hasError) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return AppColors.textSecondary;
  }

  Color get _borderColor {
    if (!widget.enabled) return AppColors.border.withOpacity(0.52);
    if (_hasError) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return AppColors.border.withOpacity(_hasText ? 0.92 : 0.68);
  }

  Color get _fieldColor {
    if (!widget.enabled) return AppColors.cardAlt;
    if (_hasError) return AppColors.errorSoft.withOpacity(0.18);
    if (_isFocused) return AppColors.surface;
    return AppColors.surface;
  }

  List<BoxShadow> get _fieldShadow {
    if (!widget.enabled) return const [];

    if (_hasError) {
      return [
        BoxShadow(
          color: AppColors.error.withOpacity(0.08),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
    }

    if (_isFocused) {
      return [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
    }

    return AppShadows.card;
  }

  EdgeInsetsGeometry _contentPadding(double screenWidth) {
    if (widget.contentPadding != null) return widget.contentPadding!;

    final verticalPadding = AppSpacing.responsive(
      _isMultiline ? 17 : 15,
      screenWidth: screenWidth,
    );

    return EdgeInsets.symmetric(vertical: verticalPadding);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppSpacing.responsive(
      AppSpacing.md,
      screenWidth: screenWidth,
    );

    return Semantics(
      textField: true,
      label: widget.label,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(
            label: widget.label,
            color: _labelColor,
            showActiveMark: _isFocused || _hasText || _hasError,
            hasError: _hasError,
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedContainer(
            duration: AppDuration.input,
            curve: AppAnimations.smoothCurve,
            decoration: BoxDecoration(
              color: _fieldColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: _borderColor,
                width: _isFocused || _hasError ? 1.35 : 1,
              ),
              boxShadow: _fieldShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled
                      ? () {
                          widget.onTap?.call();

                          if (!widget.readOnly) {
                            _focusNode.requestFocus();
                          }
                        }
                      : null,
                  splashColor: AppColors.primary.withOpacity(0.04),
                  highlightColor: AppColors.primary.withOpacity(0.025),
                  child: Row(
                    crossAxisAlignment: _isMultiline
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      if (widget.prefixIcon != null)
                        Padding(
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            top: _isMultiline ? AppSpacing.md : 0,
                            right: AppSpacing.sm,
                          ),
                          child: _FieldIconSlot(
                            isActive: _isFocused || _hasText,
                            hasError: _hasError,
                            enabled: widget.enabled,
                            child: widget.prefixIcon!,
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
                          minLines: _isMultiline ? widget.maxLines : 1,
                          textInputAction: widget.textInputAction,
                          inputFormatters: widget.inputFormatters,
                          textCapitalization: widget.textCapitalization,
                          cursorColor:
                              _hasError ? AppColors.error : AppColors.primary,
                          cursorWidth: 1.7,
                          style: AppTypography.readable(
                            AppTextStyles.bodyLarge.copyWith(
                              color: widget.enabled
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                          onChanged: _handleChanged,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            counterText: '',
                            isDense: true,
                            hintText: widget.hint,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint.withOpacity(0.82),
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.05,
                            ),
                            contentPadding: _contentPadding(screenWidth),
                          ),
                        ),
                      ),
                      if (widget.obscureText || widget.suffixIcon != null)
                        Padding(
                          padding: EdgeInsets.only(
                            left: AppSpacing.xs,
                            right: horizontalPadding - 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.suffixIcon != null)
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: widget.obscureText ? AppSpacing.xs : 0,
                                  ),
                                  child: IconTheme(
                                    data: IconThemeData(
                                      color: _hasError
                                          ? AppColors.error
                                          : _isFocused
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    child: widget.suffixIcon!,
                                  ),
                                ),
                              if (widget.obscureText)
                                _IconActionButton(
                                  tooltip: _obscure
                                      ? 'Hiển thị nội dung'
                                      : 'Ẩn nội dung',
                                  icon: _obscure
                                      ? AppIcons.visibilityOff
                                      : AppIcons.visibility,
                                  isActive: _isFocused,
                                  hasError: _hasError,
                                  onTap: widget.enabled
                                      ? () {
                                          setState(() {
                                            _obscure = !_obscure;
                                          });
                                        }
                                      : null,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _SupportingText(
            helperText: widget.helperText,
            errorText: widget.errorText,
            hasError: _hasError,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;
  final bool showActiveMark;
  final bool hasError;

  const _FieldLabel({
    required this.label,
    required this.color,
    required this.showActiveMark,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDuration.fast,
            curve: AppAnimations.smoothCurve,
            width: showActiveMark ? 18 : 8,
            height: 4,
            decoration: BoxDecoration(
              color: showActiveMark
                  ? hasError
                      ? AppColors.error
                      : AppColors.primary
                  : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: AppDuration.fast,
              curve: AppAnimations.smoothCurve,
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldIconSlot extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final bool hasError;
  final bool enabled;

  const _FieldIconSlot({
    required this.child,
    required this.isActive,
    required this.hasError,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = !enabled
        ? AppColors.textDisabled
        : hasError
            ? AppColors.error
            : isActive
                ? AppColors.primary
                : AppColors.textSecondary;

    final backgroundColor = !enabled
        ? AppColors.cardAlt
        : hasError
            ? AppColors.errorSoft.withOpacity(0.32)
            : isActive
                ? AppColors.primarySoft.withOpacity(0.78)
                : AppColors.cardAlt.withOpacity(0.72);

    return AnimatedContainer(
      duration: AppDuration.fast,
      curve: AppAnimations.smoothCurve,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: IconTheme(
        data: IconThemeData(
          color: iconColor,
          size: 20,
        ),
        child: child,
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final bool hasError;
  final VoidCallback? onTap;

  const _IconActionButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = hasError
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : AppColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          curve: AppAnimations.smoothCurve,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primarySoft.withOpacity(0.72)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _SupportingText extends StatelessWidget {
  final String? helperText;
  final String? errorText;
  final bool hasError;

  const _SupportingText({
    required this.helperText,
    required this.errorText,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final text = hasError ? errorText : helperText;
    final hasText = text != null && text.trim().isNotEmpty;

    return AnimatedSize(
      duration: AppDuration.normal,
      curve: AppAnimations.smoothCurve,
      alignment: Alignment.topCenter,
      child: hasText
          ? Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                left: AppSpacing.xs,
                right: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    curve: AppAnimations.smoothCurve,
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: hasError
                          ? AppColors.errorSoft
                          : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasError ? AppIcons.error : AppIcons.info,
                      size: 12,
                      color: hasError ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      text.trim(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: hasError
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
