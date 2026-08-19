part of '../pages/other_page.dart';

const double _healthInsightsMaxContentWidth = 920;
const double _healthMetricMinWidth = 168;

class _HealthInsightsContentShell extends StatelessWidget {
  final Widget child;

  const _HealthInsightsContentShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 720
        ? AppSpacing.pagePaddingLarge
        : AppSpacing.pagePadding;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _healthInsightsMaxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.pagePadding,
            horizontalPadding,
            AppSpacing.xxxxl,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HealthInsightsHeader extends StatelessWidget {
  final DashboardEntity dashboard;

  const _HealthInsightsHeader({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final name = _shortName(dashboard.fullName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Góc sức khỏe',
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name.isEmpty
                    ? 'Những điều đáng chú ý và gợi ý chăm sóc dành cho bạn hôm nay.'
                    : 'Chào $name, Nabi đã gom những điều đáng chú ý hôm nay cho bạn.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.semanticColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ExcludeSemantics(
          child: Container(
            height: 48,
            width: 48,
            decoration: AppDecoration.gradient(
              colors: const [AppColors.primary, AppColors.secondary],
              radius: AppRadius.md,
              shadows: AppShadows.sm,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.surface,
              size: 23,
            ),
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
    final scoreSemantics = score <= 0
        ? 'Điểm sức khỏe hôm nay chưa đủ dữ liệu.'
        : 'Điểm sức khỏe hôm nay: $score trên 100. ${_scoreTitle(score)}.';

    final heroPadding = MediaQuery.sizeOf(context).width >= 720
        ? AppSpacing.cardPaddingLarge
        : AppSpacing.cardPadding;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: scoreSemantics,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(heroPadding),
        decoration: AppDecoration.gradient(
          colors: AppGradients.hero.colors,
          radius: AppRadius.lg,
          shadows: AppShadows.md,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stackHeader = constraints.maxWidth < 430 || textScale > 1.3;
            final headerContent = Column(
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
                  style: AppTextStyles.heading2.copyWith(
                    color: context.semanticColors.surface,
                    height: 1.24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _scoreMessage(score),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.semanticColors.surface.withValues(
                      alpha: .88,
                    ),
                    height: 1.45,
                  ),
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stackHeader) ...[
                  headerContent,
                  const SizedBox(height: AppSpacing.md),
                  _ScoreBadge(score: score),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: headerContent),
                      const SizedBox(width: AppSpacing.md),
                      _ScoreBadge(score: score),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: context.semanticColors.surface.withValues(
                        alpha: .2,
                      ),
                      valueColor: const AlwaysStoppedAnimation(AppColors.surface),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SnapshotMetricsWrap(metrics: metrics),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 86),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.semanticColors.surface.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.semanticColors.surface.withValues(alpha: .22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score <= 0 ? '--' : '$score',
              style: AppTextStyles.displaySmall.copyWith(
                color: context.semanticColors.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              score <= 0 ? 'chưa có' : 'điểm',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.semanticColors.surface.withValues(alpha: .82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotMetricsWrap extends StatelessWidget {
  final DashboardDailyMetrics metrics;

  const _SnapshotMetricsWrap({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final useTwoColumns = constraints.maxWidth >= 320 && textScale <= 1.35;
        final gap = AppSpacing.sm;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _SnapshotMetric(
                icon: Icons.favorite_rounded,
                label: 'Nhịp tim',
                value: metrics.heartRateBpm == null
                    ? 'Chưa có dữ liệu'
                    : '${metrics.heartRateBpm} bpm',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SnapshotMetric(
                icon: Icons.bloodtype_rounded,
                label: 'SpO₂',
                value: metrics.oxygenSaturation == null
                    ? 'Chưa có dữ liệu'
                    : '${metrics.oxygenSaturation!.toStringAsFixed(1)}%',
              ),
            ),
          ],
        );
      },
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
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.semanticColors.surface.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: context.semanticColors.surface, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.semanticColors.surface.withValues(
                          alpha: .72,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.semanticColors.surface,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final calorieHint = metrics.caloriesLogged > 0 ? 'đã ghi' : 'kcal kế hoạch';
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
        const _SectionTitle(
          title: 'Chỉ số hôm nay',
          subtitle: 'Các tín hiệu nhanh để bạn theo dõi nhịp chăm sóc trong ngày.',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final preferredMinWidth = textScale > 1.3
                ? 220.0
                : _healthMetricMinWidth;
            final gap = AppSpacing.sm;
            final fourColumnWidth = preferredMinWidth * 4 + gap * 3;
            final twoColumnWidth = preferredMinWidth * 2 + gap;
            final columns = constraints.maxWidth >= fourColumnWidth
                ? 4
                : constraints.maxWidth >= twoColumnWidth
                ? 2
                : 1;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  SizedBox(
                    width: itemWidth,
                    child: _HealthMetricTile(item: item),
                  ),
              ],
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
    final spokenValue = item.value == '--'
        ? 'chưa có dữ liệu'
        : '${item.value} ${item.unit}';

    return Semantics(
      container: true,
      label: '${item.label}: $spokenValue',
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.semanticColors.borderLight),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: item.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: AppTextStyles.labelSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          item.value,
                          style: AppTextStyles.heading4.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                          child: Text(item.unit, style: AppTextStyles.caption),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        message:
            'Khi có thêm tín hiệu sức khỏe, Nabi sẽ đặt điều đáng chú ý ở đây.',
      );
    }

    final primary = insights.first;
    final remaining = insights.skip(1).toList(growable: false);
    final riskLabel = _riskLabel(primary.riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Điều đáng chú ý',
          subtitle: 'Nabi ưu tiên tín hiệu quan trọng nhất để bạn đọc trước.',
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: '$riskLabel. ${primary.title}. ${primary.content}',
          child: _CompactSurface(
            accentColor: _riskColor(primary.riskLevel),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TintedIcon(
                    icon: _riskIcon(primary.riskLevel),
                    color: _riskColor(primary.riskLevel),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _RiskLabel(riskLevel: primary.riskLevel),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(primary.title, style: AppTextStyles.heading5),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          primary.content,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
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
            Divider(
              height: AppSpacing.md,
              color: context.semanticColors.borderLight,
            ),
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
    final label = _riskLabel(item.riskLevel);

    return Semantics(
      container: true,
      label: '$label. ${item.title}. ${item.content}',
      child: ExcludeSemantics(
        child: Row(
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
                    style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final action = primary.actionText.trim();
    final semantics = StringBuffer(
      'Việc nên làm hôm nay. ${primary.title}. ${primary.description}',
    );
    if (action.isNotEmpty) semantics.write('. Gợi ý: $action');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Việc nên làm hôm nay',
          subtitle: 'Một hành động nhỏ, dễ bắt đầu và phù hợp với nhịp hiện tại.',
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: semantics.toString(),
          child: _CompactSurface(
            accentColor: context.semanticColors.primary,
            backgroundColor: context.semanticColors.primarySubtle,
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TintedIcon(
                    icon: primary.isRead
                        ? Icons.lightbulb_outline_rounded
                        : Icons.lightbulb_rounded,
                    color: context.semanticColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: context.semanticColors.primarySoft,
                            borderRadius: BorderRadius.circular(
                              AppRadius.circular,
                            ),
                          ),
                          child: Text(
                            'Ưu tiên hôm nay',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: context.semanticColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(primary.title, style: AppTextStyles.heading5),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          primary.description,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        ),
                        if (action.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.semanticColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: context.semanticColors.primarySoft,
                              ),
                            ),
                            child: Text(
                              'Gợi ý: $action',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: context.semanticColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
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
            Divider(
              height: AppSpacing.md,
              color: context.semanticColors.borderLight,
            ),
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
    final action = item.actionText.trim();
    final semantics = StringBuffer('${item.title}. ${item.description}');
    if (action.isNotEmpty) semantics.write('. Gợi ý: $action');

    return Semantics(
      container: true,
      label: semantics.toString(),
      child: ExcludeSemantics(
        child: Row(
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
                    style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                  ),
                  if (action.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Gợi ý: $action',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.semanticColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Thông tin thêm',
          subtitle: 'Mở khi bạn muốn xem thêm các chỉ số và nội dung phụ.',
        ),
        const SizedBox(height: AppSpacing.md),
        _CompactExpansionPanel(
          title: 'Xem chi tiết',
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              _DetailRow(data: rows[index]),
              if (index != rows.length - 1)
                Divider(
                  height: AppSpacing.md,
                  color: context.semanticColors.borderLight,
                ),
            ],
          ],
        ),
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
    final spokenValue = data.value == '--' ? 'chưa có dữ liệu' : data.value;

    return Semantics(
      container: true,
      label: '${data.label}: $spokenValue',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                data.label,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                data.value,
                textAlign: TextAlign.end,
                style: AppTextStyles.labelLarge.copyWith(
                  color: context.semanticColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
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
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          0,
          AppSpacing.cardPadding,
          AppSpacing.cardPadding,
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
  final Color? backgroundColor;

  const _CompactSurface({
    required this.child,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          top: BorderSide(color: context.semanticColors.borderLight),
          right: BorderSide(color: context.semanticColors.borderLight),
          bottom: BorderSide(color: context.semanticColors.borderLight),
          left: BorderSide(
            color: accentColor ?? context.semanticColors.borderLight,
            width: accentColor == null ? 1 : 4,
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
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 20),
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
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_riskIcon(riskLevel), size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _riskLabel(riskLevel),
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.sectionTitle),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
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
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.semanticColors.borderLight),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TintedIcon(icon: icon, color: context.semanticColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.semanticColors.primarySubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
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
      child: _HealthInsightsContentShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBlock(height: 52, widthFactor: .68),
            const SizedBox(height: AppSpacing.sectionSpacing),
            const _SkeletonBlock(height: 238),
            const SizedBox(height: AppSpacing.sectionSpacing),
            const _SkeletonBlock(height: 150),
            const SizedBox(height: AppSpacing.sectionSpacing),
            const _SkeletonBlock(height: 180),
            const SizedBox(height: AppSpacing.sectionSpacing),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 420;
                final gap = AppSpacing.sm;
                final width = twoColumns
                    ? (constraints.maxWidth - gap) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(
                    4,
                    (_) => SizedBox(
                      width: width,
                      child: const _SkeletonBlock(height: 92),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
    return SingleChildScrollView(
      child: _HealthInsightsContentShell(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
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
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  header: true,
                  child: Text(
                    'Chưa thể mở góc sức khỏe',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Nabi chưa lấy được dữ liệu của bạn lúc này. Bạn có thể thử lại sau một chút.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
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
    return 'Nabi sẽ cập nhật khi có thêm ghi nhận trong ngày.';
  }
  return 'Điểm tổng hợp từ nhiệm vụ, bữa ăn, nước và giấc ngủ của bạn.';
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
