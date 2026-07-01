import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(nutritionSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const _NutritionLoadingState(),
          error: (error, _) => _StateCard(
            icon: Icons.spa_rounded,
            title: 'Nabi chưa mở được góc dinh dưỡng của bạn',
            message:
                'Có vẻ dữ liệu bữa ăn đang cần thêm một chút thời gian để sẵn sàng. Bạn thử làm mới lại nhé, Nabi vẫn ở đây cùng bạn.',
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
                      _NamiNoteCard(summary: summary),
                      const SizedBox(height: AppSpacing.lg),
                      _SummaryGrid(summary: summary),
                      const SizedBox(height: AppSpacing.lg),
                      _MealPlanSection(meals: summary.todayMeals),
                      const SizedBox(height: AppSpacing.lg),
                      _NutritionLogSection(logs: summary.todayLogs),
                      const SizedBox(height: AppSpacing.lg),
                      _NutritionLogSection(
                        title: 'Những bữa Nabi đã ghi nhớ',
                        subtitle:
                            'Từng ghi nhận nhỏ đều giúp Nabi hiểu bạn hơn một chút.',
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

class _NutritionLoadingState extends StatelessWidget {
  const _NutritionLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _SurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nabi đang chuẩn bị góc dinh dưỡng...',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading4.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chờ Nabi một nhịp nhỏ để gom lại những bữa ăn hôm nay cho bạn nhé.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
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
    final displayName = name.isEmpty ? 'bạn' : name;
    final plannedCalories = summary.plannedCalories;
    final loggedCalories = summary.loggedCalories;
    final progress = plannedCalories <= 0
        ? 0.0
        : (loggedCalories / plannedCalories).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFF06B6D4), Color(0xFF22C55E)],
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
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
                        color: Colors.white,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nabi đang cùng $displayName chăm từng bữa ăn nhỏ trong ngày.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: .92),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nhịp năng lượng',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      plannedCalories > 0
                          ? '$loggedCalories / $plannedCalories kcal'
                          : '$loggedCalories kcal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: .92),
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: .22),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: .92),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _energyMessage(summary),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: .9),
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

  String _energyMessage(NutritionSummary summary) {
    final planned = summary.plannedCalories;
    final logged = summary.loggedCalories;

    if (planned <= 0 && logged <= 0) {
      return 'Hôm nay vẫn còn rất nhẹ nhàng. Khi bạn ăn hoặc ghi nhận bữa đầu tiên, Nabi sẽ theo dõi cùng bạn.';
    }

    if (planned <= 0) {
      return 'Bạn đã bắt đầu ghi nhận bữa ăn rồi. Nabi sẽ tiếp tục giữ lại những nhịp nhỏ này cho bạn.';
    }

    final ratio = logged / planned;

    if (ratio < .45) {
      return 'Bạn vẫn còn khá nhiều khoảng trống năng lượng trong ngày. Mình cứ đi chậm thôi, không cần vội.';
    }

    if (ratio <= 1.05) {
      return 'Nhịp ăn hôm nay đang khá cân bằng. Nabi thấy bạn đang chăm mình rất ổn đó.';
    }

    return 'Hôm nay năng lượng đã hơi vượt kế hoạch một chút. Không sao cả, bữa sau mình chọn nhẹ nhàng hơn nhé.';
  }
}

class _NamiNoteCard extends StatelessWidget {
  final NutritionSummary summary;

  const _NamiNoteCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lời nhắn nhỏ từ Nabi',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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

  String get _message {
    final hasMeals = summary.todayMeals.isNotEmpty;
    final hasLogs = summary.todayLogs.isNotEmpty;
    final protein = summary.protein;

    if (!hasMeals && !hasLogs) {
      return 'Hôm nay Nabi chưa thấy bữa ăn nào được ghi nhận. Bạn có thể bắt đầu từ một bữa thật đơn giản, miễn là cơ thể thấy dễ chịu.';
    }

    if (protein > 0 && protein < 30) {
      return 'Bạn đã có ghi nhận dinh dưỡng rồi. Nếu được, mình thêm một chút đạm lành mạnh để cơ thể có thêm năng lượng hồi phục nhé.';
    }

    if (hasMeals && !hasLogs) {
      return 'Thực đơn hôm nay đã sẵn sàng. Khi bạn dùng bữa xong, chỉ cần ghi nhận lại một chút để Nabi đồng hành sát hơn.';
    }

    return 'Bạn đang chăm mình bằng những ghi nhận rất nhỏ nhưng rất đáng quý. Nabi sẽ giữ nhịp này cùng bạn.';
  }
}

class _SummaryGrid extends StatelessWidget {
  final NutritionSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        title: 'Đã nạp hôm nay',
        value: summary.loggedCalories > 0
            ? '${summary.loggedCalories} kcal'
            : '--',
        hint: 'Năng lượng bạn đã ghi nhận',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.warning,
      ),
      _Metric(
        title: 'Kế hoạch dịu nhẹ',
        value: summary.plannedCalories > 0
            ? '${summary.plannedCalories} kcal'
            : '--',
        hint: 'Mức năng lượng Nabi dự kiến',
        icon: Icons.restaurant_menu_rounded,
        color: AppColors.primary,
      ),
      _Metric(
        title: 'Đạm chăm cơ thể',
        value: summary.protein > 0
            ? '${summary.protein.toStringAsFixed(1)} g'
            : '--',
        hint: 'Giúp cơ thể no lâu và hồi phục',
        icon: Icons.fitness_center_rounded,
        color: AppColors.success,
      ),
      _Metric(
        title: 'Tinh bột / chất béo',
        value: summary.carbs > 0 || summary.fat > 0
            ? '${summary.carbs.toStringAsFixed(1)}g / ${summary.fat.toStringAsFixed(1)}g'
            : '--',
        hint: 'Hai nhịp năng lượng chính trong ngày',
        icon: Icons.pie_chart_rounded,
        color: AppColors.secondary,
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
            childAspectRatio: constraints.maxWidth >= 620 ? 1.05 : 1.02,
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
  final String hint;
  final IconData icon;
  final Color color;

  const _Metric({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(metric.icon, color: metric.color, size: 21),
          ),
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
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: AppTypography.semiBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.25,
            ),
          ),
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
      title: 'Bữa ăn Nabi gợi ý hôm nay',
      subtitle:
          'Một vài lựa chọn nhỏ để ngày của bạn nhẹ bụng và đủ năng lượng hơn.',
      emptyTitle: 'Hôm nay Nabi chưa có thực đơn cho bạn',
      emptyMessage:
          'Không sao đâu. Khi thực đơn sẵn sàng, Nabi sẽ đặt ở đây để bạn dễ chọn bữa phù hợp với mình.',
      emptyIcon: Icons.restaurant_menu_rounded,
      children: meals.map((meal) {
        return _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(
                icon: Icons.restaurant_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayText(
                        meal.mealName,
                        fallback: 'Một bữa ăn nhẹ nhàng',
                      ),
                      style: AppTextStyles.heading4.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _TinyPill(
                          icon: Icons.schedule_rounded,
                          label: _mealTypeLabel(meal.mealType),
                          color: AppColors.primary,
                        ),
                        _TinyPill(
                          icon: Icons.local_fire_department_rounded,
                          label: '${meal.calories} kcal',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    if (meal.description.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        meal.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
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
  final String subtitle;
  final List<NutritionLogModel> logs;

  const _NutritionLogSection({
    this.title = 'Bữa ăn bạn đã ghi nhận',
    this.subtitle =
        'Nabi sẽ gom lại từng bữa để bạn nhìn thấy hành trình chăm mình rõ hơn.',
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      subtitle: subtitle,
      emptyTitle: 'Chưa có bữa ăn nào được ghi nhận',
      emptyMessage:
          'Bạn chưa cần làm mọi thứ thật hoàn hảo. Chỉ cần ghi lại bữa đầu tiên, Nabi sẽ cùng bạn theo dõi từng chút một.',
      emptyIcon: Icons.receipt_long_rounded,
      children: logs.map((log) {
        return _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(
                icon: Icons.receipt_long_rounded,
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
                        fallback: 'Một món ăn nhỏ trong ngày',
                      ),
                      style: AppTextStyles.heading4.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (log.calories != null)
                          _TinyPill(
                            icon: Icons.local_fire_department_rounded,
                            label: '${log.calories} kcal',
                            color: AppColors.warning,
                          ),
                        if (log.mealType?.trim().isNotEmpty == true)
                          _TinyPill(
                            icon: Icons.restaurant_rounded,
                            label: _mealTypeLabel(log.mealType!),
                            color: AppColors.primary,
                          ),
                        if (log.eatenAt?.trim().isNotEmpty == true)
                          _TinyPill(
                            icon: Icons.calendar_today_rounded,
                            label: _dateLabel(log.eatenAt!),
                            color: AppColors.secondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Đạm ${_macro(log.protein)} • Tinh bột ${_macro(log.carbs)} • Chất béo ${_macro(log.fat)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
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
  final String? subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final List<Widget> children;

  const _Section({
    required this.title,
    this.subtitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final sectionSubtitle = subtitle?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        if (sectionSubtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            sectionSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (children.isEmpty)
          _StateCard(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
        else
          ...children.expand(
            (child) => [child, const SizedBox(height: AppSpacing.sm)],
          ),
      ],
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SoftIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TinyPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
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
          _SoftIcon(
            icon: icon,
            color: onRetry == null ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Để Nabi thử lại'),
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
