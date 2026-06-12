import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/presentation/models/dashboard_mock_stats.dart';

import 'conditions_card.dart';
import 'lifestyle_metric_card.dart';

class SmartLifestyleSection extends StatelessWidget {
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;
  final List<String> conditions;

  const SmartLifestyleSection({
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
    required this.conditions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LifestyleMetricCard(
                icon: Icons.bedtime_rounded,
                title: 'Giấc ngủ',
                value: sleepQuality,
                detail: '${DashboardMockStats.sleepHours}h đêm qua',
                color: const Color(0xFF8B5CF6),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: LifestyleMetricCard(
                icon: Icons.directions_run_rounded,
                title: 'Vận động',
                value: activityLevel,
                detail: '${DashboardMockStats.steps} bước',
                color: const Color(0xFF3B82F6),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: LifestyleMetricCard(
                icon: Icons.water_drop_rounded,
                title: 'Nước uống',
                value: waterPerDay,
                detail:
                    '${DashboardMockStats.waterLiters}L / ${DashboardMockStats.waterGoal}L',
                color: const Color(0xFF06B6D4),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: LifestyleMetricCard(
                icon: Icons.psychology_rounded,
                title: 'Stress',
                value: 'Thấp',
                detail: 'Điểm: ${DashboardMockStats.stress.toInt()}/100',
                color: const Color(0xFF22C55E),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
              ),
            ),
          ],
        ),
        if (conditions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ConditionsCard(conditions: conditions),
        ],
      ],
    );
  }
}
