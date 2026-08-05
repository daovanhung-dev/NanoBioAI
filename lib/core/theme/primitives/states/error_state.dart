import 'package:flutter/material.dart';

import '../../tokens/color_tokens.dart';
import '../../tokens/component_tokens.dart';
import '../../tokens/spacing_tokens.dart';
import '../button.dart';

/// Consistent user-safe error state with an optional retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Thử lại',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      liveRegion: true,
      label: 'Có lỗi. $message',
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
                    color: AppColorTokens.errorLight,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.dialog),
                  ),
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    size: 48,
                    color: AppColorTokens.error,
                  ),
                ),
                SizedBox(height: AppSpacingTokens.sectionSpacing),
                Text(
                  'Nabi cần thử lại một chút',
                  style: AppTextStyles.heading2.copyWith(
                    color: isDark
                        ? AppColorTokens.darkTextPrimary
                        : AppColorTokens.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacingTokens.itemSpacing),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColorTokens.darkTextSecondary
                        : AppColorTokens.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  SizedBox(height: AppSpacingTokens.sectionSpacing),
                  AppButton(
                    variant: ButtonVariant.primary,
                    onPressed: onRetry,
                    child: Text(retryLabel),
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
