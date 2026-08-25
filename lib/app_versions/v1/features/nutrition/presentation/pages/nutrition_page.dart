import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_intelligence_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:nano_app/core/theme/theme.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(nutritionSummaryProvider);
    final intelligenceAsync = ref.watch(nutritionIntelligenceProvider);
    final aiAsync = ref.watch(nutritionAiReportProvider);

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      body: SafeArea(
        child: AppStateSwitcher(
          alignment: Alignment.topCenter,
          child: summaryAsync.when(
            loading: () => const _NutritionLoadingState(
              key: ValueKey('nutrition-loading'),
            ),
            error: (_, __) => _NutritionStateCard(
              key: const ValueKey('nutrition-error'),
              icon: Icons.spa_rounded,
              title: 'Nabi chưa mở được góc dinh dưỡng của bạn',
              message: 'Dữ liệu bữa ăn chưa sẵn sàng. Bạn thử làm mới nhé.',
              actionLabel: 'Thử lại',
              onAction: () => _refresh(ref),
            ),
            data: (summary) => _NutritionReady(
              summary: summary,
              intelligenceAsync: intelligenceAsync,
              aiAsync: aiAsync,
              onRefresh: () => _refresh(ref),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    ref.invalidate(nutritionDataBundleProvider);
    try {
      await ref.read(nutritionSummaryProvider.future);
      AppFeedbackService.instance.emit(AppFeedbackType.success);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      rethrow;
    }
  }
}

class _NutritionReady extends ConsumerWidget {
  const _NutritionReady({
    required this.summary,
    required this.intelligenceAsync,
    required this.aiAsync,
    required this.onRefresh,
  });

  final NutritionSummary summary;
  final AsyncValue<NutritionIntelligence> intelligenceAsync;
  final AsyncValue<NutritionAiReport> aiAsync;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      key: const ValueKey('nutrition-ready'),
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              AppSpacing.xxxxl + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        summary: summary,
                        intelligenceAsync: intelligenceAsync,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DateNavigator(
                        selectedDate: summary.selectedDate,
                        onChanged: (date) {
                          final normalized = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          ref
                              .read(selectedNutritionDateProvider.notifier)
                              .setDate(normalized);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      const _NutritionProfileEntryCard(),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _AiNutritionSection(aiAsync: aiAsync),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _SummaryWrap(
                        summary: summary,
                        intelligenceAsync: intelligenceAsync,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _IntelligenceSection(
                        intelligenceAsync: intelligenceAsync,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _ActionSection(aiAsync: aiAsync),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _MealPlanSection(
                        meals: summary.todayMeals,
                        selectedDate: summary.selectedDate,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _NutritionLogSection(
                        logs: summary.todayLogs,
                        selectedDate: summary.selectedDate,
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.summary, required this.intelligenceAsync});

  final NutritionSummary summary;
  final AsyncValue<NutritionIntelligence> intelligenceAsync;

  @override
  Widget build(BuildContext context) {
    final displayName = summary.fullName.trim().isEmpty
        ? 'bạn'
        : summary.fullName.trim();
    final planned = summary.plannedCalories;
    final logged = summary.loggedCalories;
    final progress = planned <= 0
        ? 0.0
        : (logged / planned).clamp(0.0, 1.0).toDouble();
    final quality = intelligenceAsync.asData?.value.dataQuality;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      decoration: AppDecoration.gradient(
        colors: AppGradients.health.colors,
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dinh dưỡng thông minh',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Nabi đang ghép bữa ăn, thực đơn và tín hiệu sức khỏe của $displayName thành một bức tranh dễ hiểu.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.surface.withValues(alpha: .92),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(
                icon: Icons.local_fire_department_rounded,
                label: planned > 0 ? '$logged / $planned kcal' : '$logged kcal',
              ),
              if (quality != null)
                _HeroChip(
                  icon: Icons.fact_check_rounded,
                  label: 'Dữ liệu ${quality.score}/100 · ${quality.level}',
                ),
              _HeroChip(
                icon: Icons.calendar_today_rounded,
                label: _friendlyDate(summary.selectedDate),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surface.withValues(alpha: .2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.surface.withValues(alpha: .95),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            planned > 0
                ? 'Thanh tiến độ so với thực đơn trong app, không phải ngưỡng y khoa.'
                : 'Chưa có thực đơn làm mốc so sánh cho ngày này.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.surface.withValues(alpha: .82),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surface.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.surface),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.surface),
          ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.selectedDate, required this.onChanged});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstAllowed = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 365));
    final lastAllowed = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 90));

    Future<void> chooseDate() async {
      final safeInitial = selectedDate.isBefore(firstAllowed)
          ? firstAllowed
          : selectedDate.isAfter(lastAllowed)
          ? lastAllowed
          : selectedDate;
      final picked = await showDatePicker(
        context: context,
        initialDate: safeInitial,
        firstDate: firstAllowed,
        lastDate: lastAllowed,
        helpText: 'Chọn ngày dinh dưỡng',
      );
      if (picked != null) onChanged(picked);
    }

    return Semantics(
      container: true,
      label: 'Chọn ngày phân tích dinh dưỡng',
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Ngày trước',
            onPressed: selectedDate.isAfter(firstAllowed)
                ? () =>
                      onChanged(selectedDate.subtract(const Duration(days: 1)))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: chooseDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(_friendlyDate(selectedDate)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: 'Ngày sau',
            onPressed: selectedDate.isBefore(lastAllowed)
                ? () => onChanged(selectedDate.add(const Duration(days: 1)))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _AiNutritionSection extends StatelessWidget {
  const _AiNutritionSection({required this.aiAsync});

  final AsyncValue<NutritionAiReport> aiAsync;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.semanticColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.semanticColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nabi phân tích', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'AI chỉ diễn giải các chỉ số app đã tính và dữ liệu bạn đã cung cấp.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          aiAsync.when(
            loading: () => const _InlineLoading(
              label: 'Nabi đang nối các tín hiệu dinh dưỡng…',
            ),
            error: (_, __) => Text(
              'Phân tích AI chưa sẵn sàng. Các chỉ số tính bằng app bên dưới vẫn dùng được bình thường.',
              style: AppTextStyles.bodyMedium,
            ),
            data: (report) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.summary,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
                if (report.insights.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final insight in report.insights.take(4)) ...[
                    _AiInsightTile(insight: insight),
                    if (insight != report.insights.take(4).last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(
                    icon: report.generatedByAi
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    label: report.generatedByAi
                        ? 'Độ tin cậy AI: ${report.confidence}'
                        : 'Đang dùng phân tích dự phòng an toàn',
                    color: report.generatedByAi
                        ? context.semanticColors.primary
                        : context.semanticColors.warning,
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

class _AiInsightTile extends StatelessWidget {
  const _AiInsightTile({required this.insight});

  final NutritionAiInsight insight;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (insight.priority) {
      'cao' => context.semanticColors.warning,
      'thấp' => context.semanticColors.success,
      _ => context.semanticColors.primary,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: priorityColor.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(
                icon: Icons.bolt_rounded,
                label: insight.priority,
                color: priorityColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            insight.body,
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final code in insight.evidenceCodes.take(4))
                _EvidenceChip(code: code),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _evidenceLabel(code),
        style: AppTextStyles.labelSmall.copyWith(
          color: context.semanticColors.textSecondary,
        ),
      ),
    );
  }
}

class _SummaryWrap extends StatelessWidget {
  const _SummaryWrap({required this.summary, required this.intelligenceAsync});

  final NutritionSummary summary;
  final AsyncValue<NutritionIntelligence> intelligenceAsync;

  @override
  Widget build(BuildContext context) {
    final intelligence = intelligenceAsync.asData?.value;
    final metrics = <_Metric>[
      _Metric(
        title: 'Đã ghi nhận',
        value: _numberWithUnit(
          intelligence?.actual.energyKcal,
          'kcal',
          decimals: 0,
        ),
        hint: 'Năng lượng từ nhật ký ngày đã chọn',
        icon: Icons.local_fire_department_rounded,
        color: context.semanticColors.warning,
      ),
      _Metric(
        title: 'Kế hoạch',
        value: _numberWithUnit(
          intelligence?.planned.energyKcal,
          'kcal',
          decimals: 0,
        ),
        hint: 'Mốc so sánh từ thực đơn cá nhân',
        icon: Icons.restaurant_menu_rounded,
        color: context.semanticColors.primary,
      ),
      _Metric(
        title: 'Protein',
        value: _numberWithUnit(intelligence?.actual.proteinG, 'g'),
        hint: _comparisonHint(
          intelligence?.actual.proteinG,
          intelligence?.planned.proteinG,
        ),
        icon: Icons.fitness_center_rounded,
        color: context.semanticColors.success,
      ),
      _Metric(
        title: 'Carb / chất béo',
        value: intelligence == null
            ? '--'
            : '${_shortNumber(intelligence.actual.carbsG)} / ${_shortNumber(intelligence.actual.fatG)} g',
        hint: 'Không điền số khi log chưa có dữ liệu',
        icon: Icons.pie_chart_rounded,
        color: context.semanticColors.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final minWidth = textScale >= 1.45 ? 240.0 : 190.0;
        final available = constraints.maxWidth;
        final columns = (available / minWidth).floor().clamp(1, 4);
        final spacing = AppSpacing.md;
        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color, size: 26),
          const SizedBox(height: AppSpacing.md),
          Text(metric.title, style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.value,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.hint,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelligenceSection extends StatelessWidget {
  const _IntelligenceSection({required this.intelligenceAsync});

  final AsyncValue<NutritionIntelligence> intelligenceAsync;

  @override
  Widget build(BuildContext context) {
    return intelligenceAsync.when(
      loading: () => const MedicalSurfaceCard(
        child: _InlineLoading(label: 'Đang tính các chỉ số chuyên sâu…'),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NutrientCoverageCard(data: data),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _MealRhythmCard(data: data),
                    const SizedBox(height: AppSpacing.md),
                    _HealthContextCard(data: data),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _MealRhythmCard(data: data)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _HealthContextCard(data: data)),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _TrendCard(data: data),
          if (data.dataQuality.missingData.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _MissingDataCard(quality: data.dataQuality),
          ],
        ],
      ),
    );
  }
}

class _NutrientCoverageCard extends StatelessWidget {
  const _NutrientCoverageCard({required this.data});

  final NutritionIntelligence data;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Độ phủ dinh dưỡng', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'So sánh dữ liệu đã ghi với thực đơn của chính bạn. Đây không phải bảng ngưỡng điều trị hay chẩn đoán.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final metric in data.coverage) ...[
            _CoverageRow(metric: metric),
            if (metric != data.coverage.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.metric});

  final NutritionCoverageMetric metric;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (metric.status) {
      NutritionCoverageStatus.onTrack => context.semanticColors.success,
      NutritionCoverageStatus.low ||
      NutritionCoverageStatus.abovePlan => context.semanticColors.warning,
      NutritionCoverageStatus.nearPlan => context.semanticColors.primary,
      NutritionCoverageStatus.insufficientData =>
        context.semanticColors.textSecondary,
    };
    final ratio = metric.ratio;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(metric.label, style: AppTextStyles.labelLarge),
              ),
              Text(
                metric.actual == null
                    ? 'Chưa đủ dữ liệu'
                    : metric.planned == null
                    ? '${_format(metric.actual!)} ${metric.unit}'
                    : '${_format(metric.actual!)} / ${_format(metric.planned!)} ${metric.unit}',
                style: AppTextStyles.labelMedium.copyWith(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (ratio != null && metric.dataCoverage >= .5)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.25).toDouble() / 1.25,
                minHeight: 6,
                backgroundColor: statusColor.withValues(alpha: .1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Text(
              'Độ phủ log: ${(metric.dataCoverage * 100).round()}% · Nabi không giả định phần còn thiếu bằng không.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MealRhythmCard extends StatelessWidget {
  const _MealRhythmCard({required this.data});

  final NutritionIntelligence data;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nhịp ăn trong ngày', style: AppTextStyles.heading4),
          const SizedBox(height: AppSpacing.md),
          if (data.mealDistribution.isEmpty)
            Text(
              'Chưa có đủ bữa được ghi để phân tích nhịp ăn.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            )
          else
            for (final item in data.mealDistribution) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _mealLabel(item.mealType),
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                  Text(
                    '${item.energyKcal.round()} kcal · ${item.loggedItems} mục',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              if (item != data.mealDistribution.last)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _HealthContextCard extends StatelessWidget {
  const _HealthContextCard({required this.data});

  final NutritionIntelligence data;

  @override
  Widget build(BuildContext context) {
    final health = data.healthContext;
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tín hiệu sức khỏe liên quan', style: AppTextStyles.heading4),
          const SizedBox(height: AppSpacing.md),
          if (!health.hasAnyValue)
            Text(
              'Chưa có dữ liệu theo dõi sức khỏe gần ngày này.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            )
          else ...[
            _CompactDataRow(
              icon: Icons.water_drop_rounded,
              label: 'Nước',
              value: health.waterMl == null ? '--' : '${health.waterMl} ml',
              secondary: health.sevenDayAverageWaterMl == null
                  ? null
                  : 'TB gần đây ${health.sevenDayAverageWaterMl!.round()} ml',
            ),
            _CompactDataRow(
              icon: Icons.bedtime_rounded,
              label: 'Giấc ngủ',
              value: health.sleepHours == null
                  ? '--'
                  : '${health.sleepHours!.toStringAsFixed(1)} giờ',
              secondary: health.sevenDayAverageSleepHours == null
                  ? null
                  : 'TB gần đây ${health.sevenDayAverageSleepHours!.toStringAsFixed(1)} giờ',
            ),
            _CompactDataRow(
              icon: Icons.directions_walk_rounded,
              label: 'Bước chân',
              value: health.stepsCount == null ? '--' : '${health.stepsCount}',
              secondary: health.sevenDayAverageSteps == null
                  ? null
                  : 'TB gần đây ${health.sevenDayAverageSteps!.round()}',
            ),
            _CompactDataRow(
              icon: Icons.psychology_alt_rounded,
              label: 'Stress',
              value: health.stressLevel == null
                  ? '--'
                  : '${health.stressLevel}',
              secondary: health.mood,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactDataRow extends StatelessWidget {
  const _CompactDataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.secondary,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.labelMedium)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.labelLarge),
              if (secondary?.trim().isNotEmpty ?? false)
                Text(
                  secondary!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data});

  final NutritionIntelligence data;

  @override
  Widget build(BuildContext context) {
    final seven = data.sevenDayTrend;
    final maxEnergy = seven
        .map((item) => item.energyKcal ?? 0)
        .fold<double>(0, (max, value) => value > max ? value : max);
    final days30 = data.dataQuality.daysWithLogsInLast30;

    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Xu hướng', style: AppTextStyles.heading3)),
              _StatusPill(
                icon: Icons.history_rounded,
                label: '$days30 ngày có log / 30 ngày',
                color: context.semanticColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Năng lượng đã ghi trong bảy ngày gần ngày đang xem. Cột trống nghĩa là chưa có dữ liệu, không phải đã ăn bằng không.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in seven)
                  Expanded(
                    child: _TrendBar(point: point, maxEnergy: maxEnergy),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.point, required this.maxEnergy});

  final NutritionTrendPoint point;
  final double maxEnergy;

  @override
  Widget build(BuildContext context) {
    final value = point.energyKcal;
    final ratio = value == null || maxEnergy <= 0
        ? 0.0
        : (value / maxEnergy).clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: value == null
          ? '${_shortWeekday(point.date)} chưa có dữ liệu'
          : '${_shortWeekday(point.date)} ${value.round()} kilocalo',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: value == null ? .04 : (.15 + ratio * .85),
                  widthFactor: .62,
                  child: Container(
                    decoration: BoxDecoration(
                      color: value == null
                          ? context.semanticColors.outline.withValues(
                              alpha: .25,
                            )
                          : context.semanticColors.primary.withValues(
                              alpha: .75,
                            ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _shortWeekday(point.date),
              style: AppTextStyles.labelSmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingDataCard extends StatelessWidget {
  const _MissingDataCard({required this.quality});

  final NutritionDataQuality quality;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: context.semanticColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Làm dữ liệu chính xác hơn',
                  style: AppTextStyles.heading4,
                ),
              ),
              Text('${quality.score}/100', style: AppTextStyles.heading4),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in quality.missingData.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 7,
                    color: context.semanticColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.aiAsync});

  final AsyncValue<NutritionAiReport> aiAsync;

  @override
  Widget build(BuildContext context) {
    final report = aiAsync.asData?.value;
    if (report == null ||
        (report.todayActions.isEmpty && report.weeklyActions.isEmpty)) {
      return const SizedBox.shrink();
    }
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Việc nên làm tiếp theo', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          if (report.todayActions.isNotEmpty) ...[
            Text('Hôm nay', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            for (final action in report.todayActions)
              _ActionRow(
                icon: Icons.check_circle_outline_rounded,
                text: action,
              ),
          ],
          if (report.weeklyActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Trong tuần', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            for (final action in report.weeklyActions)
              _ActionRow(icon: Icons.calendar_view_week_rounded, text: action),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.semanticColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionProfileEntryCard extends StatelessWidget {
  const _NutritionProfileEntryCard();

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.assignment_ind_rounded, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hồ sơ dinh dưỡng cá nhân', style: AppTextStyles.heading4),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cập nhật dị ứng, mục tiêu, triệu chứng và dữ liệu liên quan để Nabi phân tích đúng ngữ cảnh hơn.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mở hồ sơ dinh dưỡng',
            onPressed: () => context.push(V1RoutePaths.nutritionProfile),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _MealPlanSection extends StatelessWidget {
  const _MealPlanSection({required this.meals, required this.selectedDate});

  final List<MealPlanModel> meals;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thực đơn · ${_friendlyDate(selectedDate)}',
                  style: AppTextStyles.heading3,
                ),
              ),
              TextButton(
                onPressed: () => context.push(V1RoutePaths.mealPlan),
                child: const Text('Xem thực đơn'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (meals.isEmpty)
            Text(
              'Chưa có bữa ăn nào trong kế hoạch của ngày này.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            )
          else
            for (final meal in meals.take(6)) ...[
              _DataRow(
                icon: meal.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.restaurant_rounded,
                title: meal.mealName.trim().isEmpty
                    ? _mealLabel(meal.mealType)
                    : meal.mealName.trim(),
                subtitle: [
                  _mealLabel(meal.mealType),
                  if (meal.calories > 0) '${meal.calories} kcal',
                  if (meal.protein > 0)
                    '${meal.protein.toStringAsFixed(0)}g protein',
                  if (meal.fiber > 0) '${meal.fiber.toStringAsFixed(0)}g xơ',
                ].join(' • '),
              ),
              if (meal != meals.take(6).last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _NutritionLogSection extends StatelessWidget {
  const _NutritionLogSection({required this.logs, required this.selectedDate});

  final List<NutritionLogModel> logs;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nhật ký · ${_friendlyDate(selectedDate)}',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bữa có dữ liệu vi chất sẽ được Nabi dùng cho phân tích chuyên sâu; bữa chỉ có macro vẫn được giữ nguyên.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (logs.isEmpty)
            Text(
              'Chưa có ghi nhận nào trong ngày này.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            )
          else
            for (final log in logs.take(12)) ...[
              _DataRow(
                icon: log.nutrition.isNotEmpty
                    ? Icons.analytics_rounded
                    : Icons.ramen_dining_rounded,
                title: (log.foodName ?? '').trim().isEmpty
                    ? 'Bữa ăn đã ghi nhận'
                    : log.foodName!.trim(),
                subtitle: [
                  if ((log.mealType ?? '').trim().isNotEmpty)
                    _mealLabel(log.mealType!),
                  if ((log.calories ?? 0) > 0) '${log.calories} kcal',
                  if (log.nutrition.isNotEmpty) 'Có vi chất',
                  if ((log.nutritionSource ?? '').trim().isNotEmpty)
                    _sourceLabel(log.nutritionSource!),
                ].join(' • '),
              ),
              if (log != logs.take(12).last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.semanticColors.primary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.semanticColors.textSecondary,
                    ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}

class _NutritionLoadingState extends StatelessWidget {
  const _NutritionLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _NutritionStateCard extends StatelessWidget {
  const _NutritionStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: MedicalSurfaceCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: context.semanticColors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
}

String _mealLabel(String type) => switch (type.trim().toLowerCase()) {
  'breakfast' => 'Bữa sáng',
  'morning_snack' => 'Bữa phụ sáng',
  'lunch' => 'Bữa trưa',
  'afternoon_snack' => 'Bữa phụ chiều',
  'dinner' => 'Bữa tối',
  'snack' => 'Bữa phụ',
  _ => 'Bữa ăn',
};

String _friendlyDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final value = DateTime(date.year, date.month, date.day);
  if (value == today) return 'Hôm nay';
  if (value == today.subtract(const Duration(days: 1))) return 'Hôm qua';
  if (value == today.add(const Duration(days: 1))) return 'Ngày mai';
  return '${_shortWeekday(date)}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _shortWeekday(DateTime date) => switch (date.weekday) {
  DateTime.monday => 'T2',
  DateTime.tuesday => 'T3',
  DateTime.wednesday => 'T4',
  DateTime.thursday => 'T5',
  DateTime.friday => 'T6',
  DateTime.saturday => 'T7',
  _ => 'CN',
};

String _numberWithUnit(double? value, String unit, {int decimals = 1}) {
  if (value == null) return '--';
  return '${value.toStringAsFixed(decimals)} $unit';
}

String _shortNumber(double? value) =>
    value == null ? '--' : value.toStringAsFixed(1);

String _comparisonHint(double? actual, double? planned) {
  if (actual == null) return 'Chưa có dữ liệu đã ghi';
  if (planned == null || planned <= 0) return 'Chưa có kế hoạch làm mốc';
  final ratio = actual / planned;
  if (ratio < .65) return 'Còn thấp so với thực đơn đã lập';
  if (ratio < .85) return 'Đang tiến gần mốc thực đơn';
  if (ratio <= 1.2) return 'Gần mốc thực đơn hôm nay';
  return 'Đã vượt mốc trong thực đơn';
}

String _format(double value) {
  if (value.abs() >= 100) return value.toStringAsFixed(0);
  if (value.abs() >= 10) return value.toStringAsFixed(1);
  return value.toStringAsFixed(2);
}

String _sourceLabel(String source) {
  final normalized = source.trim().toLowerCase();
  return switch (normalized) {
    'food_scan' || 'ai_scan' || 'ai_fallback' => 'Food Scan',
    'catalog' || 'database' => 'CSDL thực phẩm',
    'manual' => 'Nhập tay',
    _ => 'Có nguồn dữ liệu',
  };
}

String _evidenceLabel(String code) {
  const fixed = <String, String>{
    'actual:energy': 'Năng lượng đã ghi',
    'actual:protein': 'Protein đã ghi',
    'actual:carbs': 'Carb đã ghi',
    'actual:fat': 'Chất béo đã ghi',
    'planned:energy': 'Năng lượng kế hoạch',
    'planned:protein': 'Protein kế hoạch',
    'planned:carbs': 'Carb kế hoạch',
    'planned:fat': 'Chất béo kế hoạch',
    'trend:7d': 'Xu hướng gần đây',
    'trend:30d': 'Lịch sử dài hơn',
    'health:water': 'Nước',
    'health:sleep': 'Giấc ngủ',
    'health:stress': 'Stress',
    'health:steps': 'Vận động',
    'data:quality': 'Chất lượng dữ liệu',
  };
  if (fixed.containsKey(code)) return fixed[code]!;
  if (code.startsWith('nutrient:')) {
    final nutrient = code.substring('nutrient:'.length);
    return switch (nutrient) {
      'energy' => 'Năng lượng',
      'protein' => 'Protein',
      'carbs' => 'Carbohydrate',
      'fat' => 'Chất béo',
      'fiber' => 'Chất xơ',
      'sodium' => 'Natri',
      'potassium' => 'Kali',
      'calcium' => 'Canxi',
      'iron' => 'Sắt',
      _ => 'Dinh dưỡng',
    };
  }
  if (code.startsWith('goal:')) return 'Mục tiêu cá nhân';
  if (code.startsWith('allergy:')) return 'Dị ứng đã khai báo';
  if (code.startsWith('restriction:')) return 'Hạn chế thực phẩm';
  if (code.startsWith('symptom:')) return 'Triệu chứng đã khai báo';
  if (code.startsWith('lab:')) return 'Xét nghiệm đã khai báo';
  return 'Dữ liệu hồ sơ';
}
