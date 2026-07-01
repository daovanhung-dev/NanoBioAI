import 'package:flutter/material.dart';
import '../../tokens/color_tokens.dart';
import '../../tokens/spacing_tokens.dart';
import '../../tokens/component_tokens.dart';

/// Loading state variants for different loading patterns.
///
/// Each variant serves a specific purpose:
/// - **spinner**: Standard circular progress indicator
/// - **skeleton**: Placeholder skeleton UI (future implementation)
/// - **shimmer**: Animated shimmer effect (future implementation)
///
/// **Validates: Requirements 4.8, 8.1**
enum LoadingVariant {
  /// Standard circular progress indicator
  spinner,

  /// Placeholder skeleton UI (future implementation)
  skeleton,

  /// Animated shimmer effect (future implementation)
  shimmer,
}

/// A primitive loading state component for displaying loading indicators.
///
/// `LoadingState` is a Layer 3 primitive component that provides consistent
/// loading displays with optional message.
///
/// ## Basic Usage
///
/// ```dart
/// LoadingState(
///   variant: LoadingVariant.spinner,
/// )
/// ```
///
/// ## With Message
///
/// ```dart
/// LoadingState(
///   variant: LoadingVariant.spinner,
///   message: 'Loading meal plan...',
/// )
/// ```
///
/// ## In Widget
///
/// ```dart
/// if (isLoading)
///   LoadingState(
///     variant: LoadingVariant.spinner,
///     message: 'Generating AI recommendations...',
///   )
/// else
///   ContentWidget()
/// ```
///
/// ## Token-Based Styling
///
/// All styling references semantic tokens:
/// - Colors: [AppColorTokens]
/// - Spacing: [AppSpacingTokens]
/// - Text: [AppTextStyles]
///
/// **Validates: Requirements 4.8, 4.10, 4.11**
class LoadingState extends StatelessWidget {
  /// Creates a loading state with the specified variant and optional message.
  ///
  /// The [variant] determines the visual style.
  /// The [message] provides optional context about what is loading.
  const LoadingState({super.key, required this.variant, this.message});

  /// The visual style variant for this loading state.
  final LoadingVariant variant;

  /// Optional message describing what is loading.
  final String? message;

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
            // Loading indicator based on variant
            _buildLoadingIndicator(isDark),
            // Message
            if (message != null) ...[
              SizedBox(height: AppSpacingTokens.sectionSpacing),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColorTokens.darkTextSecondary
                      : AppColorTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the loading indicator based on variant.
  Widget _buildLoadingIndicator(bool isDark) {
    switch (variant) {
      case LoadingVariant.spinner:
        return SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColorTokens.primary),
          ),
        );
      case LoadingVariant.skeleton:
        // TODO: Implement skeleton loading UI
        return _buildPlaceholder(isDark, 'Đang tải khung nội dung');
      case LoadingVariant.shimmer:
        // TODO: Implement shimmer loading effect
        return _buildPlaceholder(isDark, 'Đang tải hiệu ứng chờ');
    }
  }

  /// Builds a placeholder for unimplemented variants.
  Widget _buildPlaceholder(bool isDark, String label) {
    return Container(
      width: 200,
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColorTokens.darkSurface : AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isDark
                ? AppColorTokens.darkTextMuted
                : AppColorTokens.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
