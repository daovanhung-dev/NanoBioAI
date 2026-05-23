import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'stat_item.dart';

class StatCard extends StatelessWidget {
  final StatItem stat;

  const StatCard({required this.stat, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: AppTextStyles.heading4.copyWith(
              fontSize: 15,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            stat.unit,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textHint,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              value: stat.progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: stat.bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(stat.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: AppTextStyles.overline.copyWith(
              fontSize: 9,
              color: AppColors.textHint,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
