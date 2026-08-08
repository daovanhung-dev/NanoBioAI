import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class GoalChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const GoalChip({required this.label, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.semanticColors.primarySoft,
            context.semanticColors.secondarySoft,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(
          color: context.semanticColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.semanticColors.primary, size: 14),
          const SizedBox(width: AppSpacing.tiny),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: context.semanticColors.primaryDark,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}
