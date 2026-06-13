import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/component_tokens.dart';
import 'button.dart';

/// A primitive section header component for grouping content with optional action.
///
/// `SectionHeader` is a Layer 3 primitive component that provides consistent
/// section headers with title, optional subtitle, and optional action button.
///
/// ## Basic Usage
///
/// ```dart
/// SectionHeader(
///   title: 'Health Goals',
/// )
/// ```
///
/// ## With Subtitle
///
/// ```dart
/// SectionHeader(
///   title: 'Meal Plan',
///   subtitle: '7-day personalized nutrition plan',
/// )
/// ```
///
/// ## With Action Button
///
/// ```dart
/// SectionHeader(
///   title: 'Recent Activities',
///   actionLabel: 'View All',
///   onAction: () {
///     // Navigate to full list
///   },
/// )
/// ```
///
/// ## Full Example
///
/// ```dart
/// SectionHeader(
///   title: 'Health Metrics',
///   subtitle: 'Track your progress',
///   actionLabel: 'Edit',
///   onAction: () {
///     // Edit metrics
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
/// **Validates: Requirements 4.6, 4.10, 4.11**
class SectionHeader extends StatelessWidget {
  /// Creates a section header with title and optional subtitle and action.
  ///
  /// The [title] is required and displayed as the main heading.
  /// The [subtitle] provides additional context (optional).
  /// The [actionLabel] and [onAction] create an action button (both required for action).
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// The main heading text for the section.
  final String title;

  /// Optional subtitle text providing additional context.
  final String? subtitle;

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

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingTokens.sectionSpacing),
      child: Row(
        children: [
          // Title and subtitle column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(
                    color: isDark
                        ? AppColorTokens.darkTextPrimary
                        : AppColorTokens.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacingTokens.itemSpacing / 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColorTokens.darkTextSecondary
                          : AppColorTokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action button
          if (hasAction) ...[
            SizedBox(width: AppSpacingTokens.itemSpacing),
            AppButton(
              variant: ButtonVariant.text,
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
