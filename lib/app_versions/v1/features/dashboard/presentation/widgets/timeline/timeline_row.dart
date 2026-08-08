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
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                event.time,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.semanticColors.textHint,
                  fontWeight: AppTypography.medium,
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
                  child: Container(
                    width: 1.5,
                    color: context.semanticColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
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
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    event.detail,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.semanticColors.textSecondary,
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
