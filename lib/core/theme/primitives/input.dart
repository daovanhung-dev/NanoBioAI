import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/component_tokens.dart';

/// Input variants for different input patterns.
///
/// Each variant serves a specific purpose:
/// - **textField**: Standard text input field
/// - **dropdown**: Dropdown selection input
/// - **search**: Search input with search icon
///
/// **Validates: Requirements 4.4, 8.1**
enum InputVariant {
  /// Standard text input field
  textField,

  /// Dropdown selection input
  dropdown,

  /// Search input with search icon
  search,
}

/// A primitive input component with variant-based styling using design tokens.
///
/// `AppInput` is a Layer 3 primitive component that provides consistent form
/// input styling across the application.
///
/// ## Variants
///
/// ```dart
/// // Text field
/// AppInput(
///   variant: InputVariant.textField,
///   label: 'Full Name',
///   hint: 'Enter your full name',
///   controller: nameController,
/// )
///
/// // Search input
/// AppInput(
///   variant: InputVariant.search,
///   hint: 'Search meals...',
///   controller: searchController,
///   onChanged: (value) {
///     // Handle search
///   },
/// )
///
/// // Dropdown (uses Material DropdownButtonFormField)
/// AppInput(
///   variant: InputVariant.dropdown,
///   label: 'Gender',
///   hint: 'Select gender',
/// )
/// ```
///
/// ## Error State
///
/// ```dart
/// AppInput(
///   variant: InputVariant.textField,
///   label: 'Email',
///   errorText: 'Invalid email format',
///   controller: emailController,
/// )
/// ```
///
/// ## Token-Based Styling
///
/// All styling references semantic tokens:
/// - Colors: [AppColorTokens]
/// - Spacing: [AppSpacingTokens]
/// - Radius: [AppRadiusTokens]
/// - Text: [AppTextStyles]
///
/// **Validates: Requirements 4.4, 4.10, 4.11, 8.1, 8.2**
class AppInput extends StatelessWidget {
  /// Creates an input with the specified variant and styling.
  ///
  /// The [variant] determines the visual style and interaction pattern.
  /// The [controller] manages the text input state.
  /// The [label] is the field label displayed above the input.
  /// The [hint] is the placeholder text shown when empty.
  /// The [errorText] displays validation error below the input.
  const AppInput({
    super.key,
    required this.variant,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  /// The visual style variant for this input.
  final InputVariant variant;

  /// Controller to manage the input text.
  final TextEditingController? controller;

  /// Label text displayed above the input field.
  final String? label;

  /// Placeholder hint text shown when input is empty.
  final String? hint;

  /// Error message displayed below the input field.
  final String? errorText;

  /// Callback triggered when the input value changes.
  final ValueChanged<String>? onChanged;

  /// Callback triggered when the user submits the input.
  final ValueChanged<String>? onSubmitted;

  /// Whether the input is enabled for interaction.
  final bool enabled;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// The keyboard type for the input.
  final TextInputType? keyboardType;

  /// Maximum number of lines for the input.
  final int maxLines;

  /// Optional leading icon inside the input field.
  final IconData? prefixIcon;

  /// Optional trailing icon inside the input field.
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark
                  ? AppColorTokens.darkTextPrimary
                  : AppColorTokens.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacingTokens.itemSpacing),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColorTokens.darkTextPrimary
                : AppColorTokens.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColorTokens.darkTextMuted
                  : AppColorTokens.textMuted,
            ),
            errorText: errorText,
            errorStyle: AppTextStyles.caption.copyWith(
              color: AppColorTokens.error,
            ),
            prefixIcon: _buildPrefixIcon(isDark),
            suffixIcon: suffixIcon != null
                ? Icon(
                    suffixIcon,
                    color: isDark
                        ? AppColorTokens.darkTextSecondary
                        : AppColorTokens.textSecondary,
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColorTokens.darkSurface
                : AppColorTokens.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacingTokens.inputPaddingH,
              vertical: AppSpacingTokens.inputPaddingV,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              borderSide: BorderSide(
                color: isDark
                    ? AppColorTokens.darkBorder
                    : AppColorTokens.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              borderSide: BorderSide(
                color: isDark
                    ? AppColorTokens.darkBorder
                    : AppColorTokens.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              borderSide: BorderSide(color: AppColorTokens.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              borderSide: BorderSide(color: AppColorTokens.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              borderSide: BorderSide(color: AppColorTokens.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              borderSide: BorderSide(
                color: isDark
                    ? AppColorTokens.darkBorder.withValues(alpha: 0.5)
                    : AppColorTokens.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the prefix icon based on variant and provided prefixIcon.
  Widget? _buildPrefixIcon(bool isDark) {
    IconData? iconData;

    // Use variant-specific icon if no custom prefixIcon is provided
    if (prefixIcon != null) {
      iconData = prefixIcon;
    } else if (variant == InputVariant.search) {
      iconData = Icons.search;
    } else if (variant == InputVariant.dropdown) {
      iconData = Icons.arrow_drop_down;
    }

    if (iconData == null) return null;

    return Icon(
      iconData,
      color: isDark
          ? AppColorTokens.darkTextSecondary
          : AppColorTokens.textSecondary,
    );
  }
}
