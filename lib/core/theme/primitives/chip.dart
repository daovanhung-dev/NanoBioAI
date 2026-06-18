import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/component_tokens.dart';

/// Chip variants for different interaction patterns.
///
/// Each variant serves a specific purpose:
/// - **selectable**: Toggle selection state (e.g., health goals, conditions)
/// - **filter**: Multi-select filtering (e.g., meal types, categories)
/// - **action**: Single-action chips (e.g., tags with delete)
///
/// **Validates: Requirements 4.3, 8.1**
enum ChipVariant {
  /// Selectable chip with toggle state - use for single or multi-select options
  selectable,

  /// Filter chip for filtering lists - use for filter controls
  filter,

  /// Action chip with optional delete - use for tags and removable items
  action,
}

/// A primitive chip component with variant-based styling using design tokens.
///
/// `AppChip` is a Layer 3 primitive component that provides consistent compact
/// selection and action controls across the application.
///
/// ## Variants
///
/// ```dart
/// // Selectable chip (e.g., health goals)
/// AppChip(
///   variant: ChipVariant.selectable,
///   label: 'Lose Weight',
///   selected: true,
///   onTap: () {
///     // Toggle selection
///   },
/// )
///
/// // Filter chip
/// AppChip(
///   variant: ChipVariant.filter,
///   label: 'Breakfast',
///   selected: isBreakfastFiltered,
///   onTap: () {
///     // Toggle filter
///   },
/// )
///
/// // Action chip with delete
/// AppChip(
///   variant: ChipVariant.action,
///   label: 'Peanut Allergy',
///   onDeleted: () {
///     // Remove chip
///   },
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
/// **Validates: Requirements 4.3, 4.10, 4.11, 8.1, 8.2**
class AppChip extends StatelessWidget {
  /// Creates a chip with the specified variant and styling.
  ///
  /// The [variant] determines the visual style and interaction pattern.
  /// The [label] is the text displayed on the chip.
  /// The [selected] state affects the visual appearance (for selectable/filter variants).
  /// The [onTap] callback is triggered when the chip is tapped.
  /// The [onDeleted] callback shows a delete icon when provided.
  const AppChip({
    super.key,
    required this.variant,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.icon,
  });

  /// The visual style variant for this chip.
  final ChipVariant variant;

  /// The text label displayed on the chip.
  final String label;

  /// Whether the chip is in selected state (for selectable/filter variants).
  final bool selected;

  /// Callback triggered when the chip is tapped.
  final VoidCallback? onTap;

  /// Callback triggered when the delete icon is tapped.
  ///
  /// When provided, displays a delete icon on the chip.
  final VoidCallback? onDeleted;

  /// Optional leading icon for the chip.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppMotionTokens.card,
      curve: AppMotionTokens.defaultCurve,
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppRadiusTokens.chip),
        border: _getBorder(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadiusTokens.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.chip),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacingTokens.chipPaddingH,
              vertical: AppSpacingTokens.chipPaddingV,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: _getTextColor(isDark)),
                  SizedBox(width: AppSpacingTokens.iconTextSpacing),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: _getTextColor(isDark),
                  ),
                ),
                if (onDeleted != null) ...[
                  SizedBox(width: AppSpacingTokens.iconTextSpacing),
                  GestureDetector(
                    onTap: onDeleted,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: _getTextColor(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gets the background color based on variant, selection state, and theme mode.
  Color _getBackgroundColor(bool isDark) {
    // Selected state colors
    if (selected &&
        (variant == ChipVariant.selectable || variant == ChipVariant.filter)) {
      return AppColorTokens.primaryLight;
    }

    // Unselected state colors
    if (isDark) {
      return AppColorTokens.darkSurface;
    } else {
      return AppColorTokens.surfaceElevated;
    }
  }

  /// Gets the text color based on variant, selection state, and theme mode.
  Color _getTextColor(bool isDark) {
    // Selected state text color
    if (selected &&
        (variant == ChipVariant.selectable || variant == ChipVariant.filter)) {
      return AppColorTokens.primary;
    }

    // Unselected state text color
    if (isDark) {
      return AppColorTokens.darkTextPrimary;
    } else {
      return AppColorTokens.textPrimary;
    }
  }

  /// Gets the border based on variant, selection state, and theme mode.
  Border? _getBorder(bool isDark) {
    // Selected state border
    if (selected &&
        (variant == ChipVariant.selectable || variant == ChipVariant.filter)) {
      return Border.all(color: AppColorTokens.primary, width: 1.5);
    }

    // Unselected state border
    return Border.all(
      color: isDark ? AppColorTokens.darkBorder : AppColorTokens.border,
      width: 1,
    );
  }
}
