import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

class HealthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;
  final Gradient? gradient;
  final Color? activeColor;
  final bool enabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;
  final Widget? badge;

  const HealthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.gradient,
    this.activeColor,
    this.enabled = true,
    this.width,
    this.height,
    this.padding,
    this.trailing,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? NabiPalette.greenPrimary;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: width,
        height: height ?? 54,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AnimatedContainer(
              duration: AppDuration.ripple,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: selected
                    ? (gradient ??
                        (activeColor == null
                            ? NabiPalette.selection
                            : LinearGradient(colors: [color, color])))
                    : NabiPalette.card,
                border: Border.all(
                  color: selected ? color : NabiPalette.line,
                  width: selected ? 1.3 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.45,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null)
                      Text(emoji!, style: const TextStyle(fontSize: 18))
                    else if (icon != null)
                      Icon(icon, size: 18, color: selected ? AppColors.surface : color),
                    if (emoji != null || icon != null) const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected ? AppColors.surface : NabiPalette.ink,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: AppSpacing.xs), badge!],
                    if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
                    const SizedBox(width: AppSpacing.tiny),
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 19,
                      color: selected ? AppColors.surface : color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
