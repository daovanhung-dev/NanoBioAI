import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/component_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../app_text_styles.dart';

enum BadgeVariant { status, count, dot }

enum BadgeStatus { success, warning, error, info, neutral }

/// Semantic status and notification indicator.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.variant,
    this.label,
    this.count,
    this.status = BadgeStatus.neutral,
  });

  final BadgeVariant variant;
  final String? label;
  final int? count;
  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semanticLabel = switch (variant) {
      BadgeVariant.status => label ?? 'Trạng thái',
      BadgeVariant.count => '${count ?? 0} thông báo',
      BadgeVariant.dot => 'Có cập nhật mới',
    };

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: _padding,
        constraints: _constraints,
        decoration: BoxDecoration(
          color: _backgroundColor(isDark),
          borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
          border: variant == BadgeVariant.status
              ? Border.all(color: _statusColor(isDark))
              : null,
        ),
        child: _content(isDark),
      ),
    );
  }

  Widget _content(bool isDark) {
    switch (variant) {
      case BadgeVariant.status:
        return Text(
          label ?? '',
          style: AppTextStyles.labelMedium.copyWith(
            color: _statusColor(isDark),
            fontWeight: FontWeight.w700,
          ),
        );
      case BadgeVariant.count:
        return Text(
          count != null && count! > 99 ? '99+' : '${count ?? 0}',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorTokens.textInverse,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        );
      case BadgeVariant.dot:
        return const SizedBox.shrink();
    }
  }

  Color _backgroundColor(bool isDark) {
    switch (variant) {
      case BadgeVariant.status:
        return switch (status) {
          BadgeStatus.success => AppColorTokens.successLight,
          BadgeStatus.warning => AppColorTokens.warningLight,
          BadgeStatus.error => AppColorTokens.errorLight,
          BadgeStatus.info => AppColorTokens.infoLight,
          BadgeStatus.neutral =>
            isDark
                ? AppColorTokens.darkSurface
                : AppColorTokens.surfaceElevated,
        };
      case BadgeVariant.count:
        return AppColorTokens.error;
      case BadgeVariant.dot:
        return _statusColor(isDark);
    }
  }

  Color _statusColor(bool isDark) => switch (status) {
    BadgeStatus.success => AppColorTokens.success,
    BadgeStatus.warning => AppColorTokens.warning,
    BadgeStatus.error => AppColorTokens.error,
    BadgeStatus.info => AppColorTokens.info,
    BadgeStatus.neutral =>
      isDark ? AppColorTokens.darkTextSecondary : AppColorTokens.textMuted,
  };

  EdgeInsets get _padding => switch (variant) {
    BadgeVariant.status => EdgeInsets.symmetric(
      horizontal: AppSpacingTokens.chipPaddingH,
      vertical: AppSpacingTokens.chipPaddingV,
    ),
    BadgeVariant.count => EdgeInsets.symmetric(
      horizontal: AppSpacingTokens.itemSpacing,
      vertical: AppSpacingTokens.itemSpacing / 2,
    ),
    BadgeVariant.dot => EdgeInsets.zero,
  };

  BoxConstraints? get _constraints => switch (variant) {
    BadgeVariant.status => null,
    BadgeVariant.count => const BoxConstraints(minWidth: 24, minHeight: 24),
    BadgeVariant.dot => const BoxConstraints.tightFor(width: 8, height: 8),
  };
}
