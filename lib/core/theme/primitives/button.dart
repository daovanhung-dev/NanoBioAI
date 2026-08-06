import 'package:flutter/material.dart';

import '../../feedback/app_feedback_service.dart';
import '../../feedback/app_feedback_type.dart';
import '../../motion/app_motion_scope.dart';
import '../app_motion.dart';
import '../app_text_styles.dart';
import '../tokens/color_tokens.dart';
import '../tokens/component_tokens.dart';
import '../tokens/spacing_tokens.dart';

enum ButtonVariant { primary, secondary, text, icon, outlined }

/// Canonical Kinetic Aura button.
///
/// The public API remains compatible with the previous primitive while press,
/// loading and semantic feedback are now shared across all surfaces.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.variant,
    required this.onPressed,
    this.child,
    this.icon,
    this.loading = false,
    this.feedbackType,
    this.semanticLabel,
  });

  final ButtonVariant variant;
  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final bool loading;
  final AppFeedbackType? feedbackType;
  final String? semanticLabel;

  bool get _isDisabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = variant == ButtonVariant.icon
        ? _buildIconButton(context, isDark)
        : _buildStandardButton(context, isDark);

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: semanticLabel,
      child: AppPressScale(
        enabled: !_isDisabled,
        pressedScale: AppMotionTokens.buttonPressedScale,
        child: button,
      ),
    );
  }

  VoidCallback? get _effectiveOnPressed {
    if (_isDisabled) return null;
    return () {
      AppFeedbackService.instance.emit(
        feedbackType ??
            (variant == ButtonVariant.primary
                ? AppFeedbackType.primaryAction
                : AppFeedbackType.selection),
      );
      onPressed?.call();
    };
  }

  Widget _buildStandardButton(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: AppMotionScope.duration(context, AppMotionTokens.button),
      curve: AppMotionTokens.defaultCurve,
      constraints: const BoxConstraints(
        minHeight: AppSpacingTokens.buttonMinHeight,
      ),
      child: Material(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
        elevation: _getElevation(),
        shadowColor: AppColorTokens.primary.withValues(alpha: 0.22),
        child: InkWell(
          onTap: _effectiveOnPressed,
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
              child: AppStateSwitcher(
                child: loading
                    ? SizedBox(
                        key: const ValueKey('app-button-loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getLoadingIndicatorColor(isDark),
                          ),
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('app-button-content'),
                        child: DefaultTextStyle(
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _getTextColor(isDark),
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: AppMotionScope.duration(context, AppMotionTokens.button),
      curve: AppMotionTokens.defaultCurve,
      constraints: const BoxConstraints(
        minWidth: AppSpacingTokens.touchTargetMin,
        minHeight: AppSpacingTokens.touchTargetMin,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
        child: InkWell(
          onTap: _effectiveOnPressed,
          borderRadius: BorderRadius.circular(AppRadiusTokens.button),
          child: Center(
            child: AppStateSwitcher(
              child: loading
                  ? SizedBox(
                      key: const ValueKey('app-icon-button-loading'),
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
                  : Icon(
                      icon,
                      key: const ValueKey('app-icon-button-content'),
                      color: _getIconColor(isDark),
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (_isDisabled) {
      return isDark
          ? AppColorTokens.darkBorder.withValues(alpha: 0.3)
          : AppColorTokens.border.withValues(alpha: 0.5);
    }
    return switch (variant) {
      ButtonVariant.primary => AppColorTokens.primary,
      ButtonVariant.secondary => isDark
          ? AppColorTokens.darkSurfaceElevated
          : AppColorTokens.surface,
      ButtonVariant.text ||
      ButtonVariant.outlined ||
      ButtonVariant.icon => Colors.transparent,
    };
  }

  Color _getTextColor(bool isDark) {
    if (_isDisabled) {
      return isDark ? AppColorTokens.darkTextMuted : AppColorTokens.textMuted;
    }
    return switch (variant) {
      ButtonVariant.primary => AppColorTokens.textInverse,
      ButtonVariant.secondary || ButtonVariant.outlined => isDark
          ? AppColorTokens.darkTextPrimary
          : AppColorTokens.textPrimary,
      ButtonVariant.text => AppColorTokens.primary,
      ButtonVariant.icon => isDark
          ? AppColorTokens.darkTextPrimary
          : AppColorTokens.textPrimary,
    };
  }

  Color _getIconColor(bool isDark) {
    if (_isDisabled) {
      return isDark ? AppColorTokens.darkTextMuted : AppColorTokens.textMuted;
    }
    return isDark ? AppColorTokens.darkTextPrimary : AppColorTokens.textPrimary;
  }

  Color _getBorderColor(bool isDark) {
    if (_isDisabled) {
      return isDark ? AppColorTokens.darkBorder : AppColorTokens.border;
    }
    return isDark
        ? AppColorTokens.darkBorderStrong
        : AppColorTokens.borderStrong;
  }

  Color _getLoadingIndicatorColor(bool isDark) {
    return switch (variant) {
      ButtonVariant.primary => AppColorTokens.textInverse,
      ButtonVariant.secondary ||
      ButtonVariant.outlined ||
      ButtonVariant.text => AppColorTokens.primary,
      ButtonVariant.icon => isDark
          ? AppColorTokens.darkTextPrimary
          : AppColorTokens.textPrimary,
    };
  }

  double _getElevation() {
    if (_isDisabled) return 0;
    return switch (variant) {
      ButtonVariant.primary => 1.5,
      ButtonVariant.secondary => 0.5,
      ButtonVariant.text ||
      ButtonVariant.outlined ||
      ButtonVariant.icon => 0,
    };
  }
}
