import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_app/core/constants/app/app_duration.dart';
import 'package:nano_app/core/constants/app/app_radius.dart';
import 'package:nano_app/core/constants/ui/color_constants.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';

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

class _OnboardingTextFieldState extends State<OnboardingTextField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;

  late final FocusNode _focusNode;

  late final AnimationController _animationController;

  bool _isFocused = false;

  bool _obscure = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);

    _focusNode = widget.focusNode ?? FocusNode();

    _obscure = widget.obscureText;

    _animationController = AnimationController(
      vsync: this,
      duration: AppDuration.splash,
    );

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });

        if (_isFocused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    _controller.dispose();
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    final bool isMultiline = widget.maxLines > 1;

    return AnimatedContainer(
      duration: AppDuration.splash,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? AppColors.primary.withOpacity(0.12)
                : Colors.black.withOpacity(0.035),
            blurRadius: _isFocused ? 24 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: AnimatedDefaultTextStyle(
              duration: AppDuration.splash,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: hasError
                    ? AppColors.secondary
                    : _isFocused
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
              child: Text(widget.label),
            ),
          ),

          AnimatedContainer(
            duration: AppDuration.splash,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: _isFocused
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                  : null,
              border: Border.all(
                color: hasError
                    ? AppColors.primary
                    : _isFocused
                    ? Colors.transparent
                    : AppColors.primary.withOpacity(0.65),
              ),
              color: Colors.white,
            ),
            child: AnimatedContainer(
              duration: AppDuration.splash,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg - 1),
              ),
              child: Row(
                crossAxisAlignment: isMultiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        top: isMultiline ? 18 : 0,
                        right: 12,
                      ),
                      child: AnimatedContainer(
                        duration: AppDuration.splash,
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          color: _isFocused
                              ? AppColors.primary
                              : AppColors.primary,
                        ),
                        child: IconTheme(
                          data: IconThemeData(
                            color: _isFocused
                                ? Colors.white
                                : AppColors.primary,
                            size: 20,
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
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      textCapitalization: widget.textCapitalization,
                      cursorColor: AppColors.primary,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.45,
                      ),
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        contentPadding:
                            widget.contentPadding ??
                            EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: isMultiline ? 20 : 18,
                            ),
                      ),
                    ),
                  ),

                  if (widget.obscureText)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppDuration.splash,
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            color: _isFocused
                                ? AppColors.primary
                                : AppColors.background,
                          ),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  if (widget.suffixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: widget.suffixIcon!,
                    ),
                ],
              ),
            ),
          ),

          if (widget.helperText != null || hasError)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 10),
              child: Row(
                children: [
                  Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: hasError ? AppColors.secondary : AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasError ? widget.errorText! : widget.helperText ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: hasError
                            ? AppColors.secondary
                            : AppColors.secondary,
                        height: 1.45,
                      ),
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
