import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

class OnboardingChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final double? width;
  final double? height;
  final Gradient? selectedGradient;
  final Color? selectedColor;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;
  final IconData? icon;
  final String? description;

  const OnboardingChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.width,
    this.height,
    this.selectedGradient,
    this.selectedColor,
    this.padding,
    this.trailing,
    this.icon,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedColor ?? NabiPalette.greenPrimary;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: width,
        height: height ?? 52,
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
                    ? (selectedGradient ??
                        (selectedColor == null
                            ? NabiPalette.selection
                            : LinearGradient(colors: [active, active])))
                    : NabiPalette.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: selected ? active : NabiPalette.line,
                  width: selected ? 1.3 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: active.withValues(alpha: 0.20),
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
                    if (icon != null)
                      Icon(icon, size: 18, color: selected ? AppColors.surface : active)
                    else
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: description == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected ? AppColors.surface : NabiPalette.ink,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.tiny),
                      trailing!,
                    ],
                    const SizedBox(width: AppSpacing.tiny),
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 19,
                      color: selected ? AppColors.surface : active,
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
