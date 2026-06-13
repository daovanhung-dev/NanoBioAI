import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/component_tokens.dart';

/// Badge variants for different display patterns.
///
/// Each variant serves a specific purpose:
/// - **status**: Displays status with text (e.g., "Active", "Pending")
/// - **count**: Displays numeric count (e.g., notification count)
/// - **dot**: Displays simple dot indicator
///
/// **Validates: Requirements 4.5, 8.1**
enum BadgeVariant {
  /// Status badge with text label
  status,

  /// Count badge with numeric value
  count,

  /// Simple dot indicator badge
  dot,
}

/// Badge status types for semantic color mapping.
///
/// Used with [BadgeVariant.status] to apply appropriate colors.
enum BadgeStatus {
  /// Success status (green)
  success,

  /// Warning status (amber)
  warning,

  /// Error status (red)
  error,

  /// Info status (blue)
  info,

  /// Neutral/default status (gray)
  neutral,
}

/// A primitive badge component with variant-based styling using design tokens.
///
/// `AppBadge` is a Layer 3 primitive component that provides consistent status
/// and notification indicators across the application.
///
/// ## Variants
///
/// ```dart
/// // Status badge
/// AppBadge(
///   variant: BadgeVariant.status,
///   status: BadgeStatus.success,
///   label: 'Active',
/// )
///
/// // Count badge (e.g., notifications)
/// AppBadge(
///   variant: BadgeVariant.count,
///   count: 5,
/// )
///
/// // Dot badge (simple indicator)
/// AppBadge(
///   variant: BadgeVariant.dot,
///   status: BadgeStatus.error,
/// )
/// ```
///
/// ## As Overlay (for icons)
///
/// ```dart
/// Stack(
///   children: [
///     Icon(Icons.notifications),
///     Positioned(
///       right: 0,
///       top: 0,
///       child: AppBadge(
///         variant: BadgeVariant.count,
///         count: 3,
///       ),
///     ),
///   ],
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
/// **Validates: Requirements 4.5, 4.10, 4.11, 8.1, 8.2**
class AppBadge extends StatelessWidget {
  /// Creates a badge with the specified variant and styling.
  ///
  /// The [variant] determines the visual style.
  /// For [BadgeVariant.status], provide [label] and [status].
  /// For [BadgeVariant.count], provide [count].
  /// For [BadgeVariant.dot], provide [status].
  const AppBadge({
    super.key,
    required this.variant,
    this.label,
    this.count,
    this.status = BadgeStatus.neutral,
  });

  /// The visual style variant for this badge.
  final BadgeVariant variant;

  /// Label text for status badges.
  final String? label;

  /// Numeric count for count badges.
  final int? count;

  /// Status type for semantic color mapping.
  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: variant == BadgeVariant.status
            ? Border.all(
                color: _getBorderColor(isDark),
                width: 1,
              )
            : null,
      ),
      constraints: _getConstraints(),
      child: _buildContent(isDark),
    );
  }

  /// Builds the badge content based on variant.
  Widget _buildContent(bool isDark) {
    switch (variant) {
      case BadgeVariant.status:
        return Text(
          label ?? '',
          style: AppTextStyles.caption.copyWith(
            color: _getTextColor(isDark),
            fontWeight: FontWeight.w600,
          ),
        );
      case BadgeVariant.count:
        return Text(
          count != null && count! > 99 ? '99+' : (count?.toString() ?? '0'),
          style: AppTextStyles.caption.copyWith(
            color: AppColorTokens.textInverse,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        );
      case BadgeVariant.dot:
        return const SizedBox.shrink();
    }
  }

  /// Gets the background color based on variant, status, and theme mode.
  Color _getBackgroundColor(bool isDark) {
    switch (variant) {
      case BadgeVariant.status:
        return _getStatusBackgroundColor(isDark);
      case BadgeVariant.count:
        return AppColorTokens.error;
      case BadgeVariant.dot:
        return _getStatusColor();
    }
  }

  /// Gets the status-specific background color.
  Color _getStatusBackgroundColor(bool isDark) {
    switch (status) {
      case BadgeStatus.success:
        return AppColorTokens.successLight;
      case BadgeStatus.warning:
        return AppColorTokens.warningLight;
      case BadgeStatus.error:
        return AppColorTokens.errorLight;
      case BadgeStatus.info:
        return AppColorTokens.infoLight;
      case BadgeStatus.neutral:
        return isDark
            ? AppColorTokens.darkSurface
            : AppColorTokens.surfaceElevated;
    }
  }

  /// Gets the status color for borders and dot variant.
  Color _getStatusColor() {
    switch (status) {
      case BadgeStatus.success:
        return AppColorTokens.success;
      case BadgeStatus.warning:
        return AppColorTokens.warning;
      case BadgeStatus.error:
        return AppColorTokens.error;
      case BadgeStatus.info:
        return AppColorTokens.info;
      case BadgeStatus.neutral:
        return AppColorTokens.textMuted;
    }
  }

  /// Gets the border color for status variant.
  Color _getBorderColor(bool isDark) {
    return _getStatusColor();
  }

  /// Gets the text color based on status and theme mode.
  Color _getTextColor(bool isDark) {
    return _getStatusColor();
  }

  /// Gets the padding based on variant.
  EdgeInsets _getPadding() {
    switch (variant) {
      case BadgeVariant.status:
        return EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.chipPaddingH,
          vertical: AppSpacingTokens.chipPaddingV,
        );
      case BadgeVariant.count:
        return const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        );
      case BadgeVariant.dot:
        return EdgeInsets.zero;
    }
  }

  /// Gets the border radius based on variant.
  double _getBorderRadius() {
    switch (variant) {
      case BadgeVariant.status:
        return AppRadiusTokens.badge;
      case BadgeVariant.count:
      case BadgeVariant.dot:
        return 999; // Full circle
    }
  }

  /// Gets the size constraints based on variant.
  BoxConstraints? _getConstraints() {
    switch (variant) {
      case BadgeVariant.status:
        return null;
      case BadgeVariant.count:
        return const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        );
      case BadgeVariant.dot:
        return const BoxConstraints(
          minWidth: 8,
          minHeight: 8,
          maxWidth: 8,
          maxHeight: 8,
        );
    }
  }
}
