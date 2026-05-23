import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'goal_chip.dart';

class GoalChipsGrid extends StatelessWidget {
  final List<String> goals;

  const GoalChipsGrid({required this.goals, super.key});

  static const _goalIcons = <String, IconData>{
    'Giảm cân': Icons.trending_down_rounded,
    'Tăng cơ': Icons.fitness_center_rounded,
    'Cải thiện giấc ngủ': Icons.bedtime_rounded,
    'Tăng sức bền': Icons.directions_run_rounded,
    'Giảm stress': Icons.spa_rounded,
    'Ăn lành mạnh': Icons.restaurant_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: goals.map((goal) {
        final icon = _goalIcons[goal] ?? Icons.check_circle_rounded;
        return GoalChip(label: goal, icon: icon);
      }).toList(),
    );
  }
}
