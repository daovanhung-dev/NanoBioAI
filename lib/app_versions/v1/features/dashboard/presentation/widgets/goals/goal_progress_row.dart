import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'goal_data.dart';

class GoalProgressRow extends StatelessWidget {
  final GoalData goal;

  const GoalProgressRow({required this.goal, super.key});

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(goal.icon, color: goal.color, size: 15),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                goal.label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
            Text(
              '${goal.current.toInt()} / ${goal.target.toInt()} ${goal.unit}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: goal.color,
                  fontWeight: AppTypography.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
            ),
            FractionallySizedBox(
              widthFactor: goal.progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [goal.color.withValues(alpha: 0.7), goal.color],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  boxShadow: [
                    BoxShadow(
                      color: goal.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
