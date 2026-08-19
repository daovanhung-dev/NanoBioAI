import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:nano_app/core/theme/theme.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(nutritionSummaryProvider);
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
              onAction: () => ref.invalidate(nutritionSummaryProvider),
            ),
            data: (summary) => _NutritionReady(
              summary: summary,
              onRefresh: () async {
                AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
                ref.invalidate(nutritionSummaryProvider);
                try {
                  await ref.read(nutritionSummaryProvider.future);
                  AppFeedbackService.instance.emit(AppFeedbackType.success);
                } catch (_) {
                  AppFeedbackService.instance.emit(AppFeedbackType.error);
                  rethrow;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionReady extends StatelessWidget {
  const _NutritionReady({required this.summary, required this.onRefresh});

  final NutritionSummary summary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
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
                      _Header(summary: summary),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      const _NutritionProfileEntryCard(),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _SummaryWrap(summary: summary),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _MealPlanSection(meals: summary.todayMeals),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _NutritionLogSection(logs: summary.todayLogs),
                      if (summary.todayLogs.length != summary.logs.length) ...[
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        _NutritionLogSection(
                          title: 'Những bữa Nabi đã ghi nhớ',
                          subtitle:
                              'Các ghi nhận trước đây giúp bạn nhìn lại nhịp ăn của mình.',
                          logs: summary.logs,
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

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final NutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final displayName = summary.fullName.trim().isEmpty
        ? 'bạn'
        : summary.fullName.trim();
    final planned = summary.plannedCalories;
    final logged = summary.loggedCalories;
    final progress = planned <= 0 ? 0.0 : (logged / planned).clamp(0.0, 1.0).toDouble();
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
                      'Dinh dưỡng hôm nay',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Nabi đang cùng $displayName chăm từng bữa ăn nhỏ trong ngày.',
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
          Row(
            children: [
              Expanded(
                child: Text(
                  planned > 0 ? '$logged / $planned kcal' : '$logged kcal',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
              Text(
                planned > 0 ? '${(progress * 100).round()}%' : 'Đang ghi nhận',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
        ],
      ),
    );
  }
}

class _SummaryWrap extends StatelessWidget {
  const _SummaryWrap({required this.summary});

  final NutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = <_Metric>[
      _Metric(
        title: 'Đã nạp hôm nay',
        value: summary.loggedCalories > 0
            ? '${summary.loggedCalories} kcal'
            : '--',
        hint: 'Năng lượng bạn đã ghi nhận',
        icon: Icons.local_fire_department_rounded,
        color: context.semanticColors.warning,
      ),
      _Metric(
        title: 'Kế hoạch hôm nay',
        value: summary.plannedCalories > 0
            ? '${summary.plannedCalories} kcal'
            : '--',
        hint: 'Năng lượng dự kiến từ thực đơn',
        icon: Icons.restaurant_menu_rounded,
        color: context.semanticColors.primary,
      ),
      _Metric(
        title: 'Protein',
        value: summary.protein > 0
            ? '${summary.protein.toStringAsFixed(1)} g'
            : '--',
        hint: 'Lượng đạm đã ghi nhận',
        icon: Icons.fitness_center_rounded,
        color: context.semanticColors.success,
      ),
      _Metric(
        title: 'Carb / chất béo',
        value: summary.carbs > 0 || summary.fat > 0
            ? '${summary.carbs.toStringAsFixed(1)}g / ${summary.fat.toStringAsFixed(1)}g'
            : '--',
        hint: 'Hai nguồn năng lượng chính',
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
        final itemWidth =
            (available - spacing * (columns - 1)) / columns;
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
                Text(
                  'Hồ sơ dinh dưỡng cá nhân',
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cập nhật dị ứng, mục tiêu và sở thích để Nabi lọc gợi ý phù hợp hơn.',
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
  const _MealPlanSection({required this.meals});

  final List<MealPlanModel> meals;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Thực đơn hôm nay', style: AppTextStyles.heading3),
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
              'Chưa có bữa ăn nào trong kế hoạch hôm nay.',
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
  const _NutritionLogSection({
    required this.logs,
    this.title = 'Đã ghi nhận hôm nay',
    this.subtitle = 'Các bữa bạn đã ghi lại trong ngày.',
  });

  final List<NutritionLogModel> logs;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (logs.isEmpty)
            Text(
              'Chưa có ghi nhận nào.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            )
          else
            for (final log in logs.take(12)) ...[
              _DataRow(
                icon: Icons.ramen_dining_rounded,
                title: (log.foodName ?? '').trim().isEmpty
                    ? 'Bữa ăn đã ghi nhận'
                    : log.foodName!.trim(),
                subtitle: [
                  if ((log.mealType ?? '').trim().isNotEmpty)
                    _mealLabel(log.mealType!),
                  if ((log.calories ?? 0) > 0) '${log.calories} kcal',
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
