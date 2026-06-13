import 'package:flutter/material.dart';
import '../../tokens/color_tokens.dart';
import '../../tokens/spacing_tokens.dart';
import '../../tokens/component_tokens.dart';
import '../button.dart';

/// A primitive empty state component for displaying empty or no-data screens.
///
/// `EmptyState` is a Layer 3 primitive component that provides consistent
/// empty state displays with icon, title, description, and optional action.
///
/// ## Basic Usage
///
/// ```dart
/// EmptyState(
///   icon: Icons.inbox,
///   title: 'No Items',
///   description: 'You don\'t have any items yet.',
/// )
/// ```
///
/// ## With Action Button
///
/// ```dart
/// EmptyState(
///   icon: Icons.add_circle_outline,
///   title: 'No Meal Plans',
///   description: 'Create your first AI-generated meal plan.',
///   actionLabel: 'Create Plan',
///   onAction: () {
///     // Navigate to create meal plan
///   },
/// )
/// ```
///
/// ## Token-Based Styling
///
/// All styling references semantic tokens:
/// - Colors: [AppColorTokens]
/// - Spacing: [AppSpacingTokens]
/// - Text: [AppTextStyles]
///
/// **Validates: Requirements 4.7, 4.10, 4.11**
class EmptyState extends StatelessWidget {
  /// Creates an empty state with icon, title, description, and optional action.
  ///
  /// The [icon], [title], and [description] are required to create a meaningful empty state.
  /// The [actionLabel] and [onAction] create an optional action button.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  /// Icon to display above the title.
  final IconData icon;

  /// Main heading text explaining the empty state.
  final String title;

  /// Detailed description text providing more context.
  final String description;

  /// Optional action button label.
  ///
  /// Requires [onAction] to be provided.
  final String? actionLabel;

  /// Callback triggered when the action button is pressed.
  ///
  /// Required if [actionLabel] is provided.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              icon,
              size: 80,
              color: isDark
                  ? AppColorTokens.darkTextMuted
                  : AppColorTokens.textMuted,
            ),
            SizedBox(height: AppSpacingTokens.sectionSpacing),
            // Title
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                color: isDark
                    ? AppColorTokens.darkTextPrimary
                    : AppColorTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacingTokens.itemSpacing),
            // Description
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColorTokens.darkTextSecondary
                    : AppColorTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            // Action button
            if (hasAction) ...[
              SizedBox(height: AppSpacingTokens.sectionSpacing),
              AppButton(
                variant: ButtonVariant.primary,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
