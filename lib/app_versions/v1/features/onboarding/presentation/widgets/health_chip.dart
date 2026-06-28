import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Compact health option tile retained for older view call sites.
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
    final color = activeColor ?? NabiPalette.royalBlue;
    return SizedBox(
      width: width,
      height: height ?? 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: Colors.white.withValues(alpha: 0.18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? (gradient ?? NabiPalette.selection)
                  : NabiPalette.card,
              color: selected && gradient == null && activeColor != null
                  ? color
                  : null,
              border: Border.all(
                color: selected ? color : NabiPalette.line,
                width: selected ? 1.3 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null || icon != null) ...[
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.16)
                            : color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: emoji != null
                          ? Text(emoji!, style: const TextStyle(fontSize: 18))
                          : Icon(
                              icon,
                              size: 17,
                              color: selected ? Colors.white : color,
                            ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: selected ? Colors.white : NabiPalette.ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 5), badge!],
                  if (trailing != null) ...[
                    const SizedBox(width: 5),
                    trailing!,
                  ],
                  const SizedBox(width: 5),
                  Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                    color: selected ? Colors.white : NabiPalette.royalBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
