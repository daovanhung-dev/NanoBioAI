import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class StressTrackingPage extends StatelessWidget {
  const StressTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecoration.card(
                radius: AppRadius.xxl,
                shadows: AppShadows.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      color: AppColors.info,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nabiđang chuẩn bị góc cảm xúc',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading4.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Đây sẽ là nơi bạn ghi lại những ngày căng, những nhịp thở nhẹ và các điều nhỏ giúp mình bình tĩnh hơn.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
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
