import 'package:flutter/material.dart';

import '../../feedback/app_feedback_service.dart';
import '../../feedback/app_feedback_type.dart';
import '../../motion/app_motion_scope.dart';
import '../app_motion.dart';
import '../tokens/color_tokens.dart';
import '../tokens/component_tokens.dart';
import '../tokens/spacing_tokens.dart';

enum CardVariant { defaultCard, elevated, outlined }

/// Canonical Kinetic Aura card with shared selection and tactile feedback.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.variant,
    required this.child,
    this.onTap,
    this.padding,
    this.selected = false,
    this.feedbackType = AppFeedbackType.selection,
    this.semanticLabel,
  });

  final CardVariant variant;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool selected;
  final AppFeedbackType feedbackType;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePadding =
        padding ?? EdgeInsets.all(AppSpacingTokens.cardPaddingCompact);

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: AppPressScale(
        enabled: onTap != null,
        pressedScale: AppMotionTokens.cardPressedScale,
        child: AnimatedContainer(
          duration: AppMotionScope.duration(context, AppMotionTokens.card),
          curve: AppMotionTokens.defaultCurve,
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? AppColorTokens.primary.withValues(alpha: 0.18)
                      : AppColorTokens.primaryLight)
                : _getBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            border: selected
                ? Border.all(color: AppColorTokens.primary, width: 1.5)
                : _getBorder(isDark),
            boxShadow: selected
                ? AppShadowTokens.cardElevated
                : _getShadow(isDark),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            child: InkWell(
              onTap: onTap == null
                  ? null
                  : () {
                      AppFeedbackService.instance.emit(feedbackType);
                      onTap?.call();
                    },
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              child: Padding(padding: effectivePadding, child: child),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (isDark) {
      return switch (variant) {
        CardVariant.defaultCard ||
        CardVariant.outlined => AppColorTokens.darkSurface,
        CardVariant.elevated => AppColorTokens.darkSurfaceElevated,
      };
    }
    return AppColorTokens.surface;
  }

  Border _getBorder(bool isDark) {
    return Border.all(
      color: isDark ? AppColorTokens.darkBorder : AppColorTokens.border,
      width: variant == CardVariant.outlined ? 1.2 : 1,
    );
  }

  List<BoxShadow>? _getShadow(bool isDark) {
    return switch (variant) {
      CardVariant.defaultCard || CardVariant.outlined => null,
      CardVariant.elevated =>
        isDark
            ? AppShadowTokens.cardElevatedDark
            : AppShadowTokens.cardElevated,
    };
  }
}
