import 'package:flutter/material.dart';

import '../../tokens/color_tokens.dart';
import '../../tokens/component_tokens.dart';
import '../../tokens/spacing_tokens.dart';
import '../button.dart';

/// Consistent no-data state with an optional recovery action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAction = actionLabel != null && onAction != null;

    return Semantics(
      liveRegion: true,
      label: '$title. $description',
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColorTokens.darkSurfaceElevated
                        : AppColorTokens.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.dialog),
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: AppColorTokens.primary,
                  ),
                ),
                SizedBox(height: AppSpacingTokens.sectionSpacing),
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
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColorTokens.darkTextSecondary
                        : AppColorTokens.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
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
        ),
      ),
    );
  }
}
