import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Legacy-compatible selectable chip aligned with the NaBi visual language.
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
    final activeColor = selectedColor ?? NabiPalette.royalBlue;
    final foreground = selected ? Colors.white : NabiPalette.ink;

    return SizedBox(
      width: width,
      height: height ?? 54,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: enabled ? onTap : null,
          splashColor: Colors.white.withValues(alpha: 0.18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: selected
                  ? (selectedGradient ?? NabiPalette.selection)
                  : NabiPalette.card,
              color:
                  selected && selectedGradient == null && selectedColor != null
                  ? activeColor
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? activeColor : NabiPalette.line,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.20),
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
                  Container(
                    width: 29,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.16)
                          : NabiPalette.royalBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: icon != null
                        ? Icon(
                            icon,
                            size: 17,
                            color: selected ? Colors.white : activeColor,
                          )
                        : Text(emoji, style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: description == null ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
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
