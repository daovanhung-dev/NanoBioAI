import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/features/nutrition/providers/nutrition_provider.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(nutritionSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StateCard(
            icon: Icons.error_outline_rounded,
            title: 'Chưa đọc được dinh dưỡng',
            message: error.toString(),
            onRetry: () => ref.invalidate(nutritionSummaryProvider),
          ),
          data: (summary) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nutritionSummaryProvider);
              await ref.read(nutritionSummaryProvider.future);
            },
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
                      _Header(summary: summary),
                      const SizedBox(height: AppSpacing.lg),
                      _SummaryGrid(summary: summary),
                      const SizedBox(height: AppSpacing.lg),
                      _MealPlanSection(meals: summary.todayMeals),
                      const SizedBox(height: AppSpacing.lg),
                      _NutritionLogSection(logs: summary.todayLogs),
                      const SizedBox(height: AppSpacing.lg),
                      _NutritionLogSection(
                        title: 'Lịch sử ghi nhận',
                        logs: summary.logs,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final NutritionSummary summary;

  const _Header({required this.summary});

  @override
  Widget build(BuildContext context) {
    final name = summary.fullName.trim();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFF06B6D4), Color(0xFF22C55E)],
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.restaurant_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dinh dưỡng',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name.isEmpty
                      ? 'Đọc meal_plans và nutrition_logs từ SQLite'
                      : 'Dữ liệu dinh dưỡng của $name',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .9),
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

class _SummaryGrid extends StatelessWidget {
  final NutritionSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        'Calories ghi nhận',
        summary.loggedCalories > 0 ? '${summary.loggedCalories} kcal' : '--',
        Icons.local_fire_department_rounded,
      ),
      _Metric(
        'Calories dự kiến',
        summary.plannedCalories > 0 ? '${summary.plannedCalories} kcal' : '--',
        Icons.restaurant_menu_rounded,
      ),
      _Metric(
        'Protein',
        summary.protein > 0 ? '${summary.protein.toStringAsFixed(1)} g' : '--',
        Icons.fitness_center_rounded,
      ),
      _Metric(
        'Carbs/Fat',
        summary.carbs > 0 || summary.fat > 0
            ? '${summary.carbs.toStringAsFixed(1)}g / ${summary.fat.toStringAsFixed(1)}g'
            : '--',
        Icons.pie_chart_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: items[index]),
        );
      },
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final IconData icon;

  const _Metric(this.title, this.value, this.icon);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: AppColors.primary),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(metric.title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _MealPlanSection extends StatelessWidget {
  final List<MealPlanModel> meals;

  const _MealPlanSection({required this.meals});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Thực đơn hôm nay',
      emptyTitle: 'Chưa có meal_plans hôm nay',
      emptyMessage:
          'Khi bảng meal_plans có dữ liệu hôm nay, phần này sẽ tự hiển thị.',
      children: meals.map((meal) {
        return _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.restaurant_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.mealName, style: AppTextStyles.heading4),
                    const SizedBox(height: 4),
                    Text(
                      '${_mealTypeLabel(meal.mealType)} • ${meal.calories} kcal',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (meal.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meal.description,
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NutritionLogSection extends StatelessWidget {
  final String title;
  final List<NutritionLogModel> logs;

  const _NutritionLogSection({
    this.title = 'Ghi nhận hôm nay',
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      emptyTitle: 'Chưa có nutrition_logs',
      emptyMessage:
          'Khi bạn ghi nhận món ăn vào nutrition_logs, phần này sẽ tự cập nhật.',
      children: logs.map((log) {
        return _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayText(
                        log.foodName,
                        fallback: 'Món ăn chưa đặt tên',
                      ),
                      style: AppTextStyles.heading4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (log.calories != null) '${log.calories} kcal',
                        if (log.mealType?.trim().isNotEmpty == true)
                          _mealTypeLabel(log.mealType!),
                        if (log.eatenAt?.trim().isNotEmpty == true)
                          _dateLabel(log.eatenAt!),
                      ].join(' • '),
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Protein ${_macro(log.protein)} • Carbs ${_macro(log.carbs)} • Fat ${_macro(log.fat)}',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.md),
        if (children.isEmpty)
          _StateCard(
            icon: Icons.restaurant_menu_rounded,
            title: emptyTitle,
            message: emptyMessage,
          )
        else
          ...children.expand(
            (child) => [child, const SizedBox(height: AppSpacing.sm)],
          ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
      child: child,
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading4),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
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

String _displayText(String? value, {required String fallback}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _macro(double? value) {
  if (value == null || value <= 0) return '--';
  return '${value.toStringAsFixed(1)}g';
}

String _mealTypeLabel(String value) {
  switch (value.toLowerCase()) {
    case 'breakfast':
      return 'Bữa sáng';
    case 'morning_snack':
      return 'Bữa phụ sáng';
    case 'lunch':
      return 'Bữa trưa';
    case 'afternoon_snack':
      return 'Bữa phụ chiều';
    case 'dinner':
      return 'Bữa tối';
    default:
      return value.trim().isEmpty ? 'Bữa ăn' : value;
  }
}

String _dateLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/'
      '${parsed.year}';
}
