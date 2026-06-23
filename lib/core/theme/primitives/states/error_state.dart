import 'package:flutter/material.dart';
import '../../tokens/color_tokens.dart';
import '../../tokens/spacing_tokens.dart';
import '../../tokens/component_tokens.dart';
import '../button.dart';

/// A primitive error state component for displaying error screens with retry.
///
/// `ErrorState` is a Layer 3 primitive component that provides consistent
/// error displays with error message and optional retry action.
///
/// ## Basic Usage
///
/// ```dart
/// ErrorState(
///   message: 'Failed to load data',
/// )
/// ```
///
/// ## With Retry Action
///
/// ```dart
/// ErrorState(
///   message: 'Unable to connect to server',
///   onRetry: () {
///     // Retry the failed operation
///   },
/// )
/// ```
///
/// ## With Custom Retry Label
///
/// ```dart
/// ErrorState(
///   message: 'Failed to generate meal plan',
///   retryLabel: 'Try Again',
///   onRetry: () {
///     // Retry generation
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
/// **Validates: Requirements 4.9, 4.10, 4.11**
class ErrorState extends StatelessWidget {
  /// Creates an error state with message and optional retry action.
  ///
  /// The [message] describes the error that occurred.
  /// The [onRetry] callback creates a retry button (optional).
  /// The [retryLabel] customizes the retry button text (defaults to 'Retry').
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Thử lại',
  });

  /// Error message describing what went wrong.
  final String message;

  /// Callback triggered when the retry button is pressed.
  ///
  /// If null, no retry button is shown.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  ///
  /// Defaults to 'Retry'.
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Icon(Icons.error_outline, size: 80, color: AppColorTokens.error),
            SizedBox(height: AppSpacingTokens.sectionSpacing),
            // Error title
            Text(
              'Nabicần thử lại một chút',
              style: AppTextStyles.heading2.copyWith(
                color: isDark
                    ? AppColorTokens.darkTextPrimary
                    : AppColorTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacingTokens.itemSpacing),
            // Error message
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColorTokens.darkTextSecondary
                    : AppColorTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            // Retry button
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
    );
  }
}
