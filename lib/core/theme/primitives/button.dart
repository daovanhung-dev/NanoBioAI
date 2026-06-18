import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/component_tokens.dart';

/// Button variants for different visual styles and interaction patterns.
///
/// Each variant serves a specific purpose in the UI hierarchy:
/// - **primary**: Main call-to-action buttons with filled background
/// - **secondary**: Secondary actions with subtle styling
/// - **text**: Tertiary actions and navigation with text-only appearance
/// - **icon**: Compact icon-only buttons for toolbars and inline actions
/// - **outlined**: Alternative secondary style with border emphasis
///
/// **Validates: Requirements 4.1, 8.1**
enum ButtonVariant {
  /// Primary button with filled background - use for main CTAs
  primary,

  /// Secondary button with subtle background - use for secondary actions
  secondary,

  /// Text-only button - use for tertiary actions and navigation
  text,

  /// Icon-only button - use for compact actions and toolbars
  icon,

  /// Outlined button with border - use for alternative secondary actions
  outlined,
}

/// A primitive button component with variant-based styling using design tokens.
///
/// `AppButton` is a Layer 3 primitive component that consumes semantic tokens
/// to provide consistent, accessible button styling across the application.
///
/// ## Variants
///
/// ```dart
/// // Primary button (main CTAs)
/// AppButton(
///   variant: ButtonVariant.primary,
///   onPressed: () {},
///   child: Text('Save'),
/// )
///
/// // Secondary button
/// AppButton(
///   variant: ButtonVariant.secondary,
///   onPressed: () {},
///   child: Text('Cancel'),
/// )
///
/// // Text button (tertiary actions)
/// AppButton(
///   variant: ButtonVariant.text,
///   onPressed: () {},
///   child: Text('Learn More'),
/// )
///
/// // Icon button
/// AppButton(
///   variant: ButtonVariant.icon,
///   onPressed: () {},
///   icon: Icons.favorite,
/// )
///
/// // Outlined button
/// AppButton(
///   variant: ButtonVariant.outlined,
///   onPressed: () {},
///   child: Text('Details'),
/// )
/// ```
///
/// ## States
///
/// ```dart
/// // Loading state
/// AppButton(
///   variant: ButtonVariant.primary,
///   onPressed: () {},
///   loading: true,
///   child: Text('Save'),
/// )
///
/// // Disabled state
/// AppButton(
///   variant: ButtonVariant.primary,
///   onPressed: null, // null callback disables button
///   child: Text('Save'),
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
/// - Motion: [AppMotionTokens]
///
/// **Validates: Requirements 4.1, 4.10, 4.11, 8.1, 8.2**
class AppButton extends StatelessWidget {
  /// Creates a button with the specified variant and styling.
  ///
  /// The [variant] determines the visual style.
  /// The [onPressed] callback is required - set to `null` to disable the button.
  /// For icon buttons, provide [icon] instead of [child].
  const AppButton({
    super.key,
    required this.variant,
    required this.onPressed,
    this.child,
    this.icon,
    this.loading = false,
  });

  /// The visual style variant for this button.
  final ButtonVariant variant;

  /// Callback triggered when the button is pressed.
  ///
  /// If `null`, the button is disabled and shows disabled styling.
  final VoidCallback? onPressed;

  /// The button's label content (typically a Text widget).
  ///
  /// For icon buttons, use [icon] instead.
  final Widget? child;

  /// Icon to display for icon variant buttons.
  ///
  /// Only used when [variant] is [ButtonVariant.icon].
  final IconData? icon;

  /// Whether the button is in a loading state.
  ///
  /// When `true`, shows a loading indicator and disables interaction.
  final bool loading;

  /// Determines if the button is effectively disabled.
  bool get _isDisabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Handle icon variant separately
    if (variant == ButtonVariant.icon) {
      return _buildIconButton(isDark);
    }

    // Build standard button variants
    return _buildStandardButton(isDark);
  }

  /// Builds standard button variants (primary, secondary, text, outlined).
  Widget _buildStandardButton(bool isDark) {
    return AnimatedContainer(
      duration: AppMotionTokens.button,
      curve: AppMotionTokens.defaultCurve,
      constraints: const BoxConstraints(
        minHeight: AppSpacingTokens.buttonMinHeight,
      ),
      child: Material(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
        elevation: _getElevation(),
        child: InkWell(
          onTap: _isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadiusTokens.button),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacingTokens.buttonPaddingH,
              vertical: AppSpacingTokens.buttonPaddingV,
            ),
            decoration: variant == ButtonVariant.outlined
                ? BoxDecoration(
                    border: Border.all(
                      color: _getBorderColor(isDark),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.button),
                  )
                : null,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getLoadingIndicatorColor(isDark),
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: AppTextStyles.labelLarge.copyWith(
                        color: _getTextColor(isDark),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds icon button variant.
  Widget _buildIconButton(bool isDark) {
    return AnimatedContainer(
      duration: AppMotionTokens.button,
      curve: AppMotionTokens.defaultCurve,
      constraints: const BoxConstraints(
        minWidth: AppSpacingTokens.touchTargetMin,
        minHeight: AppSpacingTokens.touchTargetMin,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadiusTokens.button),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? AppColorTokens.darkTextPrimary
                            : AppColorTokens.textPrimary,
                      ),
                    ),
                  )
                : Icon(icon, color: _getIconColor(isDark), size: 24),
          ),
        ),
      ),
    );
  }

  /// Gets the background color based on variant and state.
  Color _getBackgroundColor(bool isDark) {
    if (_isDisabled) {
      return isDark
          ? AppColorTokens.darkBorder.withOpacity(0.3)
          : AppColorTokens.border.withOpacity(0.5);
    }

    switch (variant) {
      case ButtonVariant.primary:
        return AppColorTokens.primary;
      case ButtonVariant.secondary:
        return isDark
            ? AppColorTokens.darkSurfaceElevated
            : AppColorTokens.surface;
      case ButtonVariant.text:
      case ButtonVariant.outlined:
        return Colors.transparent;
      case ButtonVariant.icon:
        return Colors.transparent;
    }
  }

  /// Gets the text color based on variant and state.
  Color _getTextColor(bool isDark) {
    if (_isDisabled) {
      return isDark ? AppColorTokens.darkTextMuted : AppColorTokens.textMuted;
    }

    switch (variant) {
      case ButtonVariant.primary:
        return AppColorTokens.textInverse;
      case ButtonVariant.secondary:
      case ButtonVariant.outlined:
        return isDark
            ? AppColorTokens.darkTextPrimary
            : AppColorTokens.textPrimary;
      case ButtonVariant.text:
        return AppColorTokens.primary;
      case ButtonVariant.icon:
        return isDark
            ? AppColorTokens.darkTextPrimary
            : AppColorTokens.textPrimary;
    }
  }

  /// Gets the icon color for icon buttons.
  Color _getIconColor(bool isDark) {
    if (_isDisabled) {
      return isDark ? AppColorTokens.darkTextMuted : AppColorTokens.textMuted;
    }

    return isDark ? AppColorTokens.darkTextPrimary : AppColorTokens.textPrimary;
  }

  /// Gets the border color for outlined variant.
  Color _getBorderColor(bool isDark) {
    if (_isDisabled) {
      return isDark ? AppColorTokens.darkBorder : AppColorTokens.border;
    }

    return isDark
        ? AppColorTokens.darkBorderStrong
        : AppColorTokens.borderStrong;
  }

  /// Gets the loading indicator color based on variant.
  Color _getLoadingIndicatorColor(bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColorTokens.textInverse;
      case ButtonVariant.secondary:
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return AppColorTokens.primary;
      case ButtonVariant.icon:
        return isDark
            ? AppColorTokens.darkTextPrimary
            : AppColorTokens.textPrimary;
    }
  }

  /// Gets the elevation based on variant.
  double _getElevation() {
    if (_isDisabled) {
      return 0;
    }

    switch (variant) {
      case ButtonVariant.primary:
        return 1;
      case ButtonVariant.secondary:
        return 0.5;
      case ButtonVariant.text:
      case ButtonVariant.outlined:
      case ButtonVariant.icon:
        return 0;
    }
  }
}
