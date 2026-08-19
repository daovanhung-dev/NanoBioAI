import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/daily_health_task_entity.dart';
import '../../providers/daily_health_tracking_provider.dart';

class DailyHealthTrackingPage extends ConsumerWidget {
  const DailyHealthTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyHealthTrackingControllerProvider);
    final controller = ref.read(dailyHealthTrackingControllerProvider.notifier);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        backgroundColor: context.semanticColors.background,
        title: const Text('Theo dõi sức khỏe hôm nay'),
      ),
      body: SafeArea(
        top: false,
        child: AppStateSwitcher(
          alignment: Alignment.topCenter,
          child: state.when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => MedicalEmptyState(
              icon: Icons.monitor_heart_outlined,
              title: 'Nabi chưa mở được theo dõi hôm nay',
              message: 'Bạn thử lại sau một chút nhé.',
              action: FilledButton.icon(
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  AppSpacing.xxxl,
                ),
                children: [
                  _SummaryCard(
                    score: data.score,
                    completed: data.completedTasks,
                    total: data.totalTasks,
                  ),
                  if (data.lastEncouragement != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _EncouragementCard(
                      message: data.lastEncouragement!,
                      onDismiss: controller.dismissEncouragement,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Text('Việc chăm sóc hôm nay', style: AppTextStyles.heading3),
                  const SizedBox(height: AppSpacing.sm),
                  if (data.tasks.isEmpty)
                    const MedicalEmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'Hôm nay chưa có nhiệm vụ theo dõi',
                      message:
                          'Khi có mục chăm sóc phù hợp, Nabi sẽ hiển thị tại đây.',
                    )
                  else
                    for (final task in data.tasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _HealthTaskCard(
                          task: task,
                          onToggle: () => controller.toggleTask(task),
                          onAdd: task.taskCode.toLowerCase().contains('water')
                              ? () => controller.addWater(task)
                              : task.taskCode.toLowerCase().contains('step')
                                  ? () => controller.addSteps(task)
                                  : null,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.score, required this.completed, required this.total});
  final int score;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      decoration: AppDecoration.gradient(
        colors: AppGradients.health.colors,
        radius: AppRadius.xxl,
        shadows: AppShadows.md,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nhịp chăm sóc hôm nay',
            style: AppTextStyles.heading2.copyWith(
                color: AppColors.textInverse, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        Text('$completed/$total việc đã hoàn thành • $score điểm',
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textInverse.withValues(alpha: .92))),
        const SizedBox(height: AppSpacing.md),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          backgroundColor: AppColors.textInverse.withValues(alpha: .2),
          valueColor: const AlwaysStoppedAnimation(AppColors.textInverse),
        ),
      ]),
    );
  }
}

class _HealthTaskCard extends StatelessWidget {
  const _HealthTaskCard({required this.task, required this.onToggle, this.onAdd});
  final DailyHealthTaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(task.isCompleted ? Icons.check_circle_rounded : Icons.favorite_border_rounded,
                color: task.isCompleted ? colors.success : colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: AppTextStyles.labelLarge),
              if (task.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(task.description,
                    style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary)),
              ],
            ])),
          ]),
          if (task.isQuantitative) ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: task.progressRatio,
              minHeight: 6,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${task.currentValue.toStringAsFixed(0)} / ${task.targetValue.toStringAsFixed(0)} ${task.unit}',
                style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            if (onAdd != null && !task.isCompleted)
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ghi thêm'),
              ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: onToggle,
              icon: Icon(task.isCompleted ? Icons.undo_rounded : Icons.check_rounded),
              label: Text(task.isCompleted ? 'Hoàn tác' : 'Hoàn thành'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  const _EncouragementCard({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: context.semanticColors.successSoft,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(children: [
      Icon(Icons.auto_awesome_rounded, color: context.semanticColors.success),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(message)),
      IconButton(tooltip: 'Đóng', onPressed: onDismiss, icon: const Icon(Icons.close_rounded)),
    ]),
  );
}
