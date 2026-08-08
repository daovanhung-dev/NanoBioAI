part of '../pages/other_page.dart';

class _HealthInsightsHeader extends StatelessWidget {
  final DashboardEntity dashboard;

  const _HealthInsightsHeader({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final name = _shortName(dashboard.fullName);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Góc sức khỏe',
                style: AppTextStyles.heading1.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                name.isEmpty
                    ? 'Tổng hợp những điều đáng chú ý hôm nay'
                    : 'Chào $name, đây là tổng hợp hôm nay',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.semanticColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          height: 44,
          width: 44,
          decoration: AppDecoration.gradient(
            colors: const [AppColors.primary, AppColors.secondary],
            radius: AppRadius.md,
            shadows: AppShadows.sm,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.surface,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _HealthSnapshotCard extends StatelessWidget {
  final DashboardDailyMetrics metrics;

  const _HealthSnapshotCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final score = metrics.dailyScore;
    final progress = score <= 0 ? 0.0 : (score / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.compactCardPadding),
      decoration: AppDecoration.gradient(
        colors: AppGradients.hero.colors,
        radius: AppRadius.lg,
        shadows: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG QUAN HÔM NAY',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.semanticColors.surface.withValues(
                          alpha: .82,
                        ),
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _scoreTitle(score),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading2.copyWith(
                        color: context.semanticColors.surface,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _scoreMessage(score),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.surface.withValues(
                          alpha: .86,
                        ),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScoreBadge(score: score),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.semanticColors.surface.withValues(
                alpha: .2,
              ),
              valueColor: const AlwaysStoppedAnimation(AppColors.surface),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.favorite_rounded,
                  label: 'Nhịp tim',
                  value: metrics.heartRateBpm == null
                      ? '--'
                      : '${metrics.heartRateBpm} bpm',
                ),
              ),
              const SizedBox(width: AppSpacing.compactItemSpacing),
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.bloodtype_rounded,
                  label: 'SpO₂',
                  value: metrics.oxygenSaturation == null
                      ? '--'
                      : '${metrics.oxygenSaturation!.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.surface.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.semanticColors.surface.withValues(alpha: .2),
        ),
      ),
      child: Column(
        children: [
          Text(
            score <= 0 ? '--' : '$score',
            style: AppTextStyles.displaySmall.copyWith(
              color: context.semanticColors.surface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            score <= 0 ? 'chưa có' : 'điểm',
            maxLines: 1,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.semanticColors.surface.withValues(alpha: .82),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.surface.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.semanticColors.surface, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.semanticColors.surface.withValues(
                      alpha: .72,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: context.semanticColors.surface,
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

class _TodayMetricStrip extends StatelessWidget {
  final DashboardDailyMetrics metrics;

  const _TodayMetricStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final calories = metrics.caloriesLogged > 0
        ? metrics.caloriesLogged
        : metrics.caloriesPlanned;
    final calorieHint = metrics.caloriesLogged > 0 ? 'đã ghi' : 'kế hoạch';
    final items = [
      _HealthMetricItem(
        label: 'Nước',
        value: metrics.waterMl > 0
            ? (metrics.waterMl / 1000).toStringAsFixed(1)
            : '--',
        unit: 'L',
        icon: Icons.water_drop_rounded,
        color: context.semanticColors.info,
        background: context.semanticColors.infoSoft,
      ),
      _HealthMetricItem(
        label: 'Năng lượng',
        value: calories > 0 ? _formatInt(calories) : '--',
        unit: calories > 0 ? calorieHint : 'kcal',
        icon: Icons.local_fire_department_rounded,
        color: context.semanticColors.warning,
        background: context.semanticColors.warningSoft,
      ),
      _HealthMetricItem(
        label: 'Giấc ngủ',
        value: metrics.sleepHours > 0
            ? metrics.sleepHours.toStringAsFixed(1)
            : '--',
        unit: 'giờ',
        icon: Icons.bedtime_rounded,
        color: context.semanticColors.primary,
        background: context.semanticColors.primarySoft,
      ),
      _HealthMetricItem(
        label: 'Bước chân',
        value: metrics.stepsCount > 0 ? _formatInt(metrics.stepsCount) : '--',
        unit: 'bước',
        icon: Icons.directions_walk_rounded,
        color: context.semanticColors.success,
        background: context.semanticColors.successSoft,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Chỉ số hôm nay'),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.compactItemSpacing,
                crossAxisSpacing: AppSpacing.compactItemSpacing,
                childAspectRatio: columns == 4 ? 1.75 : 2.1,
              ),
              itemBuilder: (context, index) {
                return _HealthMetricTile(item: items[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _HealthMetricItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color background;

  const _HealthMetricItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _HealthMetricTile extends StatelessWidget {
  final _HealthMetricItem item;

  const _HealthMetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingCompact),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: item.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(item.icon, color: item.color, size: 19),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading4.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        item.unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryInsightSection extends StatelessWidget {
  final List<DashboardInsightItem> insights;

  const _PrimaryInsightSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Nabi chưa có nhận xét mới',
        message: 'Khi có thêm tín hiệu, Nabi sẽ đặt điều đáng chú ý ở đây.',
      );
    }

    final primary = insights.first;
    final remaining = insights.skip(1).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Mình nhận thấy'),
        const SizedBox(height: AppSpacing.sm),
        _CompactSurface(
          accentColor: _riskColor(primary.riskLevel),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TintedIcon(
                icon: _riskIcon(primary.riskLevel),
                color: _riskColor(primary.riskLevel),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            primary.title,
                            style: AppTextStyles.heading5,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _RiskLabel(riskLevel: primary.riskLevel),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      primary.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.42),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _ExpandableInsightList(items: remaining),
        ],
      ],
    );
  }
}

class _ExpandableInsightList extends StatelessWidget {
  final List<DashboardInsightItem> items;

  const _ExpandableInsightList({required this.items});

  @override
  Widget build(BuildContext context) {
    return _CompactExpansionPanel(
      title: 'Xem thêm ${items.length} nhận xét',
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _InsightDetailRow(item: items[index]),
          if (index != items.length - 1)
            const Divider(height: AppSpacing.md, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _InsightDetailRow extends StatelessWidget {
  final DashboardInsightItem item;

  const _InsightDetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(item.riskLevel);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_riskIcon(item.riskLevel), size: 19, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                item.content,
                style: AppTextStyles.bodySmall.copyWith(height: 1.42),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryRecommendationSection extends StatelessWidget {
  final List<DashboardRecommendationItem> recommendations;

  const _PrimaryRecommendationSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Nabi chưa có gợi ý mới',
        message: 'Bạn cứ tiếp tục theo nhịp hiện tại nhé.',
      );
    }

    final primary = recommendations.first;
    final remaining = recommendations.skip(1).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Việc nên làm hôm nay'),
        const SizedBox(height: AppSpacing.sm),
        _CompactSurface(
          accentColor: context.semanticColors.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TintedIcon(
                icon: primary.isRead
                    ? Icons.lightbulb_outline_rounded
                    : Icons.lightbulb_rounded,
                color: context.semanticColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(primary.title, style: AppTextStyles.heading5),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      primary.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.42),
                    ),
                    if (primary.actionText.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gợi ý: ${primary.actionText.trim()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.semanticColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _ExpandableRecommendationList(items: remaining),
        ],
      ],
    );
  }
}

class _ExpandableRecommendationList extends StatelessWidget {
  final List<DashboardRecommendationItem> items;

  const _ExpandableRecommendationList({required this.items});

  @override
  Widget build(BuildContext context) {
    return _CompactExpansionPanel(
      title: 'Xem thêm ${items.length} gợi ý',
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _RecommendationDetailRow(item: items[index]),
          if (index != items.length - 1)
            const Divider(height: AppSpacing.md, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _RecommendationDetailRow extends StatelessWidget {
  final DashboardRecommendationItem item;

  const _RecommendationDetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.isRead
              ? Icons.lightbulb_outline_rounded
              : Icons.lightbulb_rounded,
          size: 19,
          color: context.semanticColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                item.description,
                style: AppTextStyles.bodySmall.copyWith(height: 1.42),
              ),
              if (item.actionText.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gợi ý: ${item.actionText.trim()}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AdditionalHealthDetails extends StatelessWidget {
  final DashboardEntity dashboard;
  final DashboardDailyMetrics metrics;
  final int insightCount;
  final int recommendationCount;

  const _AdditionalHealthDetails({
    required this.dashboard,
    required this.metrics,
    required this.insightCount,
    required this.recommendationCount,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRowData>[
      _DetailRowData(
        icon: Icons.psychology_rounded,
        label: 'Căng thẳng',
        value: metrics.stressLevel > 0
            ? _stressLabel(metrics.stressLevel)
            : '--',
        color: context.semanticColors.secondary,
      ),
      _DetailRowData(
        icon: Icons.monitor_weight_rounded,
        label: 'BMI',
        value: dashboard.bmi > 0 ? dashboard.bmi.toStringAsFixed(1) : '--',
        color: context.semanticColors.warning,
      ),
      if (insightCount > 1)
        _DetailRowData(
          icon: Icons.auto_awesome_outlined,
          label: 'Nhận xét khác',
          value: '${insightCount - 1}',
          color: context.semanticColors.success,
        ),
      if (recommendationCount > 1)
        _DetailRowData(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Gợi ý khác',
          value: '${recommendationCount - 1}',
          color: context.semanticColors.primary,
        ),
    ];

    return _CompactExpansionPanel(
      title: 'Thông tin thêm',
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _DetailRow(data: rows[index]),
          if (index != rows.length - 1)
            const Divider(height: AppSpacing.md, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _DetailRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DetailRow extends StatelessWidget {
  final _DetailRowData data;

  const _DetailRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(data.icon, color: data.color, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(data.label, style: AppTextStyles.bodyMedium)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          data.value,
          style: AppTextStyles.labelLarge.copyWith(
            color: context.semanticColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CompactExpansionPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CompactExpansionPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: ExpansionTile(
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.compactCardPadding,
          vertical: AppSpacing.xxs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.compactCardPadding,
          0,
          AppSpacing.compactCardPadding,
          AppSpacing.compactCardPadding,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: context.semanticColors.primary,
        collapsedIconColor: context.semanticColors.textMuted,
        title: Text(title, style: AppTextStyles.labelLarge),
        children: children,
      ),
    );
  }
}

class _CompactSurface extends StatelessWidget {
  final Widget child;
  final Color? accentColor;

  const _CompactSurface({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.compactCardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          top: const BorderSide(color: AppColors.borderLight),
          right: const BorderSide(color: AppColors.borderLight),
          bottom: const BorderSide(color: AppColors.borderLight),
          left: BorderSide(
            color: accentColor ?? context.semanticColors.borderLight,
            width: accentColor == null ? 1 : 3,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _TintedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TintedIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _RiskLabel extends StatelessWidget {
  final String riskLevel;

  const _RiskLabel({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(riskLevel);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Text(
        _riskLabel(riskLevel),
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle);
  }
}

class _CompactEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompactEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.compactCardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TintedIcon(icon: icon, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.42),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthInsightsStatusStrip extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HealthInsightsStatusStrip({
    required this.icon,
    required this.message,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.compactCardPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.semanticColors.primarySoft),
      ),
      child: Row(
        children: [
          if (showProgress)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 19, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _HealthInsightsLoadingState extends StatelessWidget {
  const _HealthInsightsLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.compactPagePadding),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(height: 48, widthFactor: .72),
          SizedBox(height: AppSpacing.compactSectionSpacing),
          _SkeletonBlock(height: 210),
          SizedBox(height: AppSpacing.compactSectionSpacing),
          Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 72)),
              SizedBox(width: AppSpacing.compactItemSpacing),
              Expanded(child: _SkeletonBlock(height: 72)),
            ],
          ),
          SizedBox(height: AppSpacing.compactItemSpacing),
          Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 72)),
              SizedBox(width: AppSpacing.compactItemSpacing),
              Expanded(child: _SkeletonBlock(height: 72)),
            ],
          ),
          SizedBox(height: AppSpacing.compactSectionSpacing),
          _SkeletonBlock(height: 116),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final double widthFactor;

  const _SkeletonBlock({required this.height, this.widthFactor = 1});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.semanticColors.borderLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class _HealthInsightsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _HealthInsightsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          decoration: BoxDecoration(
            color: context.semanticColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.semanticColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TintedIcon(
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Chưa thể mở góc sức khỏe',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading4,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nabi chưa lấy được dữ liệu của bạn lúc này.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
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
      ),
    );
  }
}

Future<void> _refreshAll(WidgetRef ref) async {
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardDynamicProvider);
  await Future.wait<Object?>([
    ref.read(dashboardProvider.future),
    ref.read(dashboardDynamicProvider.future),
  ]);
}

void _retryAll(WidgetRef ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(dashboardDynamicProvider);
}

String _shortName(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  return text.split(RegExp(r'\s+')).last;
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final fromEnd = text.length - index;
    buffer.write(text[index]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

String _scoreTitle(int score) {
  if (score <= 0) return 'Chưa đủ dữ liệu hôm nay';
  if (score >= 85) return 'Hôm nay của bạn rất ổn';
  if (score >= 65) return 'Bạn đang đi đúng hướng';
  if (score >= 40) return 'Mình cùng cải thiện nhẹ nhé';
  return 'Hôm nay cần thêm chút chăm sóc';
}

String _scoreMessage(int score) {
  if (score <= 0) {
    return 'Nabi sẽ cập nhật khi có thêm ghi nhận.';
  }
  return 'Điểm tổng hợp từ nhiệm vụ, bữa ăn, nước và giấc ngủ.';
}

String _stressLabel(int value) {
  if (value <= 33) return 'Thấp';
  if (value <= 66) return 'Vừa';
  return 'Cao';
}

String _riskLabel(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return 'Cần chú ý';
    case 'medium':
    case 'warning':
      return 'Nên theo dõi';
    default:
      return 'Đang ổn';
  }
}

IconData _riskIcon(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return Icons.warning_rounded;
    case 'medium':
    case 'warning':
      return Icons.info_rounded;
    default:
      return Icons.check_circle_rounded;
  }
}

Color _riskColor(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return AppColors.error;
    case 'medium':
    case 'warning':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}
