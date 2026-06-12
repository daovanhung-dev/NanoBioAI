import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/presentation/models/dashboard_mock_stats.dart';
import 'package:nano_app/features/dashboard/presentation/utils/dashboard_helpers.dart';

import 'stat_card.dart';
import 'stat_item.dart';

class QuickStatsGrid extends StatelessWidget {
  final double weightKg;
  final double heightCm;

  const QuickStatsGrid({
    required this.weightKg,
    required this.heightCm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatItem(
        icon: Icons.local_fire_department_rounded,
        label: 'Năng lượng',
        value: DashboardMockStats.calories.toInt().toString(),
        unit: 'kcal',
        color: const Color(0xFFF97316),
        bgColor: const Color(0xFFFFF7ED),
        progress: DashboardMockStats.calories / DashboardMockStats.caloriesGoal,
      ),
      StatItem(
        icon: Icons.water_drop_rounded,
        label: 'Nước',
        value: DashboardMockStats.waterLiters.toStringAsFixed(1),
        unit: 'lít',
        color: const Color(0xFF06B6D4),
        bgColor: const Color(0xFFECFEFF),
        progress: DashboardMockStats.waterLiters / DashboardMockStats.waterGoal,
      ),
      StatItem(
        icon: Icons.bedtime_rounded,
        label: 'Giấc ngủ',
        value: DashboardMockStats.sleepHours.toStringAsFixed(1),
        unit: 'giờ',
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
        progress: DashboardMockStats.sleepHours / DashboardMockStats.sleepGoal,
      ),
      StatItem(
        icon: Icons.directions_walk_rounded,
        label: 'Bước chân',
        value: formatSteps(DashboardMockStats.steps),
        unit: 'bước',
        color: const Color(0xFF3B82F6),
        bgColor: AppColors.primarySoft,
        progress: DashboardMockStats.steps / DashboardMockStats.stepsGoal,
      ),
      StatItem(
        icon: Icons.favorite_rounded,
        label: 'Nhịp tim',
        value: '${DashboardMockStats.heartRate}',
        unit: 'bpm',
        color: const Color(0xFFEF4444),
        bgColor: AppColors.errorSoft,
        progress: 1 - (DashboardMockStats.heartRate - 60) / 100,
      ),
      StatItem(
        icon: Icons.psychology_rounded,
        label: 'Stress',
        value: '${DashboardMockStats.stress.toInt()}',
        unit: 'điểm',
        color: const Color(0xFFF59E0B),
        bgColor: AppColors.warningSoft,
        progress: 1 - DashboardMockStats.stress / 100,
      ),
      StatItem(
        icon: Icons.monitor_weight_rounded,
        label: 'Cân nặng',
        value: weightKg.toStringAsFixed(1),
        unit: 'kg',
        color: const Color(0xFF10B981),
        bgColor: AppColors.successSoft,
        progress: 0.78,
      ),
      StatItem(
        icon: Icons.height_rounded,
        label: 'Chiều cao',
        value: heightCm.toStringAsFixed(0),
        unit: 'cm',
        color: AppColors.secondary,
        bgColor: const Color(0xFFECFEFF),
        progress: 1.0,
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.78,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => StatCard(stat: stats[i]),
    );
  }
}
