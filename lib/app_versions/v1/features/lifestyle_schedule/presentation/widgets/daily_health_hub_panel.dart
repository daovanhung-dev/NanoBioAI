import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';

import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/lifestyle_schedule_state.dart';
import 'daily_health_quick_checkin_sheet.dart';
import 'manual_health_task_sheet.dart';

class DailyHealthHubPanel extends ConsumerWidget {
  final LifestyleScheduleState state;

  const DailyHealthHubPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dailyHealthSnapshotProvider(state.selectedDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngày của tôi', style: AppTextStyles.heading2),
                  const SizedBox(height: 4),
                  Text(
                    'Theo dõi những việc nhỏ tạo nên một ngày chăm sóc trọn vẹn.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => unawaited(
                showManualHealthTaskSheet(
                  context: context,
                  ref: ref,
                  initialDate: state.selectedDate,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        snapshot.when(
          loading: () => const _SnapshotLoading(),
          error: (_, __) => _SnapshotError(
            onRetry: () => ref.invalidate(
              dailyHealthSnapshotProvider(state.selectedDate),
            ),
          ),
          data: (value) => _SnapshotGrid(snapshot: value),
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        _QuickActions(date: state.selectedDate),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        snapshot.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (value) => _NabiDailyInsight(state: state, snapshot: value),
        ),
      ],
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  final DailyHealthSnapshotEntity snapshot;

  const _SnapshotGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final items = <_SnapshotItem>[
      _SnapshotItem(
        icon: Icons.water_drop_rounded,
        label: 'Nước',
        value: '${snapshot.waterMl} ml',
        color: AppColorTokens.info,
      ),
      _SnapshotItem(
        icon: Icons.mood_rounded,
        label: 'Cảm xúc',
        value: snapshot.moodLabel,
        color: AppColorTokens.tertiary,
      ),
      _SnapshotItem(
        icon: Icons.bedtime_rounded,
        label: 'Giấc ngủ',
        value: snapshot.sleepHours == null
            ? 'Chưa ghi'
            : '${_decimal(snapshot.sleepHours!)} giờ',
        color: AppColorTokens.primaryHover,
      ),
      _SnapshotItem(
        icon: Icons.monitor_weight_outlined,
        label: 'Cân nặng',
        value: snapshot.weightKg == null
            ? 'Chưa ghi'
            : '${_decimal(snapshot.weightKg!)} kg',
        color: AppColorTokens.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final width =
            (constraints.maxWidth -
                (columns - 1) * AppSpacingTokens.itemSpacing) /
            columns;
        return Wrap(
          spacing: AppSpacingTokens.itemSpacing,
          runSpacing: AppSpacingTokens.itemSpacing,
          children: items
              .map((item) => SizedBox(width: width, child: _SnapshotCard(item: item)))
              .toList(growable: false),
        );
      },
    );
  }

  String _decimal(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _SnapshotItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SnapshotItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _SnapshotCard extends StatelessWidget {
  final _SnapshotItem item;

  const _SnapshotCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 20, color: item.color),
          const SizedBox(height: AppSpacingTokens.itemSpacing),
          Text(item.value, style: AppTextStyles.labelLarge),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  final DateTime date;

  const _QuickActions({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ghi nhanh', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacingTokens.itemSpacing),
        Wrap(
          spacing: AppSpacingTokens.itemSpacing,
          runSpacing: AppSpacingTokens.itemSpacing,
          children: [
            _QuickChip(
              icon: Icons.water_drop_rounded,
              label: 'Uống nước',
              onTap: () => _open(
                context,
                ref,
                ScheduleHealthActionType.hydration,
              ),
            ),
            _QuickChip(
              icon: Icons.sentiment_satisfied_alt_rounded,
              label: 'Cảm xúc',
              onTap: () => _open(
                context,
                ref,
                ScheduleHealthActionType.moodStress,
              ),
            ),
            _QuickChip(
              icon: Icons.bedtime_rounded,
              label: 'Giấc ngủ',
              onTap: () => _open(
                context,
                ref,
                ScheduleHealthActionType.sleepCheckIn,
              ),
            ),
            _QuickChip(
              icon: Icons.monitor_weight_outlined,
              label: 'Cân nặng',
              onTap: () => _open(
                context,
                ref,
                ScheduleHealthActionType.weightCheckIn,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    ScheduleHealthActionType action,
  ) {
    unawaited(
      showDailyHealthQuickCheckInSheet(
        context: context,
        ref: ref,
        date: date,
        action: action,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _NabiDailyInsight extends StatelessWidget {
  final LifestyleScheduleState state;
  final DailyHealthSnapshotEntity snapshot;

  const _NabiDailyInsight({required this.state, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final message = _message();
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: AppColorTokens.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: AppColorTokens.primary.withValues(alpha: .16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColorTokens.primary),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nabi gợi ý', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodyMedium.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _message() {
    if (state.totalItems == 0) {
      return 'Hôm nay chưa có mốc trong lịch. Bạn có thể thêm một nhiệm vụ nhỏ phù hợp với nhịp sống của mình.';
    }
    if (state.completedItems == state.totalItems) {
      return 'Bạn đã hoàn thành toàn bộ mốc của ngày này. Duy trì nhịp đều quan trọng hơn việc cố làm thật nhiều.';
    }
    if (snapshot.waterMl == 0 && state.isSelectedToday) {
      return 'Hôm nay chưa có ghi nhận nước. Nếu bạn vừa uống nước, có thể cập nhật nhanh ngay tại đây.';
    }
    if (!snapshot.hasMood && state.isSelectedToday) {
      return 'Một check-in cảm xúc ngắn có thể giúp bạn nhìn lại ngày hôm nay rõ hơn.';
    }
    return 'Bạn đã hoàn thành ${state.completedItems}/${state.totalItems} mốc. Chọn nhiệm vụ gần nhất để tiếp tục theo nhịp của mình.';
  }
}

class _SnapshotLoading extends StatelessWidget {
  const _SnapshotLoading();

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator(minHeight: 3);
  }
}

class _SnapshotError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SnapshotError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Chưa đọc được ghi nhận sức khỏe của ngày này.')),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
