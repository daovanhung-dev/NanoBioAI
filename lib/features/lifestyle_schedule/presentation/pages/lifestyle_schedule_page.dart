import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/lifestyle_schedule_state.dart';

class LifestyleSchedulePage extends ConsumerWidget {
  const LifestyleSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ScheduleError(message: error.toString()),
        data: (state) => RefreshIndicator(
          onRefresh: () =>
              ref.read(lifestyleScheduleControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.md,
                  128,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ScheduleHeader(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    _ProgressCard(state: state),
                    if (state.lastEncouragement != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _EncouragementBanner(
                        message: state.lastEncouragement!,
                        onClose: () => ref
                            .read(lifestyleScheduleControllerProvider.notifier)
                            .dismissEncouragement(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _DateSelector(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    _Timeline(items: state.selectedItems),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  final LifestyleScheduleState state;

  const _ScheduleHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.event_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isSelectedToday
                      ? 'Nhiệm vụ hôm nay'
                      : 'Lịch trình cá nhân',
                  style: AppTextStyles.heading4.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.summary.fullName} • ${_formatDate(state.selectedDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final LifestyleScheduleState state;

  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final value = state.score / 100;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiến độ trong ngày',
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              Text(
                '${state.completedItems}/${state.totalItems}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncouragementBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _EncouragementBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodyMedium)),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends ConsumerWidget {
  final LifestyleScheduleState state;

  const _DateSelector({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.availableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.availableDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final date = state.availableDates[index];
          final selected = DateUtils.isSameDay(date, state.selectedDate);
          return GestureDetector(
            onTap: () => ref
                .read(lifestyleScheduleControllerProvider.notifier)
                .selectDate(date),
            child: AnimatedContainer(
              duration: AppDuration.normal,
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.borderLight,
                ),
                boxShadow: selected ? AppShadows.md : AppShadows.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(date),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.heading5.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<LifestyleScheduleItemEntity> items;

  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có lịch trình cho ngày này',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading5.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch trình',
          style: AppTextStyles.heading4.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ScheduleItemCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _ScheduleItemCard extends ConsumerWidget {
  final LifestyleScheduleItemEntity item;

  const _ScheduleItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _meta(item.category, item.sourceType);
    final canComplete = item.isCompleted || item.canCompleteAt(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: item.isCompleted
              ? meta.color.withValues(alpha: .35)
              : AppColors.borderLight,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.startTime,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: meta.color,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                if (item.endTime.isNotEmpty)
                  Text(
                    item.endTime,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: AppTypography.bold,
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (!canComplete) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Chua den gio',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Checkbox(
            value: item.isCompleted,
            activeColor: meta.color,
            onChanged: canComplete
                ? (_) => ref
                      .read(lifestyleScheduleControllerProvider.notifier)
                      .toggleItem(item)
                : null,
          ),
        ],
      ),
    );
  }

  _ScheduleMeta _meta(String category, String sourceType) {
    if (sourceType == LifestyleScheduleSourceTypes.mealPlan ||
        category == LifestyleScheduleCategories.meal) {
      return const _ScheduleMeta(Icons.restaurant_rounded, Color(0xFF06B6D4));
    }

    switch (category) {
      case LifestyleScheduleCategories.water:
        return const _ScheduleMeta(Icons.water_drop_rounded, Color(0xFF0891B2));
      case LifestyleScheduleCategories.body:
        return const _ScheduleMeta(
          Icons.directions_run_rounded,
          Color(0xFF22C55E),
        );
      case LifestyleScheduleCategories.mind:
        return const _ScheduleMeta(
          Icons.self_improvement_rounded,
          Color(0xFF8B5CF6),
        );
      case LifestyleScheduleCategories.brain:
        return const _ScheduleMeta(Icons.psychology_rounded, Color(0xFFF59E0B));
      case LifestyleScheduleCategories.sleep:
        return const _ScheduleMeta(Icons.bedtime_rounded, Color(0xFF6366F1));
      default:
        return const _ScheduleMeta(Icons.checklist_rounded, AppColors.primary);
    }
  }
}

class _ScheduleError extends StatelessWidget {
  final String message;

  const _ScheduleError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa thể mở lịch trình',
              style: AppTextStyles.heading5.copyWith(
                fontWeight: AppTypography.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleMeta {
  final IconData icon;
  final Color color;

  const _ScheduleMeta(this.icon, this.color);
}

String _formatDate(DateTime date) {
  return '${_weekday(date)}, ${date.day}/${date.month}/${date.year}';
}

String _weekday(DateTime date) {
  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return days[date.weekday - 1];
}
