import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/design_system.dart';

import '../controllers/lifestyle_schedule_state.dart';

class ScheduleProgressSummary extends StatelessWidget {
  const ScheduleProgressSummary({super.key, required this.state});

  final LifestyleScheduleState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.totalItems == 0
        ? 0.0
        : (state.score / 100).clamp(0.0, 1.0).toDouble();
    final remaining = (state.totalItems - state.completedItems)
        .clamp(0, state.totalItems)
        .toInt();

    return AppCard(
      variant: CardVariant.defaultCard,
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiến độ',
                  style: AppTextStyles.heading4.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${state.score.round()}%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColorTokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacing),
          Text(
            state.totalItems == 0
                ? 'Ngày này chưa có nhiệm vụ.'
                : '${state.completedItems}/${state.totalItems} nhiệm vụ đã hoàn thành',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColorTokens.primary.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= .96
                    ? AppColorTokens.success
                    : AppColorTokens.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          Text(
            _supportingMessage(
              isToday: state.isSelectedToday,
              total: state.totalItems,
              completed: state.completedItems,
              remaining: remaining,
            ),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _supportingMessage({
  required bool isToday,
  required int total,
  required int completed,
  required int remaining,
}) {
  if (total == 0) {
    return 'Khi kế hoạch có dữ liệu, Nabi sẽ sắp các mốc theo thời gian tại đây.';
  }
  if (remaining == 0) {
    return isToday
        ? 'Bạn đã hoàn thành các mốc chăm sóc hôm nay.'
        : 'Các mốc của ngày này đã được hoàn thành.';
  }
  if (completed == 0) {
    return isToday
        ? 'Bắt đầu từ mốc phù hợp với thời gian hiện tại nhé.'
        : 'Ngày này còn $remaining mốc chưa hoàn thành.';
  }
  return isToday
      ? 'Còn $remaining việc nhỏ. Bạn cứ giữ nhịp nhẹ nhàng.'
      : 'Ngày này còn $remaining mốc chưa hoàn thành.';
}
