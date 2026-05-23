import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class ConditionsCard extends StatelessWidget {
  final List<String> conditions;

  const ConditionsCard({required this.conditions, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.errorSoft),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information_rounded,
                color: AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Tình trạng cần theo dõi',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...conditions.map(
            (condition) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      condition,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
