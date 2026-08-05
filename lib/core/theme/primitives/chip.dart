import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/component_tokens.dart';
import '../tokens/spacing_tokens.dart';

/// Chip variants for different interaction patterns.
enum ChipVariant { selectable, filter, action }

/// Compact selection and action control for NaBi Blue Wellness surfaces.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.variant,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.icon,
  });

  final ChipVariant variant;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppMotionTokens.card,
        curve: AppMotionTokens.defaultCurve,
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: _backgroundColor(isDark),
          borderRadius: BorderRadius.circular(AppRadiusTokens.chip),
          border: _border(isDark),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadiusTokens.chip),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadiusTokens.chip),
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacingTokens.chipPaddingH,
                right: onDeleted == null
                    ? AppSpacingTokens.chipPaddingH
                    : AppSpacingTokens.itemSpacing,
                top: AppSpacingTokens.chipPaddingV,
                bottom: AppSpacingTokens.chipPaddingV,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: _textColor(isDark)),
                    SizedBox(width: AppSpacingTokens.iconTextSpacing),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _textColor(isDark),
                      ),
                    ),
                  ),
                  if (selected) ...[
                    SizedBox(width: AppSpacingTokens.iconTextSpacing),
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: _textColor(isDark),
                    ),
                  ],
                  if (onDeleted != null) ...[
                    SizedBox(width: AppSpacingTokens.itemSpacing),
                    Semantics(
                      button: true,
                      label: 'Xóa $label',
                      child: InkResponse(
                        onTap: onDeleted,
                        radius: AppSpacingTokens.touchTargetMin / 2,
                        child: SizedBox.square(
                          dimension: AppSpacingTokens.touchTargetMin,
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: _textColor(isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _usesSelectionState =>
      variant == ChipVariant.selectable || variant == ChipVariant.filter;

  Color _backgroundColor(bool isDark) {
    if (selected && _usesSelectionState) {
      return isDark
          ? AppColorTokens.primary.withValues(alpha: 0.20)
          : AppColorTokens.primaryLight;
    }
    return isDark
        ? AppColorTokens.darkSurface
        : AppColorTokens.surfaceElevated;
  }

  Color _textColor(bool isDark) {
    if (selected && _usesSelectionState) {
      return AppColorTokens.primary;
    }
    return isDark
        ? AppColorTokens.darkTextPrimary
        : AppColorTokens.textPrimary;
  }

  Border _border(bool isDark) {
    if (selected && _usesSelectionState) {
      return Border.all(color: AppColorTokens.primary, width: 1.5);
    }
    return Border.all(
      color: isDark ? AppColorTokens.darkBorder : AppColorTokens.border,
    );
  }
}
