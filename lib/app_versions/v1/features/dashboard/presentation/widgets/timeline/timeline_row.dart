import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'timeline_event.dart';

class TimelineRow extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const TimelineRow({required this.event, required this.isLast, super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                event.time,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontWeight: AppTypography.medium,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: event.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(event.icon, color: event.color, size: 14),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: AppColors.borderLight),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 4,
                bottom: isLast ? 0 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.detail,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
