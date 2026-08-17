import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../domain/services/schedule_health_action_policy.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../pages/lifestyle_schedule_health_action_page.dart';
import '../pages/lifestyle_schedule_item_detail_page.dart';
import 'schedule_item_card.dart';

class ScheduleTimeline extends StatelessWidget {
  const ScheduleTimeline({
    super.key,
    required this.items,
    required this.focusedItemId,
    required this.focusedItemKey,
    this.onOpenDetail,
  });

  final List<LifestyleScheduleItemEntity> items;
  final String? focusedItemId;
  final GlobalKey focusedItemKey;
  final ValueChanged<LifestyleScheduleItemEntity>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_rounded,
        title: 'Ngày này chưa có lịch trình',
        description:
            'Khi kế hoạch cá nhân có dữ liệu, các mốc sẽ xuất hiện theo thời gian tại đây.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Dòng thời gian',
          subtitle:
              'Chạm vào một mốc để xem hướng dẫn và cách ghi nhận phù hợp.',
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            key: item.id == focusedItemId
                ? focusedItemKey
                : ValueKey('schedule-item-${item.id}'),
            padding: EdgeInsets.only(
              bottom: index == items.length - 1
                  ? 0
                  : AppSpacingTokens.itemSpacingLarge,
            ),
            child: _ScheduleTimelineRow(
              item: item,
              meta: _ScheduleMeta.from(item.category, item.sourceType),
              isLast: index == items.length - 1,
              highlighted: item.id == focusedItemId,
              onOpenDetail: onOpenDetail,
            ),
          );
        }),
      ],
    );
  }
}

class _ScheduleTimelineRow extends ConsumerWidget {
  const _ScheduleTimelineRow({
    required this.item,
    required this.meta,
    required this.isLast,
    required this.highlighted,
    required this.onOpenDetail,
  });

  final LifestyleScheduleItemEntity item;
  final _ScheduleMeta meta;
  final bool isLast;
  final bool highlighted;
  final ValueChanged<LifestyleScheduleItemEntity>? onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(lifestyleScheduleClockProvider)();
    final status = item.completionStatusAt(now);
    final canToggle = item.isWithinCompletionWindow(now);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineRail(meta: meta, status: status, isLast: isLast),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Semantics(
              button: true,
              hint: 'Mở chi tiết nhiệm vụ',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openDetail(context),
                child: ScheduleItemCard(
                  item: item,
                  categoryIcon: meta.icon,
                  categoryColor: meta.color,
                  categoryLabel: meta.label,
                  status: status,
                  canToggle: canToggle,
                  highlighted: highlighted,
                  onToggle: canToggle ? () => _toggle(context, ref) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    if (onOpenDetail != null) {
      onOpenDetail!(item);
      return;
    }
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    final action = ScheduleHealthActionPolicy.forItem(item);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => action == ScheduleHealthActionType.photoProof
            ? LifestyleScheduleItemDetailPage(initialItem: item)
            : LifestyleScheduleHealthActionPage(initialItem: item),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final action = ScheduleHealthActionPolicy.forItem(item);
    if (action == ScheduleHealthActionType.photoProof) {
      await ref.read(lifestyleScheduleControllerProvider.notifier).toggleItem(item);
      return;
    }

    if (!item.isCompleted && ScheduleHealthActionPolicy.requiresInput(action)) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LifestyleScheduleHealthActionPage(initialItem: item),
        ),
      );
      return;
    }

    final result = item.isCompleted
        ? await ref.read(dailyHealthHubControllerProvider).undoTask(item)
        : await ref.read(dailyHealthHubControllerProvider).completeTask(item: item);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.meta,
    required this.status,
    required this.isLast,
  });

  final _ScheduleMeta meta;
  final CompletionWindowStatus status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _timelineStatusColor(context, status, meta.color);
    final icon = status == CompletionWindowStatus.completed
        ? Icons.check_rounded
        : meta.icon;

    return SizedBox(
      width: 32,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMotionScope.duration(context, AppMotionTokens.button),
            curve: AppMotionTokens.defaultCurve,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .12),
              border: Border.all(color: color.withValues(alpha: .30)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

Color _timelineStatusColor(
  BuildContext context,
  CompletionWindowStatus status,
  Color category,
) {
  return switch (status) {
    CompletionWindowStatus.completed => AppColorTokens.success,
    CompletionWindowStatus.open => AppColorTokens.primary,
    CompletionWindowStatus.locked =>
      Theme.of(context).colorScheme.onSurfaceVariant,
    CompletionWindowStatus.waiting => category,
  };
}

class _ScheduleMeta {
  const _ScheduleMeta({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  factory _ScheduleMeta.from(String category, String sourceType) {
    if (sourceType == LifestyleScheduleSourceTypes.mealPlan ||
        category == LifestyleScheduleCategories.meal) {
      return const _ScheduleMeta(
        icon: Icons.restaurant_rounded,
        color: AppColorTokens.secondary,
        label: 'Bữa ăn',
      );
    }

    return switch (category) {
      LifestyleScheduleCategories.water => const _ScheduleMeta(
        icon: Icons.water_drop_rounded,
        color: AppColorTokens.info,
        label: 'Uống nước',
      ),
      LifestyleScheduleCategories.body => const _ScheduleMeta(
        icon: Icons.directions_run_rounded,
        color: AppColorTokens.success,
        label: 'Vận động',
      ),
      LifestyleScheduleCategories.mind => const _ScheduleMeta(
        icon: Icons.self_improvement_rounded,
        color: AppColorTokens.tertiary,
        label: 'Tinh thần',
      ),
      LifestyleScheduleCategories.brain => const _ScheduleMeta(
        icon: Icons.psychology_rounded,
        color: AppColorTokens.warning,
        label: 'Trí não',
      ),
      LifestyleScheduleCategories.sleep => const _ScheduleMeta(
        icon: Icons.bedtime_rounded,
        color: AppColorTokens.primaryHover,
        label: 'Giấc ngủ',
      ),
      LifestyleScheduleCategories.metric => const _ScheduleMeta(
        icon: Icons.monitor_weight_outlined,
        color: AppColorTokens.success,
        label: 'Chỉ số',
      ),
      _ => const _ScheduleMeta(
        icon: Icons.checklist_rounded,
        color: AppColorTokens.primary,
        label: 'Chăm sóc',
      ),
    };
  }
}
