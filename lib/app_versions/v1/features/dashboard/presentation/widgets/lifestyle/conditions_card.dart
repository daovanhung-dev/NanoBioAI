import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class ConditionsCard extends StatelessWidget {
  final List<String> conditions;

  const ConditionsCard({required this.conditions, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semanticColors.errorSoft),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_information_rounded,
                color: context.semanticColors.error,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.tiny),
              Text(
                'Tình trạng cần theo dõi',
                style: AppTextStyles.labelLarge.copyWith(
                  color: context.semanticColors.error,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...conditions.map(
            (condition) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.tiny),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.semanticColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      condition,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.semanticColors.textPrimary,
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
