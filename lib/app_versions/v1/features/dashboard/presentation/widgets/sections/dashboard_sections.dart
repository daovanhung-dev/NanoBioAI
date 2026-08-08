import 'package:flutter/material.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart';
import 'package:nano_app/core/theme/theme.dart';

class DashboardTimelinePreview extends StatelessWidget {
  final List<DashboardTimelineItem> items;
  final TimelineActionCallback onComplete;
  final VoidCallback onViewAll;

  const DashboardTimelinePreview({
    required this.items,
    required this.onComplete,
    required this.onViewAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = [...items]
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    final preview = visibleItems.take(3).toList();

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.view_timeline_rounded,
            title: 'Lịch hôm nay',
            subtitle: preview.isEmpty
                ? 'Chưa có hoạt động được sắp cho hôm nay'
                : 'Ưu tiên các việc chưa hoàn thành',
            trailing: TextButton(
              onPressed: onViewAll,
              child: const Text('Xem toàn bộ'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (preview.isEmpty)
            const _EmptyMessage(
              icon: Icons.event_available_outlined,
              title: 'Hôm nay chưa có lịch',
              message:
                  'Bạn có thể mở lịch chăm sóc để xem hoặc chuẩn bị nhịp mới.',
            )
          else
            ...preview.indexed.map((entry) {
              final index = entry.$1;
              final item = entry.$2;
              return Column(
                children: [
                  _TimelineRow(item: item, onComplete: onComplete),
                  if (index != preview.length - 1)
                    const Divider(height: AppSpacing.md),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class DashboardProgressCard extends StatelessWidget {
  final DashboardPlanStatus planStatus;
  final DashboardSelfCareStreak streak;
  final bool isGeneratingPlan;
  final Future<void> Function() onGeneratePlan;

  const DashboardProgressCard({
    required this.planStatus,
    required this.streak,
    required this.isGeneratingPlan,
    required this.onGeneratePlan,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showGenerateAction =
        !planStatus.hasPlan || planStatus.remainingDays <= 1;
    final planTitle = !planStatus.hasPlan
        ? 'Chưa có lịch chăm sóc'
        : planStatus.remainingDays > 1
        ? 'Lịch còn ${planStatus.remainingDays} ngày'
        : planStatus.remainingDays == 1
        ? 'Hôm nay là ngày cuối'
        : 'Lịch hiện tại đã kết thúc';
    final streakText = streak.currentStreak > 0
        ? 'Chuỗi ${streak.currentStreak} ngày'
        : streak.hasAnyCareDay
        ? 'Đã có ngày chăm sóc trong tuần'
        : 'Bắt đầu từ một ghi nhận nhỏ';

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.trending_up_rounded,
            title: 'Tiến độ',
            subtitle: 'Lịch hiện tại và nhịp chăm sóc của bạn',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProgressInfo(
                  icon: Icons.event_available_rounded,
                  label: 'Kế hoạch',
                  value: planTitle,
                  color: context.semanticColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ProgressInfo(
                  icon: Icons.local_florist_rounded,
                  label: 'Chuỗi chăm sóc',
                  value: streakText,
                  color: context.semanticColors.success,
                ),
              ),
            ],
          ),
          if (streak.days.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: streak.days
                  .take(7)
                  .map(
                    (day) => Expanded(
                      child: _StreakDay(
                        label: _weekdayLabel(day.date),
                        active: day.hasCareSignal,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (showGenerateAction) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isGeneratingPlan ? null : onGeneratePlan,
                icon: isGeneratingPlan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  isGeneratingPlan
                      ? 'Nabi đang chuẩn bị lịch...'
                      : !planStatus.hasPlan
                      ? 'Tạo lịch 7 ngày'
                      : 'Chuẩn bị lịch tiếp theo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardPrimaryInsight extends StatelessWidget {
  final List<DashboardInsightItem> insights;
  final List<DashboardRecommendationItem> recommendations;
  final String concern;

  const DashboardPrimaryInsight({
    required this.insights,
    required this.recommendations,
    required this.concern,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedInsights = [...insights]
      ..sort(
        (a, b) =>
            _riskPriority(a.riskLevel).compareTo(_riskPriority(b.riskLevel)),
      );
    final primaryInsight = sortedInsights.firstOrNull;
    final recommendation = recommendations.firstOrNull;

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.auto_awesome_rounded,
            title: 'Gợi ý từ Nabi',
            subtitle: 'Một điều đáng chú ý nhất hôm nay',
          ),
          const SizedBox(height: AppSpacing.md),
          if (primaryInsight == null &&
              recommendation == null &&
              concern.trim().isEmpty)
            const _EmptyMessage(
              icon: Icons.auto_awesome_outlined,
              title: 'Chưa có gợi ý mới',
              message:
                  'Khi có thêm ghi nhận, Nabi sẽ đặt điều quan trọng nhất ở đây.',
            )
          else ...[
            if (primaryInsight != null) _InsightBody(insight: primaryInsight),
            if (recommendation != null) ...[
              if (primaryInsight != null) const SizedBox(height: AppSpacing.sm),
              _RecommendationRow(item: recommendation),
            ],
            if (concern.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.semanticColors.secondarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'Bạn đang quan tâm: ${concern.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class DashboardHealthDetails extends StatelessWidget {
  final double bmi;
  final double heightCm;
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;
  final List<DashboardGoalProgressItem> goalProgress;
  final List<String> fallbackGoals;
  final List<String> conditions;
  final List<String> habits;

  const DashboardHealthDetails({
    required this.bmi,
    required this.heightCm,
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
    required this.goalProgress,
    required this.fallbackGoals,
    required this.conditions,
    required this.habits,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final activeGoalCount = goalProgress.where((goal) => goal.isActive).length;
    final goalCount = activeGoalCount > 0
        ? activeGoalCount
        : fallbackGoals.length;
    final noteCount = conditions.length + habits.length;
    final summaryParts = <String>[
      if (goalCount > 0) '$goalCount mục tiêu',
      if (noteCount > 0) '$noteCount lưu ý',
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.semanticColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          'Mục tiêu và thông tin sức khỏe',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          summaryParts.isEmpty
              ? 'Xem thông tin hồ sơ đã chia sẻ'
              : summaryParts.join(' • '),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.semanticColors.textSecondary,
          ),
        ),
        children: [
          const Divider(),
          _DetailGroup(
            title: 'Thông tin cơ bản',
            children: [
              _InfoChip(
                label: bmi > 0 ? 'BMI ${bmi.toStringAsFixed(1)}' : 'BMI --',
              ),
              _InfoChip(
                label: heightCm > 0
                    ? '${heightCm.toStringAsFixed(0)} cm'
                    : 'Chiều cao chưa có',
              ),
              _InfoChip(label: sleepQuality),
              _InfoChip(label: activityLevel),
              _InfoChip(label: waterPerDay),
            ],
          ),
          if (goalProgress.isNotEmpty || fallbackGoals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _GoalsDetail(
              progressItems: goalProgress,
              fallbackGoals: fallbackGoals,
            ),
          ],
          if (conditions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailGroup(
              title: 'Sức khỏe cần lưu ý',
              children: conditions
                  .map((item) => _InfoChip(label: item))
                  .toList(),
            ),
          ],
          if (habits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailGroup(
              title: 'Thói quen đã chia sẻ',
              children: habits.map((item) => _InfoChip(label: item)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final DashboardTimelineItem item;
  final TimelineActionCallback onComplete;

  const _TimelineRow({required this.item, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(item.category);
    return Opacity(
      opacity: item.isCompleted ? .62 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_categoryIcon(item.category), color: color, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.timeLabel.trim().isNotEmpty) ...[
                      Text(
                        item.timeLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: context.semanticColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (item.isCompleted)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.semanticColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.canComplete && !item.isCompleted) ...[
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Mở ${item.title} để hoàn thành',
              child: IconButton.filledTonal(
                onPressed: () => onComplete(item),
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: 'Mở hoạt động',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProgressInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.semanticColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.semanticColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String label;
  final bool active;

  const _StreakDay({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active
                ? context.semanticColors.success
                : context.semanticColors.surfaceSoft,
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? context.semanticColors.success
                  : context.semanticColors.border,
            ),
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.circle_outlined,
            color: active
                ? context.semanticColors.textInverse
                : context.semanticColors.textMuted,
            size: 15,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _InsightBody extends StatelessWidget {
  final DashboardInsightItem insight;

  const _InsightBody({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(insight.riskLevel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_riskIcon(insight.riskLevel), color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.45,
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

class _RecommendationRow extends StatelessWidget {
  final DashboardRecommendationItem item;

  const _RecommendationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 21,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.4,
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

class _GoalsDetail extends StatelessWidget {
  final List<DashboardGoalProgressItem> progressItems;
  final List<String> fallbackGoals;

  const _GoalsDetail({
    required this.progressItems,
    required this.fallbackGoals,
  });

  @override
  Widget build(BuildContext context) {
    final activeItems = progressItems.where((item) => item.isActive).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục tiêu',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeItems.isNotEmpty)
          ...activeItems
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${(item.progress.clamp(0, 1) * 100).round()}%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: context.semanticColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: item.progress.clamp(0, 1).toDouble(),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ],
                  ),
                ),
              )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: fallbackGoals
                .take(6)
                .map((goal) => _InfoChip(label: goal))
                .toList(),
          ),
      ],
    );
  }
}

class _DetailGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final safeLabel = label.trim().isEmpty ? 'Chưa ghi nhận' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.semanticColors.primarySoft),
      ),
      child: Text(
        safeLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.semanticColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  final Widget child;

  const _SectionSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.semanticColors.borderLight),
        boxShadow: AppShadows.xs,
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.semanticColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: context.semanticColors.primary, size: 21),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.semanticColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.4,
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

int _riskPriority(String riskLevel) {
  switch (riskLevel.trim().toLowerCase()) {
    case 'high':
    case 'danger':
      return 0;
    case 'medium':
    case 'warning':
      return 1;
    default:
      return 2;
  }
}

Color _riskColor(String riskLevel) {
  switch (riskLevel.trim().toLowerCase()) {
    case 'high':
    case 'danger':
      return AppColors.error;
    case 'medium':
    case 'warning':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

IconData _riskIcon(String riskLevel) {
  switch (riskLevel.trim().toLowerCase()) {
    case 'high':
    case 'danger':
      return Icons.warning_rounded;
    case 'medium':
    case 'warning':
      return Icons.info_rounded;
    default:
      return Icons.check_circle_outline_rounded;
  }
}

Color _categoryColor(String category) {
  switch (category.trim().toLowerCase()) {
    case 'water':
      return AppColors.secondary;
    case 'body':
    case 'exercise':
      return AppColors.success;
    case 'mind':
    case 'stress':
    case 'sleep':
      return AppColors.tertiary;
    case 'meal':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

IconData _categoryIcon(String category) {
  switch (category.trim().toLowerCase()) {
    case 'water':
      return Icons.water_drop_rounded;
    case 'body':
    case 'exercise':
      return Icons.directions_run_rounded;
    case 'mind':
    case 'stress':
      return Icons.self_improvement_rounded;
    case 'sleep':
      return Icons.bedtime_rounded;
    case 'meal':
      return Icons.restaurant_rounded;
    default:
      return Icons.favorite_outline_rounded;
  }
}

String _weekdayLabel(String rawDate) {
  final date = DateTime.tryParse(rawDate);
  if (date == null) return '•';
  const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return labels[date.weekday - 1];
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
