import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart';
import 'package:nano_app/core/theme/theme.dart';

class TodayTasksReadyState extends StatelessWidget {
  const TodayTasksReadyState({
    required this.tasks,
    required this.now,
    required this.onRefresh,
  });

  final List<LifestyleScheduleItemEntity> tasks;
  final DateTime now;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((task) => task.isCompleted).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final groups = _TodayTaskGroups.from(tasks: tasks, now: now);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MedicalPageHero(
                        eyebrow: 'KẾ HOẠCH TRONG NGÀY',
                        title: 'Nhiệm vụ hôm nay',
                        subtitle:
                            '${_formatVietnameseDate(now)}. Nabi giúp bạn theo dõi từng việc nhỏ theo đúng thời gian.',
                        icon: Icons.task_alt_rounded,
                        actions: [
                          MedicalStatusPill(
                            label: '$completed/${tasks.length} đã xong',
                            icon: Icons.check_circle_outline_rounded,
                            foregroundColor: AppColors.textInverse,
                            backgroundColor: AppColors.textInverse.withValues(
                              alpha: .14,
                            ),
                            borderColor: AppColors.textInverse.withValues(
                              alpha: .22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _TodayProgressCard(
                        completed: completed,
                        total: tasks.length,
                        progress: progress,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      if (tasks.isEmpty)
                        const TodayTasksEmptyState()
                      else ...[
                        _TaskSection(
                          title: 'Đang đến giờ',
                          subtitle:
                              'Bạn có thể xác nhận trong cửa sổ thời gian hiện tại.',
                          icon: Icons.bolt_rounded,
                          color: AppColors.primary,
                          tasks: groups.open,
                          now: now,
                        ),
                        _TaskSection(
                          title: 'Sắp tới',
                          subtitle: 'Các nhiệm vụ tiếp theo trong ngày.',
                          icon: Icons.schedule_rounded,
                          color: AppColors.info,
                          tasks: groups.waiting,
                          now: now,
                        ),
                        _TaskSection(
                          title: 'Đã hoàn thành',
                          subtitle: 'Những mốc bạn đã chăm sóc hôm nay.',
                          icon: Icons.verified_rounded,
                          color: AppColors.success,
                          tasks: groups.completed,
                          now: now,
                        ),
                        _TaskSection(
                          title: 'Đã kết thúc',
                          subtitle:
                              'Các mốc đã qua thời gian xác nhận trong ngày.',
                          icon: Icons.lock_clock_rounded,
                          color: AppColors.textSecondary,
                          tasks: groups.locked,
                          now: now,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final message = switch (percent) {
      100 => 'Bạn đã hoàn thành toàn bộ nhịp chăm sóc hôm nay.',
      >= 60 => 'Bạn đang giữ nhịp rất tốt. Cứ tiếp tục nhẹ nhàng nhé.',
      > 0 => 'Mỗi nhiệm vụ hoàn thành là một bước nhỏ có ý nghĩa.',
      _ => 'Bắt đầu từ nhiệm vụ phù hợp với thời gian hiện tại nhé.',
    };

    return MedicalSurfaceCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MedicalIconBadge(
                icon: Icons.insights_rounded,
                color: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiến độ hôm nay', style: AppTextStyles.heading4),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      total == 0
                          ? 'Chưa có nhiệm vụ'
                          : '$completed/$total nhiệm vụ • $percent%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.primarySoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.now,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<LifestyleScheduleItemEntity> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicalSectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
            action: MedicalStatusPill(
              label: '${tasks.length}',
              foregroundColor: color,
              backgroundColor: color.withValues(alpha: .09),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final task in tasks) ...[
            TodayTaskCard(task: task, now: now),
            if (task != tasks.last) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class TodayTasksEmptyState extends StatelessWidget {
  const TodayTasksEmptyState();

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const MedicalIconBadge(
              icon: Icons.event_available_rounded,
              color: AppColors.success,
              backgroundColor: AppColors.pastelMint,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Hôm nay chưa có nhiệm vụ',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Khi kế hoạch cá nhân được tạo, Nabi sẽ hiển thị từng nhiệm vụ tại đây.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TodayTasksLoadingState extends StatelessWidget {
  const TodayTasksLoadingState();

  @override
  Widget build(BuildContext context) {
    return const MedicalSurfaceCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Nabi đang chuẩn bị nhiệm vụ hôm nay...'),
          ],
        ),
      ),
    );
  }
}

class TodayTasksErrorState extends StatelessWidget {
  const TodayTasksErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      borderColor: AppColors.error.withValues(alpha: .18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            const MedicalIconBadge(
              icon: Icons.sync_problem_rounded,
              color: AppColors.error,
              backgroundColor: AppColors.pastelRose,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nabi chưa thể tải nhiệm vụ hôm nay.',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bạn kiểm tra kết nối rồi thử lại nhé.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayTasksPageFrame extends StatelessWidget {
  const TodayTasksPageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: child,
        ),
      ),
    );
  }
}

class _TodayTaskGroups {
  const _TodayTaskGroups({
    required this.open,
    required this.waiting,
    required this.completed,
    required this.locked,
  });

  final List<LifestyleScheduleItemEntity> open;
  final List<LifestyleScheduleItemEntity> waiting;
  final List<LifestyleScheduleItemEntity> completed;
  final List<LifestyleScheduleItemEntity> locked;

  factory _TodayTaskGroups.from({
    required List<LifestyleScheduleItemEntity> tasks,
    required DateTime now,
  }) {
    final open = <LifestyleScheduleItemEntity>[];
    final waiting = <LifestyleScheduleItemEntity>[];
    final completed = <LifestyleScheduleItemEntity>[];
    final locked = <LifestyleScheduleItemEntity>[];

    for (final task in tasks) {
      switch (task.completionStatusAt(now)) {
        case CompletionWindowStatus.open:
          open.add(task);
          break;
        case CompletionWindowStatus.waiting:
          waiting.add(task);
          break;
        case CompletionWindowStatus.completed:
          completed.add(task);
          break;
        case CompletionWindowStatus.locked:
          locked.add(task);
          break;
      }
    }

    return _TodayTaskGroups(
      open: open,
      waiting: waiting,
      completed: completed,
      locked: locked,
    );
  }
}

String _formatVietnameseDate(DateTime date) {
  const weekdays = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '${weekdays[date.weekday - 1]}, $day/$month/${date.year}';
}
