import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'goal_data.dart';
import 'goal_progress_row.dart';

class GoalProgressSection extends StatelessWidget {
  final List<GoalData> goals;

  const GoalProgressSection({required this.goals, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(
          goals.length,
          (i) => Padding(
            padding: EdgeInsets.only(
              bottom: i < goals.length - 1 ? AppSpacing.md : 0,
            ),
            child: GoalProgressRow(goal: goals[i]),
          ),
        ),
      ),
    );
  }
}
