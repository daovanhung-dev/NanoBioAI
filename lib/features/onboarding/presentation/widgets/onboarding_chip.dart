import 'package:flutter/material.dart';

class OnboardingChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const OnboardingChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = selected ? theme.colorScheme.primary : theme.colorScheme.surface;
    final fgColor = selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Text(
          '$emoji  $label',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
