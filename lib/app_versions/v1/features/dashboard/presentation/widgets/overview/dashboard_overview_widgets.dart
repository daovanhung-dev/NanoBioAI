import 'package:flutter/material.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/services/dashboard_companion_service.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart';
import 'package:nano_app/core/membership/membership_display_info.dart';
import 'package:nano_app/core/theme/theme.dart';

class DashboardHeader extends StatelessWidget {
  final String fullName;
  final MembershipDisplayInfo membershipInfo;
  final int unreadNotifications;

  const DashboardHeader({
    required this.fullName,
    required this.membershipInfo,
    required this.unreadNotifications,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final shortName = fullName.trim().isEmpty
        ? 'bạn'
        : fullName.trim().split(RegExp(r'\s+')).last;
    final notificationLabel = unreadNotifications == 0
        ? 'Không có lời nhắc mới'
        : '$unreadNotifications lời nhắc mới';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.avatarSizeLarge,
            height: AppSpacing.avatarSizeLarge,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: .24),
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.surface,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Chào $shortName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Hôm nay mình chăm sóc bản thân nhé.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textInverse.withValues(alpha: .88),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _HeaderBadge(
                  icon: membershipInfo.icon,
                  label: _membershipLabel(membershipInfo),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: notificationLabel,
            child: Tooltip(
              message: notificationLabel,
              child: SizedBox(
                width: AppSpacing.iconButtonSize,
                height: AppSpacing.iconButtonSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: .24),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            unreadNotifications > 9
                                ? '9+'
                                : '$unreadNotifications',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _membershipLabel(MembershipDisplayInfo info) {
    switch (info.code.trim().toLowerCase()) {
      case 'guest':
        return 'Khách trải nghiệm';
      case 'free':
        return 'Gói Cơ bản';
      case 'plus':
        return 'Gói Plus';
      case 'family_plus':
      case 'familyplus':
        return 'Gói FamilyPlus';
      default:
        return info.label.trim().isEmpty ? 'Thành viên' : info.label;
    }
  }
}

class DashboardSnapshotCard extends StatelessWidget {
  final DashboardDailyMetrics metrics;
  final DashboardTimelineItem? nextAction;
  final String dailySummary;
  final bool isSlowDay;
  final VoidCallback onScoreTap;
  final TimelineActionCallback onComplete;
  final VoidCallback onLater;

  const DashboardSnapshotCard({
    required this.metrics,
    required this.nextAction,
    required this.dailySummary,
    required this.isSlowDay,
    required this.onScoreTap,
    required this.onComplete,
    required this.onLater,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return _DashboardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.today_rounded,
            title: 'Hôm nay',
            subtitle: 'Thông tin quan trọng nhất của bạn',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 360 || textScale > 1.18;
              final score = _ScoreSummary(
                metrics: metrics,
                onTap: onScoreTap,
              );
              final action = _NextActionSummary(
                item: nextAction,
                dailySummary: dailySummary,
                isSlowDay: isSlowDay,
                onComplete: onComplete,
                onLater: onLater,
              );
              if (stacked) {
                return Column(
                  children: [
                    score,
                    const SizedBox(height: AppSpacing.md),
                    action,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 126, child: score),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: action),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardQuickActions extends StatelessWidget {
  final String? selectedMood;
  final int waterMl;
  final double weightKg;
  final VoidCallback onMoodTap;
  final VoidCallback onWaterTap;
  final VoidCallback onWeightTap;

  const DashboardQuickActions({
    required this.selectedMood,
    required this.waterMl,
    required this.weightKg,
    required this.onMoodTap,
    required this.onWaterTap,
    required this.onWeightTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final moodLabel = selectedMood == null
        ? 'Chưa ghi nhận'
        : DashboardCompanionService.moodLabel(selectedMood!);
    final items = [
      _QuickActionData(
        icon: Icons.mood_rounded,
        label: 'Cảm xúc',
        value: moodLabel,
        onTap: onMoodTap,
      ),
      _QuickActionData(
        icon: Icons.water_drop_rounded,
        label: 'Nước',
        value: waterMl > 0 ? '${waterMl} ml' : 'Thêm nước',
        onTap: onWaterTap,
      ),
      _QuickActionData(
        icon: Icons.monitor_weight_rounded,
        label: 'Cân nặng',
        value: weightKg > 0 ? '${weightKg.toStringAsFixed(1)} kg' : 'Cập nhật',
        onTap: onWeightTap,
      ),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.bolt_rounded,
          title: 'Ghi nhận nhanh',
          subtitle: 'Chạm một lần để cập nhật hôm nay',
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 330 || textScale > 1.15
                ? 2
                : 3;
            final width =
                (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _QuickActionTile(data: item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class DashboardMoodCheckInSheet extends StatelessWidget {
  final String? selectedMood;
  final Future<void> Function(String mood) onSelectMood;

  const DashboardMoodCheckInSheet({
    required this.selectedMood,
    required this.onSelectMood,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hôm nay bạn thấy thế nào?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chọn cảm nhận gần nhất với cơ thể lúc này.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ...DashboardMoodCodes.all.map((mood) {
              final selected = selectedMood == mood;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  minTileHeight: AppSpacing.touchTargetMin,
                  selected: selected,
                  selectedTileColor: AppColors.primarySoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary.withValues(alpha: .35)
                          : AppColors.borderLight,
                    ),
                  ),
                  leading: Icon(
                    _moodIcon(mood),
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    DashboardCompanionService.moodLabel(mood),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await onSelectMood(mood);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _moodIcon(String mood) {
    switch (mood) {
      case DashboardMoodCodes.ok:
        return Icons.sentiment_satisfied_alt_rounded;
      case DashboardMoodCodes.tired:
        return Icons.bedtime_rounded;
      case DashboardMoodCodes.stressed:
        return Icons.psychology_alt_rounded;
      case DashboardMoodCodes.uncomfortable:
        return Icons.healing_rounded;
      default:
        return Icons.mood_rounded;
    }
  }
}

class DashboardTodayMetrics extends StatelessWidget {
  final DashboardDailyMetrics metrics;

  const DashboardTodayMetrics({required this.metrics, super.key});

  @override
  Widget build(BuildContext context) {
    final calories = metrics.caloriesLogged > 0
        ? '${metrics.caloriesLogged} kcal'
        : metrics.caloriesPlanned > 0
        ? '${metrics.caloriesPlanned} kcal dự kiến'
        : 'Chưa ghi nhận';
    final items = [
      _MetricData(
        icon: Icons.task_alt_rounded,
        label: 'Nhiệm vụ',
        value: metrics.totalTasks > 0
            ? '${metrics.completedTasks}/${metrics.totalTasks}'
            : 'Chưa có lịch',
        color: AppColors.primary,
      ),
      _MetricData(
        icon: Icons.directions_walk_rounded,
        label: 'Bước chân',
        value: metrics.stepsCount > 0
            ? '${metrics.stepsCount} bước'
            : 'Chưa ghi nhận',
        color: AppColors.secondary,
      ),
      _MetricData(
        icon: Icons.local_fire_department_rounded,
        label: 'Năng lượng',
        value: calories,
        color: AppColors.warning,
      ),
      _MetricData(
        icon: Icons.bedtime_outlined,
        label: 'Giấc ngủ',
        value: metrics.sleepHours > 0
            ? '${metrics.sleepHours.toStringAsFixed(1)} giờ'
            : 'Chưa ghi nhận',
        color: AppColors.tertiary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.query_stats_rounded,
          title: 'Tổng quan hôm nay',
          subtitle: 'Bốn chỉ số cần xem nhanh',
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 280 ? 2 : 1;
            final width =
                (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _MetricTile(data: item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final DashboardDailyMetrics metrics;
  final VoidCallback onTap;

  const _ScoreSummary({required this.metrics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasInputs = metrics.hasDailyScoreInputs;
    final score = metrics.dailyScore.clamp(0, 100);
    return Semantics(
      button: true,
      label: hasInputs
          ? 'Điểm sức khỏe hôm nay $score trên 100. Chạm để xem chi tiết.'
          : 'Chưa đủ dữ liệu tính điểm. Chạm để xem chi tiết.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primarySoft),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreRing(
                progress: hasInputs ? score / 100 : 0,
                label: hasInputs ? '$score' : '--',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasInputs ? _scoreTitle(score) : 'Chưa đủ dữ liệu',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scoreTitle(int score) {
    if (score >= 85) return 'Rất ổn';
    if (score >= 65) return 'Đúng hướng';
    if (score >= 40) return 'Cải thiện nhẹ';
    return 'Cần chăm hơn';
  }
}

class _ScoreRing extends StatelessWidget {
  final double progress;
  final String label;

  const _ScoreRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1).toDouble()),
      duration: disableAnimations ? Duration.zero : AppDuration.progress,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.primarySoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'điểm',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextActionSummary extends StatelessWidget {
  final DashboardTimelineItem? item;
  final String dailySummary;
  final bool isSlowDay;
  final TimelineActionCallback onComplete;
  final VoidCallback onLater;

  const _NextActionSummary({
    required this.item,
    required this.dailySummary,
    required this.isSlowDay,
    required this.onComplete,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final action = item;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Việc tiếp theo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (action == null) ...[
            Text(
              'Hôm nay chưa có việc cần làm ngay.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dailySummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              action.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (action.timeLabel.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                action.timeLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              isSlowDay
                  ? 'Mình làm thật nhẹ, không cần vội.'
                  : DashboardCompanionService.nextActionMessage(action),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => onComplete(action),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Đã làm'),
                ),
                TextButton(onPressed: onLater, child: const Text('Để sau')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${data.label}: ${data.value}. Chạm để cập nhật.',
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(data.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 102),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
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

class _DashboardSurface extends StatelessWidget {
  final Widget child;

  const _DashboardSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surface.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textInverse, size: 15),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
