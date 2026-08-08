import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/design_system.dart';

class ScheduleDateSelector extends StatelessWidget {
  const ScheduleDateSelector({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.today,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) return const SizedBox.shrink();
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final selectorHeight =
        70.0 + (textScale > 1 ? (textScale - 1) * 44.0 : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Theo ngày',
                style: AppTextStyles.heading4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Flexible(
              child: Text(
                'Vuốt để xem thêm',
                textAlign: TextAlign.end,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        SizedBox(
          height: selectorHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacingTokens.itemSpacing),
            itemBuilder: (context, index) {
              final date = dates[index];
              return _DateButton(
                date: date,
                selected: DateUtils.isSameDay(date, selectedDate),
                isToday: DateUtils.isSameDay(date, today),
                onTap: () => onSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColorTokens.textInverse
        : Theme.of(context).colorScheme.onSurface;
    final muted = selected
        ? AppColorTokens.textInverse.withValues(alpha: .82)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: 'Chọn ${_semanticsDate(date)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          child: AnimatedContainer(
            duration: AppMotionScope.duration(context, AppMotionTokens.button),
            curve: AppMotionTokens.defaultCurve,
            constraints: const BoxConstraints(
              minWidth: AppSpacingTokens.touchTargetMin,
              minHeight: AppSpacingTokens.touchTargetMin,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacingTokens.itemSpacingLarge,
              vertical: AppSpacingTokens.itemSpacing,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColorTokens.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              border: Border.all(
                color: selected
                    ? AppColorTokens.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _shortWeekday(date),
                  style: AppTextStyles.caption.copyWith(color: muted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: AppTextStyles.labelLarge.copyWith(color: foreground),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: AppMotionScope.duration(
                    context,
                    AppMotionTokens.button,
                  ),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? (selected
                              ? AppColorTokens.textInverse
                              : AppColorTokens.success)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _shortWeekday(DateTime date) {
  const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return labels[date.weekday - 1];
}

String _semanticsDate(DateTime date) {
  return '${_shortWeekday(date)}, ngày ${date.day}/${date.month}/${date.year}';
}
