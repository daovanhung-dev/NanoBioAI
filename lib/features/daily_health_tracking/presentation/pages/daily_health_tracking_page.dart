import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/daily_health_task_entity.dart';
import '../../providers/daily_health_tracking_provider.dart';
import '../controllers/daily_health_tracking_state.dart';

class DailyHealthTrackingPage extends ConsumerWidget {
  const DailyHealthTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(dailyHealthTrackingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: trackingAsync.when(
        loading: () => const _TrackingLoading(),
        error: (error, _) => const _TrackingError(
          message:
              'Nami chưa thể mở phần theo dõi hôm nay. Bạn thử lại sau một chút nhé.',
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref
              .read(dailyHealthTrackingControllerProvider.notifier)
              .refresh(),
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
                    _TrackingHeader(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    _ScoreCard(state: state),
                    if (state.lastEncouragement != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _EncouragementBanner(message: state.lastEncouragement!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryGrid(progress: state.categoryProgress),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Nhiệm vụ hôm nay',
                      style: AppTextStyles.heading4.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...state.tasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TaskCard(task: task),
                      ),
                    ),
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

class _TrackingHeader extends StatelessWidget {
  final DailyHealthTrackingState state;

  const _TrackingHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hôm nay của ${state.summary.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.summary.taskDate,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Hoàn thành từng việc nhỏ để thấy tiến trình sức khỏe rõ hơn trong ngày.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final DailyHealthTrackingState state;

  const _ScoreCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.score / 100;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '${state.score}',
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỉ số hôm nay',
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${state.completedTasks}/${state.totalTasks} nhiệm vụ đã hoàn thành',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.success,
                    ),
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

class _EncouragementBanner extends StatelessWidget {
  final String message;

  const _EncouragementBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withOpacity(.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final Map<String, double> progress;

  const _CategoryGrid({required this.progress});

  @override
  Widget build(BuildContext context) {
    const categories = [
      _CategoryMeta(
        'water',
        'Nước',
        Icons.water_drop_rounded,
        Color(0xFF06B6D4),
      ),
      _CategoryMeta(
        'body',
        'Thân',
        Icons.directions_walk_rounded,
        Color(0xFF22C55E),
      ),
      _CategoryMeta(
        'mind',
        'Tâm',
        Icons.self_improvement_rounded,
        Color(0xFF8B5CF6),
      ),
      _CategoryMeta(
        'brain',
        'Trí',
        Icons.psychology_rounded,
        Color(0xFFF59E0B),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: .78,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        final value = progress[item.code] ?? 0;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: value >= 1
                  ? item.color.withOpacity(.45)
                  : AppColors.borderLight,
            ),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(value >= 1 ? .18 : .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${(value * 100).round()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final DailyHealthTaskEntity task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _metaFor(task.category);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: task.isCompleted
              ? meta.color.withOpacity(.35)
              : AppColors.borderLight,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: meta.color,
            onChanged: (_) => ref
                .read(dailyHealthTrackingControllerProvider.notifier)
                .toggleTask(task),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(meta.icon, color: meta.color, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        task.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: AppTypography.bold,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (task.isQuantitative) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                    child: LinearProgressIndicator(
                      value: task.progressRatio,
                      minHeight: 7,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${task.currentValue.round()}/${task.targetValue.round()} ${task.unit}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      _QuickActionButton(task: task),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _CategoryMeta _metaFor(String category) {
    switch (category) {
      case 'water':
        return const _CategoryMeta(
          'water',
          'Nước',
          Icons.water_drop_rounded,
          Color(0xFF06B6D4),
        );
      case 'body':
        return const _CategoryMeta(
          'body',
          'Thân',
          Icons.directions_walk_rounded,
          Color(0xFF22C55E),
        );
      case 'mind':
        return const _CategoryMeta(
          'mind',
          'Tâm',
          Icons.self_improvement_rounded,
          Color(0xFF8B5CF6),
        );
      default:
        return const _CategoryMeta(
          'brain',
          'Trí',
          Icons.psychology_rounded,
          Color(0xFFF59E0B),
        );
    }
  }
}

class _QuickActionButton extends ConsumerWidget {
  final DailyHealthTaskEntity task;

  const _QuickActionButton({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWater = task.category == 'water';
    final label = isWater ? '+250ml' : '+500';
    return TextButton(
      onPressed: task.isCompleted
          ? null
          : () {
              final controller = ref.read(
                dailyHealthTrackingControllerProvider.notifier,
              );
              if (isWater) {
                controller.addWater(task);
              } else {
                controller.addSteps(task);
              }
            },
      child: Text(label),
    );
  }
}

class _TrackingLoading extends StatelessWidget {
  const _TrackingLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TrackingError extends StatelessWidget {
  final String message;

  const _TrackingError({required this.message});

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
              'Chưa thể mở theo dõi hôm nay',
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

class _CategoryMeta {
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryMeta(this.code, this.label, this.icon, this.color);
}
