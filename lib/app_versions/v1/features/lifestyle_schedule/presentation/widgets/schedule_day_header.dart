import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/design_system.dart';

import '../controllers/lifestyle_schedule_state.dart';

class ScheduleDayHeader extends StatelessWidget {
  const ScheduleDayHeader({super.key, required this.state});

  final LifestyleScheduleState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.totalItems == 0
        ? 0.0
        : (state.score / 100).clamp(0.0, 1.0).toDouble();
    final title = state.isSelectedToday
        ? 'Lịch chăm sóc hôm nay'
        : 'Lịch chăm sóc đã chọn';

    return AppCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScheduleProgressRing(progress: progress),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(state.selectedDate),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColorTokens.primary,
                  ),
                ),
                const SizedBox(height: AppSpacingTokens.itemSpacing),
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacingTokens.itemSpacing),
                Text(
                  '${state.completedItems}/${state.totalItems} đã hoàn thành • ${state.score.round()} điểm',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.summary.fullName.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacingTokens.itemSpacing),
                  Text(
                    state.summary.fullName.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleProgressRing extends StatelessWidget {
  const _ScheduleProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tiến độ ${(progress * 100).round()} phần trăm',
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: AppColorTokens.primary.withValues(alpha: .12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= .96
                      ? AppColorTokens.success
                      : AppColorTokens.primary,
                ),
              ),
            ),
            Icon(
              progress >= .96
                  ? Icons.verified_rounded
                  : Icons.calendar_today_rounded,
              size: 22,
              color: progress >= .96
                  ? AppColorTokens.success
                  : AppColorTokens.primary,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  final weekday = weekdays[date.weekday - 1];
  return '$weekday, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
