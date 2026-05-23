import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/presentation/models/dashboard_mock_stats.dart';
import 'package:nano_app/features/dashboard/presentation/utils/dashboard_helpers.dart';

import 'score_metric_row.dart';
import 'score_ring_painter.dart';

class HealthScoreCard extends StatelessWidget {
  final double bmi;
  final String sleepQuality;
  final String activityLevel;
  final Animation<double> scoreAnimation;
  final AnimationController pulseAnimation;

  const HealthScoreCard({
    required this.bmi,
    required this.sleepQuality,
    required this.activityLevel,
    required this.scoreAnimation,
    required this.pulseAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.custom(
          colors: const [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI Health Score',
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  'Excellent',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF4ADE80),
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: scoreAnimation,
                  builder: (_, __) => CustomPaint(
                    painter: ScoreRingPainter(
                      progress: scoreAnimation.value,
                      pulseValue: pulseAnimation.value,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(scoreAnimation.value * 100).toInt()}',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.black,
                              fontSize: 36,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScoreMetricRow(
                      icon: Icons.speed_rounded,
                      label: 'BMI',
                      value: bmi.toStringAsFixed(1),
                      color: bmiMetricColor(bmi),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ScoreMetricRow(
                      icon: Icons.bedtime_rounded,
                      label: 'Giấc ngủ',
                      value: sleepQuality,
                      color: const Color(0xFF818CF8),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ScoreMetricRow(
                      icon: Icons.directions_run_rounded,
                      label: 'Vận động',
                      value: activityLevel,
                      color: const Color(0xFF34D399),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ScoreMetricRow(
                      icon: Icons.favorite_rounded,
                      label: 'Nhịp tim',
                      value: '${DashboardMockStats.heartRate} bpm',
                      color: const Color(0xFFF87171),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ScoreMetricRow(
                      icon: Icons.water_drop_rounded,
                      label: 'Nước',
                      value: '${DashboardMockStats.waterLiters}L',
                      color: const Color(0xFF38BDF8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF4ADE80),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Tăng 12% so với tuần trước',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Text(
                  '+12%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF4ADE80),
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
