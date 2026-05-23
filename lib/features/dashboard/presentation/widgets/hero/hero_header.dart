import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/presentation/models/dashboard_mock_stats.dart';
import 'package:nano_app/features/dashboard/presentation/utils/dashboard_helpers.dart';

import 'header_stat_pill.dart';

class HeroHeader extends StatelessWidget {
  final String name;
  final double bmi;
  final AnimationController pulseAnimation;

  const HeroHeader({
    required this.name,
    required this.bmi,
    required this.pulseAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = greetingMessage(DateTime.now());
    final bmiStatusText = bmiStatus(bmi);
    final bmiColorValue = bmiStatusColor(bmi);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: AppGradients.custom(
          colors: const [
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
            Color(0xFF0EA5E9),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          ...AppShadows.primary,
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.12 + pulseAnimation.value * 0.06,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.07 + pulseAnimation.value * 0.04,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 120,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.05 + pulseAnimation.value * 0.03,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              72,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (_, child) => Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.5 + pulseAnimation.value * 0.3,
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(
                                0.1 + pulseAnimation.value * 0.1,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: AppShadows.sm,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF4ADE80,
                                ).withOpacity(0.7 + pulseAnimation.value * 0.3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: AppTypography.semiBold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  greeting,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: AppTypography.regular,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.extraBold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const HeaderStatPill(
                      icon: Icons.monitor_heart_rounded,
                      label: '${DashboardMockStats.heartRate} bpm',
                      active: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    HeaderStatPill(
                      icon: Icons.bloodtype_rounded,
                      label:
                          '${DashboardMockStats.oxygenSat.toStringAsFixed(1)}% SpO₂',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bmiColorValue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        border: Border.all(
                          color: bmiColorValue.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            color: bmiColorValue,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BMI ${bmi.toStringAsFixed(1)} · $bmiStatusText',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: bmiColorValue,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
