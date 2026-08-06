import 'package:flutter/material.dart';

import '../../motion/app_motion_scope.dart';
import '../app_text_styles.dart';
import '../tokens/color_tokens.dart';
import '../tokens/component_tokens.dart';
import '../tokens/spacing_tokens.dart';

enum InputVariant { textField, dropdown, search }

/// Canonical Kinetic Aura input with focus and validation transitions.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.variant,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
  });

  final InputVariant variant;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool autofocus;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _ownedFocusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(
      _handleFocusChanged,
    );
    _ownedFocusNode?.dispose();
    _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText?.trim().isNotEmpty == true;
    final focused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AnimatedDefaultTextStyle(
            duration: AppMotionScope.duration(context, AppMotionTokens.input),
            curve: AppMotionTokens.defaultCurve,
            style: AppTextStyles.labelLarge.copyWith(
              color: hasError
                  ? AppColorTokens.error
                  : focused
                      ? AppColorTokens.primary
                      : isDark
                          ? AppColorTokens.darkTextPrimary
                          : AppColorTokens.textPrimary,
            ),
            child: Text(widget.label!),
          ),
          SizedBox(height: AppSpacingTokens.itemSpacing),
        ],
        AnimatedContainer(
          duration: AppMotionScope.duration(context, AppMotionTokens.input),
          curve: AppMotionTokens.defaultCurve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadiusTokens.input),
            boxShadow: focused && !hasError
                ? [
                    BoxShadow(
                      color: AppColorTokens.primary.withValues(alpha: 0.13),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColorTokens.darkTextPrimary
                  : AppColorTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColorTokens.darkTextMuted
                    : AppColorTokens.textMuted,
              ),
              errorText: widget.errorText,
              errorStyle: AppTextStyles.caption.copyWith(
                color: AppColorTokens.error,
              ),
              prefixIcon: _buildPrefixIcon(isDark, focused),
              suffixIcon: widget.suffixIcon != null
                  ? AnimatedRotation(
                      turns: widget.variant == InputVariant.dropdown && focused
                          ? 0.5
                          : 0,
                      duration: AppMotionScope.duration(
                        context,
                        AppMotionTokens.input,
                      ),
                      child: Icon(
                        widget.suffixIcon,
                        color: focused
                            ? AppColorTokens.primary
                            : isDark
                                ? AppColorTokens.darkTextSecondary
                                : AppColorTokens.textSecondary,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? AppColorTokens.darkSurface
                  : AppColorTokens.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.inputPaddingH,
                vertical: AppSpacingTokens.inputPaddingV,
              ),
              border: _border(isDark, AppColorTokens.border, 1),
              enabledBorder: _border(
                isDark,
                isDark ? AppColorTokens.darkBorder : AppColorTokens.border,
                1,
              ),
              focusedBorder: _border(
                isDark,
                AppColorTokens.primary,
                2,
              ),
              errorBorder: _border(isDark, AppColorTokens.error, 1.2),
              focusedErrorBorder: _border(
                isDark,
                AppColorTokens.error,
                2,
              ),
              disabledBorder: _border(
                isDark,
                (isDark ? AppColorTokens.darkBorder : AppColorTokens.border)
                    .withValues(alpha: 0.5),
                1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(bool isDark, Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadiusTokens.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildPrefixIcon(bool isDark, bool focused) {
    IconData? iconData = widget.prefixIcon;
    iconData ??= switch (widget.variant) {
      InputVariant.search => Icons.search,
      InputVariant.dropdown => Icons.arrow_drop_down,
      InputVariant.textField => null,
    };
    if (iconData == null) return null;

    return AnimatedSwitcher(
      duration: AppMotionScope.duration(context, AppMotionTokens.input),
      child: Icon(
        iconData,
        key: ValueKey('${widget.variant.name}-$focused'),
        color: focused
            ? AppColorTokens.primary
            : isDark
                ? AppColorTokens.darkTextSecondary
                : AppColorTokens.textSecondary,
      ),
    );
  }
}
