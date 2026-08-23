part of '../pages/other_page.dart';

const double _healthInsightsMaxContentWidth = 920;
const double _healthMetricMinWidth = 200;

enum _HealthSignalFilter { all, attention, progress, dataGap }

class _HealthInsightsContent extends StatelessWidget {
  final HealthInsightsEntity insights;
  final Future<void> Function() onRefresh;
  final ValueChanged<HealthInsightsRange> onRangeChanged;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _HealthInsightsContent({
    required this.insights,
    required this.onRefresh,
    required this.onRangeChanged,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HealthInsightsHeader(
          insights: insights,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: AppSpacing.md),
        _HealthDataStatusStrip(insights: insights),
        const SizedBox(height: AppSpacing.md),
        _HealthRangeSelector(
          selected: insights.range,
          onChanged: onRangeChanged,
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        if (!insights.hasAnyData)
          _HealthInsightsEmptyState(onOpenTarget: onOpenTarget)
        else ...[
          _HealthOverviewHero(insights: insights),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _WhatChangedSection(
            insights: insights,
            onOpenTarget: onOpenTarget,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _HealthSignalBoard(
            items: insights.signals,
            onOpenTarget: onOpenTarget,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _HealthMetricGrid(
            insights: insights,
            onOpenTarget: onOpenTarget,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _MissingDataAssistant(
            insights: insights,
            onOpenTarget: onOpenTarget,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _WeeklySummarySection(summary: insights.weeklySummary),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _HabitConsistencySection(summary: insights.habitSummary),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _HealthActionPlan(
            actions: insights.actions,
            onOpenTarget: onOpenTarget,
          ),
          if (insights.timeline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sectionSpacing),
            _RecentHealthTimeline(entries: insights.timeline),
          ],
          const SizedBox(height: AppSpacing.sectionSpacing),
          _HealthSafetyNote(insights: insights),
        ],
      ],
    );
  }
}

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
  final HealthInsightsEntity insights;
  final Future<void> Function() onRefresh;

  const _HealthInsightsHeader({
    required this.insights,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final name = _shortName(insights.fullName);
    final updated = insights.lastUpdatedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                        color: context.semanticColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    name.isEmpty
                        ? 'NanoBio đang gom những tín hiệu sức khỏe quan trọng nhất của bạn.'
                        : 'Chào $name, đây là bức tranh sức khỏe gần nhất của bạn.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.semanticColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: 'Cập nhật dữ liệu',
              child: IconButton.filledTonal(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ],
        ),
        if (updated != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: context.semanticColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Dữ liệu gần nhất: ${_formatDateTime(updated)}',
                  style: AppTextStyles.caption.copyWith(
                    color: context.semanticColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HealthDataStatusStrip extends StatelessWidget {
  final HealthInsightsEntity insights;

  const _HealthDataStatusStrip({required this.insights});

  @override
  Widget build(BuildContext context) {
    final freshness = insights.overallFreshness;
    final (icon, title, color, background) = switch (freshness) {
      HealthDataFreshness.today => (
        Icons.cloud_done_rounded,
        'Dữ liệu đã được cập nhật hôm nay',
        context.semanticColors.success,
        context.semanticColors.successSoft,
      ),
      HealthDataFreshness.recent => (
        Icons.history_rounded,
        'Một số dữ liệu chưa được cập nhật hôm nay',
        context.semanticColors.info,
        context.semanticColors.infoSoft,
      ),
      HealthDataFreshness.stale => (
        Icons.update_rounded,
        'Dữ liệu gần nhất đã cũ, nên cập nhật thêm',
        context.semanticColors.warning,
        context.semanticColors.warningSoft,
      ),
      HealthDataFreshness.missing => (
        Icons.add_chart_rounded,
        'Chưa có đủ dữ liệu theo dõi',
        context.semanticColors.primary,
        context.semanticColors.primarySoft,
      ),
    };

    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
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

class _HealthRangeSelector extends StatelessWidget {
  final HealthInsightsRange selected;
  final ValueChanged<HealthInsightsRange> onChanged;

  const _HealthRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Khoảng thời gian đang xem: ${selected.label}',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final range in HealthInsightsRange.values) ...[
              ChoiceChip(
                label: Text(range.label),
                selected: selected == range,
                onSelected: (_) => onChanged(range),
              ),
              if (range != HealthInsightsRange.values.last)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _HealthOverviewHero extends StatelessWidget {
  final HealthInsightsEntity insights;

  const _HealthOverviewHero({required this.insights});

  @override
  Widget build(BuildContext context) {
    final score = insights.healthScore;
    final scoreText = score == null ? 'Chưa đủ dữ liệu' : _scoreTitle(score);
    final completenessPercent = (insights.dataCompleteness * 100).round();
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      container: true,
      label: score == null
          ? 'Chưa đủ dữ liệu để hiển thị điểm chăm sóc.'
          : 'Điểm chăm sóc hiện tại $score trên 100. Độ đầy đủ dữ liệu $completenessPercent phần trăm.',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width >= 720
              ? AppSpacing.cardPaddingLarge
              : AppSpacing.cardPadding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.semanticColors.ctaStart,
              context.semanticColors.ctaEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 480 || textScale > 1.3;
            final scoreBlock = _HeroScoreBlock(insights: insights);
            final summaryBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG QUAN ${insights.range.label.toUpperCase()}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.semanticColors.onBrand.withValues(alpha: .82),
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  scoreText,
                  style: AppTextStyles.heading2.copyWith(
                    color: context.semanticColors.onBrand,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _scoreMessage(score),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.semanticColors.onBrand.withValues(alpha: .88),
                    height: 1.45,
                  ),
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stack) ...[
                  summaryBlock,
                  const SizedBox(height: AppSpacing.md),
                  scoreBlock,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: summaryBlock),
                      const SizedBox(width: AppSpacing.lg),
                      scoreBlock,
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),
                _HeroCompleteness(insights: insights),
                const SizedBox(height: AppSpacing.md),
                _HeroQuickFacts(insights: insights),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroScoreBlock extends StatelessWidget {
  final HealthInsightsEntity insights;

  const _HeroScoreBlock({required this.insights});

  @override
  Widget build(BuildContext context) {
    final score = insights.healthScore;
    final delta = insights.healthScoreDelta;
    final deltaText = delta == null
        ? 'Chưa đủ dữ liệu so sánh'
        : '${_signed(delta, decimals: 1)} điểm theo kỳ';

    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.semanticColors.onBrand.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.semanticColors.onBrand.withValues(alpha: .18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedHealthScore(
            score: score,
            previousScore: insights.previousHealthScore,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            deltaText,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.semanticColors.onBrand.withValues(alpha: .84),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedHealthScore extends StatefulWidget {
  final int? score;
  final int? previousScore;

  const _AnimatedHealthScore({
    required this.score,
    required this.previousScore,
  });

  @override
  State<_AnimatedHealthScore> createState() => _AnimatedHealthScoreState();
}

class _AnimatedHealthScoreState extends State<_AnimatedHealthScore> {
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _to = widget.score?.toDouble() ?? 0;
    _from = widget.previousScore?.toDouble() ?? _to;
  }

  @override
  void didUpdateWidget(covariant _AnimatedHealthScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.score?.toDouble() ?? 0;
    if (next != _to) {
      _from = _to;
      _to = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.score == null) {
      return Text(
        '--',
        style: AppTextStyles.displayLarge.copyWith(
          color: context.semanticColors.onBrand,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _from, end: _to),
      duration: disableAnimations ? Duration.zero : AppDuration.normal,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${value.round()}',
                style: AppTextStyles.displayLarge.copyWith(
                  color: context.semanticColors.onBrand,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: ' / 100',
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.semanticColors.onBrand.withValues(alpha: .78),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCompleteness extends StatelessWidget {
  final HealthInsightsEntity insights;

  const _HeroCompleteness({required this.insights});

  @override
  Widget build(BuildContext context) {
    final value = insights.dataCompleteness.clamp(0, 1).toDouble();
    final percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Độ đầy đủ dữ liệu',
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.semanticColors.onBrand,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: AppTextStyles.labelLarge.copyWith(
                color: context.semanticColors.onBrand,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: context.semanticColors.onBrand.withValues(alpha: .18),
            valueColor: AlwaysStoppedAnimation<Color>(
              context.semanticColors.onBrand,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${insights.coreMetricsAvailable}/${insights.coreMetricsExpected} chỉ số nền tảng có dữ liệu',
          style: AppTextStyles.caption.copyWith(
            color: context.semanticColors.onBrand.withValues(alpha: .78),
          ),
        ),
      ],
    );
  }
}

class _HeroQuickFacts extends StatelessWidget {
  final HealthInsightsEntity insights;

  const _HeroQuickFacts({required this.insights});

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String, String)>[
      (
        Icons.event_available_rounded,
        'Ngày có log',
        '${insights.weeklySummary.daysWithLogs}/7',
      ),
      (
        Icons.local_fire_department_rounded,
        'Chuỗi chăm sóc',
        '${insights.habitSummary.currentStreak} ngày',
      ),
      (
        Icons.monitor_weight_outlined,
        'BMI gần nhất',
        insights.bmi > 0 ? insights.bmi.toStringAsFixed(1) : '--',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 430;
        if (stack) {
          return Column(
            children: [
              for (var index = 0; index < facts.length; index++) ...[
                _HeroFact(
                  icon: facts[index].$1,
                  label: facts[index].$2,
                  value: facts[index].$3,
                ),
                if (index != facts.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < facts.length; index++) ...[
              Expanded(
                child: _HeroFact(
                  icon: facts[index].$1,
                  label: facts[index].$2,
                  value: facts[index].$3,
                ),
              ),
              if (index != facts.length - 1)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _HeroFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.semanticColors.onBrand.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: context.semanticColors.onBrand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: context.semanticColors.onBrand.withValues(alpha: .72),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: context.semanticColors.onBrand,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _WhatChangedSection extends StatelessWidget {
  final HealthInsightsEntity insights;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _WhatChangedSection({
    required this.insights,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final items = insights.changes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Điều thay đổi gần đây',
          subtitle: items.isEmpty
              ? 'NanoBio cần thêm dữ liệu ở hai giai đoạn để so sánh.'
              : 'So sánh dữ liệu của ${insights.range.label.toLowerCase()} với giai đoạn ngay trước đó.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const _CompactEmptySurface(
            icon: Icons.compare_arrows_rounded,
            title: 'Chưa đủ dữ liệu để so sánh',
            message:
                'Bạn vẫn có thể xem các giá trị gần nhất và tiếp tục ghi nhận như bình thường.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 3 : 1;
              final gap = AppSpacing.sm;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items.take(6))
                    SizedBox(
                      width: width,
                      child: _ChangeTile(
                        item: item,
                        range: insights.range,
                        onTap: () => onOpenTarget(_metricTarget(item.metric)),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ChangeTile extends StatelessWidget {
  final HealthChangeItem item;
  final HealthInsightsRange range;
  final VoidCallback onTap;

  const _ChangeTile({
    required this.item,
    required this.range,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _trendColor(context, item.direction);
    final label = _metricLabel(item.metric);
    final delta = _formatMetricDelta(item.metric, item.delta);
    final confidence = _confidenceLabel(item.confidence);

    return Semantics(
      button: true,
      label: '$label. $delta so với giai đoạn trước. $confidence.',
      child: Material(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 118),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.semanticColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        _trendIcon(item.direction),
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(label, style: AppTextStyles.labelLarge),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  delta,
                  style: AppTextStyles.heading4.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${range == HealthInsightsRange.today ? 'So với hôm qua' : 'So với kỳ trước'} · $confidence',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthSignalBoard extends StatefulWidget {
  final List<HealthSignalItem> items;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _HealthSignalBoard({
    required this.items,
    required this.onOpenTarget,
  });

  @override
  State<_HealthSignalBoard> createState() => _HealthSignalBoardState();
}

class _HealthSignalBoardState extends State<_HealthSignalBoard> {
  _HealthSignalFilter _filter = _HealthSignalFilter.all;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      return switch (_filter) {
        _HealthSignalFilter.all => true,
        _HealthSignalFilter.attention =>
          item.kind == HealthSignalKind.attention,
        _HealthSignalFilter.progress => item.kind == HealthSignalKind.progress,
        _HealthSignalFilter.dataGap => item.kind == HealthSignalKind.dataGap,
      };
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Tín hiệu sức khỏe',
          subtitle:
              'Ưu tiên điều cần chú ý, tiến bộ và những dữ liệu NanoBio còn thiếu.',
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _HealthSignalFilter.values) ...[
                ChoiceChip(
                  label: Text(_signalFilterLabel(filter)),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
                if (filter != _HealthSignalFilter.values.last)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          const _CompactEmptySurface(
            icon: Icons.check_circle_outline_rounded,
            title: 'Chưa có tín hiệu trong nhóm này',
            message: 'NanoBio sẽ cập nhật khi có thêm dữ liệu phù hợp.',
          )
        else
          Column(
            children: [
              for (var index = 0; index < filtered.length; index++) ...[
                _HealthSignalCard(
                  item: filtered[index],
                  onOpenTarget: widget.onOpenTarget,
                ),
                if (index != filtered.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _HealthSignalCard extends StatelessWidget {
  final HealthSignalItem item;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _HealthSignalCard({
    required this.item,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _signalColor(context, item.kind);
    final soft = _signalSoftColor(context, item.kind);
    final actionAvailable = item.actionTarget != HealthActionTarget.none;
    final sourceLabel = item.sourceLabel?.trim() ?? '';

    return Semantics(
      container: true,
      label:
          '${_signalKindLabel(item.kind)}. ${item.title}. ${item.message}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.semanticColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.semanticColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(
                _signalIcon(item.kind),
                size: 21,
                color: accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusPill(
                        label: _signalKindLabel(item.kind),
                        color: accent,
                        background: soft,
                      ),
                      if (sourceLabel.isNotEmpty)
                        _StatusPill(
                          label: sourceLabel,
                          color: context.semanticColors.primary,
                          background: context.semanticColors.primarySoft,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(item.title, style: AppTextStyles.heading5),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.message,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                  if (actionAvailable) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => onOpenTarget(item.actionTarget),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Xem chi tiết'),
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

class _HealthMetricGrid extends StatelessWidget {
  final HealthInsightsEntity insights;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _HealthMetricGrid({
    required this.insights,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Chỉ số của bạn',
          subtitle:
              '${insights.metrics.length} nhóm dữ liệu · ${insights.range.label} · chạm vào từng thẻ để xem lịch sử.',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final gap = AppSpacing.sm;
            final preferredColumns = constraints.maxWidth >= 860
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            final columns = scale > 1.45
                ? 1
                : scale > 1.25 && preferredColumns > 2
                ? 2
                : preferredColumns;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final metric in insights.metrics)
                  SizedBox(
                    width: width < _healthMetricMinWidth && columns > 1
                        ? constraints.maxWidth
                        : width,
                    child: _HealthMetricCard(
                      metric: metric,
                      range: insights.range,
                      onTap: () => _showMetricDetail(
                        context,
                        metric: metric,
                        range: insights.range,
                        onOpenTarget: onOpenTarget,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  final HealthMetricSummary metric;
  final HealthInsightsRange range;
  final VoidCallback onTap;

  const _HealthMetricCard({
    required this.metric,
    required this.range,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _metricColor(context, metric.type);
    final soft = _metricSoftColor(context, metric.type);
    final value = _formatMetricCurrent(metric);
    final trendText = metric.hasTrend
        ? _formatMetricDelta(metric.type, metric.delta ?? 0)
        : _freshnessLabel(metric.freshness);

    return Semantics(
      button: true,
      label:
          '${_metricLabel(metric.type)}. $value. $trendText. ${metric.sampleCount} mẫu trong ${range.label}.',
      child: Material(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 168),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.semanticColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Icon(
                        _metricIcon(metric.type),
                        size: 20,
                        color: accent,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 17,
                      color: context.semanticColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _metricLabel(metric.type),
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3.copyWith(
                    color: context.semanticColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (metric.series.length >= 2)
                  SizedBox(
                    height: 34,
                    child: _Sparkline(
                      points: metric.series,
                      color: accent,
                    ),
                  )
                else
                  Text(
                    'Chưa đủ điểm để vẽ xu hướng',
                    style: AppTextStyles.caption,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      metric.hasTrend
                          ? _trendIcon(metric.trend)
                          : Icons.schedule_rounded,
                      size: 15,
                      color: metric.hasTrend
                          ? _trendColor(context, metric.trend)
                          : context.semanticColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        trendText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: context.semanticColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingDataAssistant extends StatelessWidget {
  final HealthInsightsEntity insights;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _MissingDataAssistant({
    required this.insights,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final missing = insights.missingMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'NanoBio cần thêm dữ liệu gì?',
          subtitle:
              'Bổ sung những mục còn thiếu để bức tranh sức khỏe sát với bạn hơn.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (missing.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: context.semanticColors.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: context.semanticColors.success.withValues(alpha: .25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  color: context.semanticColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Các chỉ số nền tảng trong giai đoạn này đã có dữ liệu. Bạn chỉ cần tiếp tục duy trì ghi nhận đều.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.semanticColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.semanticColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.semanticColors.borderLight),
            ),
            child: Column(
              children: [
                for (var index = 0; index < missing.length; index++) ...[
                  _MissingMetricRow(
                    type: missing[index],
                    onTap: () => onOpenTarget(_metricTarget(missing[index])),
                  ),
                  if (index != missing.length - 1)
                    Divider(
                      height: 1,
                      color: context.semanticColors.divider,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MissingMetricRow extends StatelessWidget {
  final HealthMetricType type;
  final VoidCallback onTap;

  const _MissingMetricRow({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final target = _metricTarget(type);
    final canOpen = target != HealthActionTarget.none;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: _metricSoftColor(context, type),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Icon(
          _metricIcon(type),
          color: _metricColor(context, type),
          size: 20,
        ),
      ),
      title: Text(_metricLabel(type), style: AppTextStyles.labelLarge),
      subtitle: Text(
        'Chưa có dữ liệu đủ mới',
        style: AppTextStyles.bodySmall,
      ),
      trailing: canOpen
          ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
          : null,
      onTap: canOpen ? onTap : null,
    );
  }
}

class _WeeklySummarySection extends StatelessWidget {
  final HealthWeeklySummary summary;

  const _WeeklySummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final averageScore = summary.averageScore;
    final averageSleep = summary.averageSleepHours;
    final averageWater = summary.averageWaterMl;
    final averageSteps = summary.averageSteps;
    final taskRate = summary.taskCompletionRate;
    final mealRate = summary.mealCompletionRate;
    final items = <_SummaryStatData>[
      _SummaryStatData(
        icon: Icons.health_and_safety_outlined,
        label: 'Điểm TB',
        value: averageScore == null ? '--' : averageScore.round().toString(),
      ),
      _SummaryStatData(
        icon: Icons.bedtime_outlined,
        label: 'Ngủ TB',
        value: averageSleep == null
            ? '--'
            : '${averageSleep.toStringAsFixed(1)} giờ',
      ),
      _SummaryStatData(
        icon: Icons.water_drop_outlined,
        label: 'Nước TB',
        value: averageWater == null ? '--' : _formatWater(averageWater),
      ),
      _SummaryStatData(
        icon: Icons.directions_walk_rounded,
        label: 'Bước TB',
        value: averageSteps == null
            ? '--'
            : _formatInteger(averageSteps.round()),
      ),
      _SummaryStatData(
        icon: Icons.task_alt_rounded,
        label: 'Nhiệm vụ',
        value: taskRate == null ? '--' : '${(taskRate * 100).round()}%',
      ),
      _SummaryStatData(
        icon: Icons.restaurant_rounded,
        label: 'Thực đơn',
        value: mealRate == null ? '--' : '${(mealRate * 100).round()}%',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Tổng kết 7 ngày',
          subtitle:
              '${summary.daysWithLogs}/7 ngày có dữ liệu${summary.bestScore == null ? '' : ' · điểm cao nhất ${summary.bestScore}'}',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 480
                ? 2
                : 1;
            final gap = AppSpacing.sm;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _SummaryStat(data: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SummaryStatData {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStatData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SummaryStat extends StatelessWidget {
  final _SummaryStatData data;

  const _SummaryStat({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 21, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.label, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  data.value,
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _HabitConsistencySection extends StatelessWidget {
  final HealthHabitSummary summary;

  const _HabitConsistencySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Nhịp tự chăm sóc',
            subtitle: 'Theo dõi sự đều đặn thay vì chỉ nhìn một ngày riêng lẻ.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ConsistencyBadge(
                icon: Icons.local_fire_department_rounded,
                label: 'Chuỗi hiện tại',
                value: '${summary.currentStreak} ngày',
              ),
              _ConsistencyBadge(
                icon: Icons.calendar_month_rounded,
                label: '7 ngày gần nhất',
                value: '${summary.careDays7}/7 ngày',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ConsistencyProgress(
            label: 'Hoàn thành nhiệm vụ',
            value: summary.taskCompletionRate7,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConsistencyProgress(
            label: 'Hoàn thành thực đơn',
            value: summary.mealCompletionRate7,
          ),
        ],
      ),
    );
  }
}

class _ConsistencyBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConsistencyBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(value, style: AppTextStyles.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyProgress extends StatelessWidget {
  final String label;
  final double? value;

  const _ConsistencyProgress({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value?.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.labelMedium)),
            Text(
              safeValue == null ? '--' : '${(safeValue * 100).round()}%',
              style: AppTextStyles.labelLarge.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: LinearProgressIndicator(
            value: safeValue ?? 0,
            minHeight: 7,
            backgroundColor: context.semanticColors.surfaceSoft,
            valueColor: AlwaysStoppedAnimation<Color>(
              context.semanticColors.success,
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthActionPlan extends StatelessWidget {
  final List<HealthActionItem> actions;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _HealthActionPlan({
    required this.actions,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Hôm nay nên làm gì?',
          subtitle:
              'Tối đa ba hành động rõ ràng, dựa trên dữ liệu và gợi ý đã có trong NanoBio.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (actions.isEmpty)
          const _CompactEmptySurface(
            icon: Icons.self_improvement_rounded,
            title: 'Chưa có hành động ưu tiên mới',
            message:
                'Bạn có thể tiếp tục lịch trình hiện tại và cập nhật dữ liệu khi thuận tiện.',
          )
        else
          Column(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                _ActionCard(
                  index: index,
                  item: actions[index],
                  onTap: actions[index].target == HealthActionTarget.none
                      ? null
                      : () => onOpenTarget(actions[index].target),
                ),
                if (index != actions.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final int index;
  final HealthActionItem item;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.index,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: index == 0
            ? context.semanticColors.primarySubtle
            : context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: index == 0
              ? context.semanticColors.primary.withValues(alpha: .2)
              : context.semanticColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.semanticColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.labelLarge.copyWith(
                color: context.semanticColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!item.isRead)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      'Ưu tiên',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.semanticColors.primary,
                      ),
                    ),
                  ),
                Text(item.title, style: AppTextStyles.heading5),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.description,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(item.actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentHealthTimeline extends StatelessWidget {
  final List<HealthTimelineEntry> entries;

  const _RecentHealthTimeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Hoạt động sức khỏe hôm nay',
          subtitle: 'Nhìn nhanh những việc đã hoàn thành và còn đang chờ.',
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: context.semanticColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: context.semanticColors.borderLight),
          ),
          child: Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                _TimelineRow(entry: entries[index]),
                if (index != entries.length - 1)
                  Divider(
                    height: 1,
                    color: context.semanticColors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final HealthTimelineEntry entry;

  const _TimelineRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.isCompleted
        ? context.semanticColors.success
        : context.semanticColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Icon(
          entry.isCompleted ? Icons.check_rounded : Icons.schedule_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(entry.title, style: AppTextStyles.labelLarge),
      subtitle: entry.subtitle.trim().isEmpty
          ? null
          : Text(entry.subtitle, style: AppTextStyles.bodySmall),
      trailing: Text(entry.timeLabel, style: AppTextStyles.caption),
    );
  }
}

class _HealthSafetyNote extends StatelessWidget {
  final HealthInsightsEntity insights;

  const _HealthSafetyNote({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: context.semanticColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Các xu hướng ở đây dùng dữ liệu bạn đã ghi nhận trong NanoBio để giúp theo dõi thói quen và thay đổi theo thời gian. Chúng không phải chẩn đoán hay kết luận y khoa.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthInsightsEmptyState extends StatelessWidget {
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _HealthInsightsEmptyState({required this.onOpenTarget});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: context.semanticColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 30,
              color: context.semanticColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bắt đầu bức tranh sức khỏe của bạn',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chưa có đủ dữ liệu để tạo xu hướng. Hãy thêm vài ghi nhận cơ bản; NanoBio sẽ dần cho bạn thấy những thay đổi theo thời gian.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    onOpenTarget(HealthActionTarget.healthTracking),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Bắt đầu ghi nhận'),
              ),
              OutlinedButton.icon(
                onPressed: () => onOpenTarget(HealthActionTarget.bodyMetrics),
                icon: const Icon(Icons.straighten_rounded),
                label: const Text('Chỉ số cơ thể'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(
            color: context.semanticColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.sectionSubtitle.copyWith(
            color: context.semanticColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _CompactEmptySurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompactEmptySurface({
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
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.semanticColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
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
      child: _HealthInsightsContentShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBox(height: 34, widthFactor: .45),
            const SizedBox(height: AppSpacing.sm),
            const _SkeletonBox(height: 18, widthFactor: .8),
            const SizedBox(height: AppSpacing.sectionSpacing),
            const _SkeletonBox(height: 220),
            const SizedBox(height: AppSpacing.sectionSpacing),
            const _SkeletonBox(height: 118),
            const SizedBox(height: AppSpacing.sm),
            const _SkeletonBox(height: 118),
            const SizedBox(height: AppSpacing.sectionSpacing),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 560 ? 2 : 1;
                final gap = AppSpacing.sm;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var index = 0; index < 4; index++)
                      SizedBox(
                        width: width,
                        child: const _SkeletonBox(height: 168),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double widthFactor;

  const _SkeletonBox({required this.height, this.widthFactor = 1});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.semanticColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
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
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
            decoration: BoxDecoration(
              color: context.semanticColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.semanticColors.borderLight),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: context.semanticColors.warning,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Chưa tải được Góc sức khỏe',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dữ liệu của bạn vẫn được giữ nguyên. Hãy thử cập nhật lại sau một chút.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
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

Future<void> _showMetricDetail(
  BuildContext context, {
  required HealthMetricSummary metric,
  required HealthInsightsRange range,
  required ValueChanged<HealthActionTarget> onOpenTarget,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _MetricDetailSheet(
        metric: metric,
        range: range,
        onOpenTarget: (target) {
          Navigator.of(sheetContext).pop();
          onOpenTarget(target);
        },
      );
    },
  );
}

class _MetricDetailSheet extends StatelessWidget {
  final HealthMetricSummary metric;
  final HealthInsightsRange range;
  final ValueChanged<HealthActionTarget> onOpenTarget;

  const _MetricDetailSheet({
    required this.metric,
    required this.range,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _metricColor(context, metric.type);
    final target = _metricTarget(metric.type);
    final canOpen = target != HealthActionTarget.none;
    final latestRecordedAt = metric.latestRecordedAt;

    return FractionallySizedBox(
      heightFactor: .88,
      child: Container(
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.bottomSheetPadding,
            AppSpacing.sm,
            AppSpacing.bottomSheetPadding,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: context.semanticColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: _metricSoftColor(context, metric.type),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      _metricIcon(metric.type),
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _metricLabel(metric.type),
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${range.label} · ${_freshnessLabel(metric.freshness)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _formatMetricCurrent(metric),
                style: AppTextStyles.displayMedium.copyWith(
                  color: context.semanticColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                latestRecordedAt == null
                    ? 'Chưa có thời điểm ghi nhận'
                    : 'Ghi nhận gần nhất: ${_formatDateTime(latestRecordedAt)}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _MetricChartPanel(metric: metric, range: range),
              const SizedBox(height: AppSpacing.md),
              _MetricStatistics(metric: metric),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: context.semanticColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chất lượng dữ liệu', style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${metric.sampleCount} mẫu trong ${range.label} · ${_confidenceLabel(metric.confidence)} · ${_freshnessLabel(metric.freshness)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Nguồn: dữ liệu đã ghi nhận trong NanoBio. Xu hướng chỉ dùng để so sánh theo thời gian và không phải kết luận y khoa.',
                      style: AppTextStyles.caption.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              if (canOpen) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => onOpenTarget(target),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_metricActionLabel(metric.type)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChartPanel extends StatelessWidget {
  final HealthMetricSummary metric;
  final HealthInsightsRange range;

  const _MetricChartPanel({required this.metric, required this.range});

  @override
  Widget build(BuildContext context) {
    if (metric.series.length < 2) {
      return const _CompactEmptySurface(
        icon: Icons.show_chart_rounded,
        title: 'Chưa đủ dữ liệu để vẽ xu hướng',
        message:
            'Cần ít nhất hai điểm ghi nhận trong khoảng thời gian đang xem.',
      );
    }

    return Semantics(
      container: true,
      label:
          'Biểu đồ ${_metricLabel(metric.type)} trong ${range.label}. ${metric.sampleCount} điểm dữ liệu.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.semanticColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.semanticColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xu hướng ${range.label.toLowerCase()}', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 150,
              child: _Sparkline(
                points: metric.series,
                color: _metricColor(context, metric.type),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              metric.hasTrend
                  ? '${_trendLabel(metric.trend)} ${_formatMetricDelta(metric.type, metric.delta ?? 0)} so với kỳ trước.'
                  : 'Chưa đủ dữ liệu kỳ trước để so sánh đáng tin cậy.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricStatistics extends StatelessWidget {
  final HealthMetricSummary metric;

  const _MetricStatistics({required this.metric});

  @override
  Widget build(BuildContext context) {
    final stats = <(String, String)>[
      ('Trung bình', _formatMetricNumber(metric.type, metric.periodAverage)),
      ('Thấp nhất', _formatMetricNumber(metric.type, metric.minimum)),
      ('Cao nhất', _formatMetricNumber(metric.type, metric.maximum)),
      (
        'So với kỳ trước',
        metric.delta == null
            ? '--'
            : _formatMetricDelta(metric.type, metric.delta ?? 0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 440 ? 2 : 1;
        final gap = AppSpacing.sm;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: context.semanticColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(color: context.semanticColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.$1, style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        stat.$2,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<HealthMetricPoint> points;
  final Color color;
  final double strokeWidth;

  const _Sparkline({
    required this.points,
    required this.color,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _SparklinePainter(
          values: points.map((item) => item.value).toList(growable: false),
          color: color,
          strokeWidth: strokeWidth,
          gridColor: context.semanticColors.borderLight,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final Color gridColor;

  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    var minValue = values.first;
    var maxValue = values.first;
    for (final value in values.skip(1)) {
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * .5),
      Offset(size.width, size.height * .5),
      gridPaint,
    );

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final horizontalStep = size.width / (values.length - 1);
    final range = maxValue - minValue;
    final path = Path();

    for (var index = 0; index < values.length; index++) {
      final normalized = range.abs() < .000001
          ? .5
          : (values[index] - minValue) / range;
      final x = index * horizontalStep;
      final y = size.height - normalized * (size.height - 10) - 5;
      final point = Offset(x, y);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(point, strokeWidth + 1, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gridColor != gridColor;
  }
}

String _shortName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? '' : parts.last;
}

String _scoreTitle(int? score) {
  if (score == null || score <= 0) return 'Chưa đủ dữ liệu';
  if (score >= 85) return 'Nhịp chăm sóc đang rất đều';
  if (score >= 70) return 'Bạn đang duy trì khá tốt';
  if (score >= 50) return 'Còn vài điểm có thể cải thiện';
  return 'Hôm nay nên ưu tiên chăm sóc bản thân hơn';
}

String _scoreMessage(int? score) {
  if (score == null || score <= 0) {
    return 'Thêm một vài ghi nhận cơ bản để NanoBio tổng hợp bức tranh rõ hơn.';
  }
  if (score >= 85) {
    return 'Hãy xem các xu hướng bên dưới để biết điều gì đang giúp bạn giữ nhịp tốt.';
  }
  if (score >= 70) {
    return 'Một vài thói quen đang được duy trì đều. NanoBio sẽ chỉ ra phần thay đổi đáng chú ý nhất.';
  }
  if (score >= 50) {
    return 'Đừng cố thay đổi mọi thứ cùng lúc. Hãy bắt đầu từ một hành động nhỏ trong phần ưu tiên hôm nay.';
  }
  return 'Điểm này phản ánh dữ liệu và nhịp chăm sóc đã ghi nhận, không phải chẩn đoán sức khỏe.';
}

String _metricLabel(HealthMetricType type) {
  return switch (type) {
    HealthMetricType.healthScore => 'Điểm chăm sóc',
    HealthMetricType.sleep => 'Giấc ngủ',
    HealthMetricType.water => 'Nước',
    HealthMetricType.steps => 'Bước chân',
    HealthMetricType.calories => 'Năng lượng',
    HealthMetricType.stress => 'Căng thẳng',
    HealthMetricType.weight => 'Cân nặng',
    HealthMetricType.heartRate => 'Nhịp tim',
    HealthMetricType.oxygen => 'SpO₂',
    HealthMetricType.mood => 'Tâm trạng',
    HealthMetricType.taskCompletion => 'Nhiệm vụ',
    HealthMetricType.mealCompletion => 'Thực đơn',
  };
}

IconData _metricIcon(HealthMetricType type) {
  return switch (type) {
    HealthMetricType.healthScore => Icons.health_and_safety_rounded,
    HealthMetricType.sleep => Icons.bedtime_rounded,
    HealthMetricType.water => Icons.water_drop_rounded,
    HealthMetricType.steps => Icons.directions_walk_rounded,
    HealthMetricType.calories => Icons.local_fire_department_rounded,
    HealthMetricType.stress => Icons.psychology_alt_rounded,
    HealthMetricType.weight => Icons.monitor_weight_rounded,
    HealthMetricType.heartRate => Icons.favorite_rounded,
    HealthMetricType.oxygen => Icons.bloodtype_rounded,
    HealthMetricType.mood => Icons.sentiment_satisfied_alt_rounded,
    HealthMetricType.taskCompletion => Icons.task_alt_rounded,
    HealthMetricType.mealCompletion => Icons.restaurant_rounded,
  };
}

Color _metricColor(BuildContext context, HealthMetricType type) {
  return switch (type) {
    HealthMetricType.healthScore => context.semanticColors.primary,
    HealthMetricType.sleep => context.semanticColors.secondary,
    HealthMetricType.water => context.semanticColors.info,
    HealthMetricType.steps => context.semanticColors.success,
    HealthMetricType.calories => context.semanticColors.warning,
    HealthMetricType.stress => context.semanticColors.secondary,
    HealthMetricType.weight => context.semanticColors.tertiary,
    HealthMetricType.heartRate => context.semanticColors.brandAccent,
    HealthMetricType.oxygen => context.semanticColors.info,
    HealthMetricType.mood => context.semanticColors.brandAccent,
    HealthMetricType.taskCompletion => context.semanticColors.success,
    HealthMetricType.mealCompletion => context.semanticColors.warning,
  };
}

Color _metricSoftColor(BuildContext context, HealthMetricType type) {
  return switch (type) {
    HealthMetricType.healthScore => context.semanticColors.primarySoft,
    HealthMetricType.sleep => context.semanticColors.secondarySoft,
    HealthMetricType.water => context.semanticColors.infoSoft,
    HealthMetricType.steps => context.semanticColors.successSoft,
    HealthMetricType.calories => context.semanticColors.warningSoft,
    HealthMetricType.stress => context.semanticColors.secondarySoft,
    HealthMetricType.weight => context.semanticColors.tertiarySoft,
    HealthMetricType.heartRate => context.semanticColors.primarySubtle,
    HealthMetricType.oxygen => context.semanticColors.infoSoft,
    HealthMetricType.mood => context.semanticColors.primarySubtle,
    HealthMetricType.taskCompletion => context.semanticColors.successSoft,
    HealthMetricType.mealCompletion => context.semanticColors.warningSoft,
  };
}

HealthActionTarget _metricTarget(HealthMetricType type) {
  return switch (type) {
    HealthMetricType.healthScore => HealthActionTarget.weeklySummary,
    HealthMetricType.sleep => HealthActionTarget.sleepTracking,
    HealthMetricType.water => HealthActionTarget.waterTracking,
    HealthMetricType.steps => HealthActionTarget.healthTracking,
    HealthMetricType.calories => HealthActionTarget.mealPlan,
    HealthMetricType.stress => HealthActionTarget.stressTracking,
    HealthMetricType.weight => HealthActionTarget.bodyMetrics,
    HealthMetricType.heartRate => HealthActionTarget.healthTracking,
    HealthMetricType.oxygen => HealthActionTarget.healthTracking,
    HealthMetricType.mood => HealthActionTarget.healthTracking,
    HealthMetricType.taskCompletion => HealthActionTarget.lifestyleSchedule,
    HealthMetricType.mealCompletion => HealthActionTarget.mealPlan,
  };
}

String _metricActionLabel(HealthMetricType type) {
  return switch (type) {
    HealthMetricType.healthScore => 'Xem tổng kết tuần',
    HealthMetricType.sleep => 'Mở theo dõi giấc ngủ',
    HealthMetricType.water => 'Cập nhật lượng nước',
    HealthMetricType.steps => 'Mở theo dõi sức khỏe',
    HealthMetricType.calories => 'Mở thực đơn',
    HealthMetricType.stress => 'Mở theo dõi căng thẳng',
    HealthMetricType.weight => 'Mở chỉ số cơ thể',
    HealthMetricType.heartRate => 'Mở theo dõi sức khỏe',
    HealthMetricType.oxygen => 'Mở theo dõi sức khỏe',
    HealthMetricType.mood => 'Ghi nhận tâm trạng',
    HealthMetricType.taskCompletion => 'Mở lịch trình',
    HealthMetricType.mealCompletion => 'Mở thực đơn',
  };
}

String _formatMetricCurrent(HealthMetricSummary metric) {
  if (metric.type == HealthMetricType.mood) {
    final text = metric.currentText?.trim() ?? '';
    return text.isEmpty ? 'Chưa có dữ liệu' : _moodLabel(text);
  }
  return _formatMetricNumber(metric.type, metric.currentValue);
}

String _formatMetricNumber(HealthMetricType type, double? value) {
  if (value == null || !value.isFinite) return '--';
  return switch (type) {
    HealthMetricType.healthScore => '${value.round()} / 100',
    HealthMetricType.sleep => '${value.toStringAsFixed(1)} giờ',
    HealthMetricType.water => _formatWater(value),
    HealthMetricType.steps => '${_formatInteger(value.round())} bước',
    HealthMetricType.calories => '${_formatInteger(value.round())} kcal',
    HealthMetricType.stress => '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} mức',
    HealthMetricType.weight => '${value.toStringAsFixed(1)} kg',
    HealthMetricType.heartRate => '${value.round()} bpm',
    HealthMetricType.oxygen => '${value.toStringAsFixed(1)}%',
    HealthMetricType.mood => '--',
    HealthMetricType.taskCompletion || HealthMetricType.mealCompletion =>
      '${(value * 100).round()}%',
  };
}

String _formatMetricDelta(HealthMetricType type, double delta) {
  return switch (type) {
    HealthMetricType.healthScore => '${_signed(delta, decimals: 1)} điểm',
    HealthMetricType.sleep => '${_signed(delta, decimals: 1)} giờ',
    HealthMetricType.water => '${_signed(delta, decimals: 0)} ml',
    HealthMetricType.steps => '${_signed(delta, decimals: 0)} bước',
    HealthMetricType.calories => '${_signed(delta, decimals: 0)} kcal',
    HealthMetricType.stress => '${_signed(delta, decimals: 1)} mức',
    HealthMetricType.weight => '${_signed(delta, decimals: 1)} kg',
    HealthMetricType.heartRate => '${_signed(delta, decimals: 1)} bpm',
    HealthMetricType.oxygen => '${_signed(delta, decimals: 1)}%',
    HealthMetricType.mood => '--',
    HealthMetricType.taskCompletion || HealthMetricType.mealCompletion =>
      '${_signed(delta * 100, decimals: 0)}%',
  };
}

String _formatWater(double ml) {
  if (ml.abs() >= 1000) return '${(ml / 1000).toStringAsFixed(1)} L';
  return '${ml.round()} ml';
}

String _signed(double value, {required int decimals}) {
  final formatted = value.abs().toStringAsFixed(decimals);
  if (value > 0) return '+$formatted';
  if (value < 0) return '-$formatted';
  return decimals == 0 ? '0' : (0.0).toStringAsFixed(decimals);
}

String _formatInteger(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} · $hour:$minute';
}

String _moodLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'great' || 'very_good' || 'excellent' => 'Rất tốt',
    'good' || 'happy' => 'Tốt',
    'okay' || 'normal' || 'neutral' => 'Bình thường',
    'tired' || 'low' => 'Hơi mệt',
    'bad' || 'sad' => 'Không tốt',
    _ => value,
  };
}

IconData _trendIcon(HealthTrendDirection direction) {
  return switch (direction) {
    HealthTrendDirection.up => Icons.trending_up_rounded,
    HealthTrendDirection.down => Icons.trending_down_rounded,
    HealthTrendDirection.stable => Icons.trending_flat_rounded,
    HealthTrendDirection.unknown => Icons.remove_rounded,
  };
}

String _trendLabel(HealthTrendDirection direction) {
  return switch (direction) {
    HealthTrendDirection.up => 'Tăng',
    HealthTrendDirection.down => 'Giảm',
    HealthTrendDirection.stable => 'Ổn định',
    HealthTrendDirection.unknown => 'Chưa rõ xu hướng',
  };
}

Color _trendColor(BuildContext context, HealthTrendDirection direction) {
  return switch (direction) {
    HealthTrendDirection.up => context.semanticColors.info,
    HealthTrendDirection.down => context.semanticColors.warning,
    HealthTrendDirection.stable => context.semanticColors.success,
    HealthTrendDirection.unknown => context.semanticColors.textMuted,
  };
}

String _freshnessLabel(HealthDataFreshness freshness) {
  return switch (freshness) {
    HealthDataFreshness.today => 'Cập nhật hôm nay',
    HealthDataFreshness.recent => 'Dữ liệu gần đây',
    HealthDataFreshness.stale => 'Dữ liệu đã cũ',
    HealthDataFreshness.missing => 'Chưa có dữ liệu',
  };
}

String _confidenceLabel(HealthInsightConfidence confidence) {
  return switch (confidence) {
    HealthInsightConfidence.high => 'Đủ dữ liệu',
    HealthInsightConfidence.medium => 'Dữ liệu khá ổn',
    HealthInsightConfidence.low => 'Dữ liệu còn ít',
    HealthInsightConfidence.insufficient => 'Chưa đủ dữ liệu',
  };
}

String _signalFilterLabel(_HealthSignalFilter filter) {
  return switch (filter) {
    _HealthSignalFilter.all => 'Tất cả',
    _HealthSignalFilter.attention => 'Cần chú ý',
    _HealthSignalFilter.progress => 'Tiến bộ',
    _HealthSignalFilter.dataGap => 'Thiếu dữ liệu',
  };
}

String _signalKindLabel(HealthSignalKind kind) {
  return switch (kind) {
    HealthSignalKind.attention => 'Cần chú ý',
    HealthSignalKind.progress => 'Bạn đang làm tốt',
    HealthSignalKind.dataGap => 'Thiếu dữ liệu',
    HealthSignalKind.info => 'Thông tin',
  };
}

IconData _signalIcon(HealthSignalKind kind) {
  return switch (kind) {
    HealthSignalKind.attention => Icons.visibility_outlined,
    HealthSignalKind.progress => Icons.trending_up_rounded,
    HealthSignalKind.dataGap => Icons.add_chart_rounded,
    HealthSignalKind.info => Icons.auto_awesome_rounded,
  };
}

Color _signalColor(BuildContext context, HealthSignalKind kind) {
  return switch (kind) {
    HealthSignalKind.attention => context.semanticColors.warning,
    HealthSignalKind.progress => context.semanticColors.success,
    HealthSignalKind.dataGap => context.semanticColors.info,
    HealthSignalKind.info => context.semanticColors.primary,
  };
}

Color _signalSoftColor(BuildContext context, HealthSignalKind kind) {
  return switch (kind) {
    HealthSignalKind.attention => context.semanticColors.warningSoft,
    HealthSignalKind.progress => context.semanticColors.successSoft,
    HealthSignalKind.dataGap => context.semanticColors.infoSoft,
    HealthSignalKind.info => context.semanticColors.primarySoft,
  };
}
