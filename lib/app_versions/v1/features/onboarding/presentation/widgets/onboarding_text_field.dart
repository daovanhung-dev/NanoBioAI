import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Compact free-text field with a clear focus state shared by all onboarding views.
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
  bool _ownsFocusNode = false;
  bool _obscure = false;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.trim().isNotEmpty;

  bool get _isFocused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _attachFocusNode(widget.focusNode);
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant OnboardingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }

    if (widget.obscureText != oldWidget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  void _attachFocusNode(FocusNode? node) {
    _ownsFocusNode = node == null;
    _focusNode = node ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _detachFocusNode();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;
    final vertical = multiline ? 10.0 : 8.5;
    final borderColor = _hasError
        ? AppColors.error
        : _isFocused
        ? NabiPalette.royalBlue
        : NabiPalette.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          style: AppTextStyles.labelMedium.copyWith(
            color: _hasError
                ? AppColors.error
                : _isFocused
                ? NabiPalette.royalBlue
                : NabiPalette.mutedInk,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: NabiPalette.royalBlue.withValues(alpha: 0.16),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: multiline ? widget.maxLines.clamp(2, 4).toInt() : 1,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            style: AppTextStyles.bodyMedium.copyWith(
              color: NabiPalette.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 10, right: 8),
                      child: IconTheme(
                        data: IconThemeData(
                          color: _isFocused
                              ? NabiPalette.royalBlue
                              : NabiPalette.mutedInk,
                          size: 20,
                        ),
                        child: widget.prefixIcon!,
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: _buildSuffix(),
              contentPadding:
                  widget.contentPadding ??
                  EdgeInsets.symmetric(horizontal: 12, vertical: vertical),
              filled: true,
              fillColor: widget.enabled
                  ? Colors.white.withValues(alpha: 0.88)
                  : NabiPalette.canvasDeep,
              errorText: widget.errorText,
              errorStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
              helperText: widget.helperText,
              helperStyle: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
              ),
              border: _border(borderColor),
              enabledBorder: _border(borderColor),
              focusedBorder: _border(
                _hasError ? AppColors.error : NabiPalette.royalBlue,
                width: 1.5,
              ),
              errorBorder: _border(AppColors.error, width: 1.4),
              focusedErrorBorder: _border(AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        iconSize: 20,
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: NabiPalette.mutedInk,
        ),
      );
    }
    return widget.suffixIcon;
  }
}
