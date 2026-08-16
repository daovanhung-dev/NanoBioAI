import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_detail_content_formatter.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart';
import 'package:nano_app/core/theme/theme.dart';

class MealPlanPage extends ConsumerStatefulWidget {
  const MealPlanPage({super.key});

  @override
  ConsumerState<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends ConsumerState<MealPlanPage> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealPlanControllerProvider);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      body: Column(
        children: [
          _MealPlanHeader(
            onRefresh: () => ref
                .read(mealPlanControllerProvider.notifier)
                .refreshMealPlans(),
          ),
          Expanded(
            child: state.when(
              loading: () => const _MealLoadingView(),
              error: (_, __) => _MealErrorView(
                onRetry: () => ref
                    .read(mealPlanControllerProvider.notifier)
                    .refreshMealPlans(),
              ),
              data: _buildReady,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReady(List<MealPlanEntity> meals) {
    if (meals.isEmpty) {
      return const _MealEmptyView(
        title: 'Mình chưa chuẩn bị xong thực đơn',
        subtitle: 'Bạn quay lại sau một chút nhé, Nabi đang chọn món phù hợp.',
      );
    }
    final dates = <DateTime>{};
    for (final meal in meals) {
      final date = _parseDate(meal.planDate);
      if (date != null) dates.add(DateUtils.dateOnly(date));
    }
    final availableDates = dates.toList()..sort();
    if (availableDates.isEmpty) {
      return const _MealEmptyView(
        title: 'Mình chưa sắp được lịch ăn',
        subtitle: 'Dữ liệu thực đơn đang được chuẩn bị.',
      );
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final fallback = availableDates.any((d) => DateUtils.isSameDay(d, today))
        ? today
        : availableDates.first;
    final selected = _selectedDate != null &&
            availableDates.any((d) => DateUtils.isSameDay(d, _selectedDate))
        ? _selectedDate!
        : fallback;
    final filtered = meals.where((meal) {
      final date = _parseDate(meal.planDate);
      return date != null && DateUtils.isSameDay(date, selected);
    }).toList()
      ..sort((a, b) => a.mealOrder.compareTo(b.mealOrder));

    return RefreshIndicator(
      color: context.semanticColors.primary,
      onRefresh: () => ref
          .read(mealPlanControllerProvider.notifier)
          .refreshMealPlans(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          _DateSelector(
            dates: availableDates,
            selected: selected,
            onChanged: (date) => setState(() => _selectedDate = date),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: _DaySummary(date: selected, count: filtered.length),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: _MealEmptyView(
                title: 'Ngày này chưa có món',
                subtitle: 'Bạn chọn một ngày khác để xem thực đơn nhé.',
              ),
            )
          else
            ...filtered.map(
              (meal) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                ),
                child: _MealPlanCard(meal: meal),
              ),
            ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateUtils.dateOnly(iso);
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(trimmed);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }
}

class _MealPlanHeader extends StatelessWidget {
  const _MealPlanHeader({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.semanticColors.primary,
              context.semanticColors.primary.withValues(alpha: .82),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thực đơn',
                        style: AppTextStyles.heading1.copyWith(
                          color: context.semanticColors.surface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Dinh dưỡng theo ngày',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.semanticColors.surface
                              .withValues(alpha: .8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Làm mới thực đơn',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.dates,
    required this.selected,
    required this.onChanged,
  });
  final List<DateTime> dates;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) => Container(
        color: context.semanticColors.surface,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final date = dates[index];
              final active = DateUtils.isSameDay(date, selected);
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => onChanged(date),
                child: AnimatedContainer(
                  duration: AppMotionScope.duration(context, AppDuration.fast),
                  width: 54,
                  decoration: BoxDecoration(
                    color: active
                        ? context.semanticColors.primary
                        : context.semanticColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _labels[date.weekday - 1],
                        style: AppTextStyles.labelSmall.copyWith(
                          color: active
                              ? context.semanticColors.surface
                              : context.semanticColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${date.day}',
                        style: AppTextStyles.heading4.copyWith(
                          color: active
                              ? context.semanticColors.surface
                              : context.semanticColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.date, required this.count});
  final DateTime date;
  final int count;
  static const _names = [
    'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
  ];

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateUtils.isSameDay(date, DateTime.now())
                      ? 'Hôm nay'
                      : _names[date.weekday - 1],
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _Pill('$count bữa'),
        ],
      );
}

class _MealPlanCard extends ConsumerWidget {
  const _MealPlanCard({required this.meal});
  final MealPlanEntity meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = MealDetailContentFormatter.fromMeal(meal);
    return Semantics(
      button: true,
      label: '${_mealLabel(meal.mealType, meal.mealOrder)}, ${content.mealName}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => _showDetails(context, ref),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: AppDecoration.card(
            color: context.semanticColors.surface,
            radius: AppRadius.xl,
            shadows: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MealPhoto(meal: meal, height: 172, borderRadius: AppRadius.lg),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mealLabel(meal.mealType, meal.mealOrder).toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.semanticColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          content.mealName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading3,
                        ),
                      ],
                    ),
                  ),
                  if (content.showNutrition && content.calories > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _EnergyBadge(calories: content.calories),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Pill(_timeLabel(meal)),
                  if (content.servingSize.isNotEmpty) _Pill(content.servingSize),
                  if (content.isEstimated)
                    const _Pill('Ước tính / khẩu phần'),
                ],
              ),
              if (content.showNutrition) ...[
                const SizedBox(height: AppSpacing.md),
                _MacroStrip(content: content),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    meal.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: context.semanticColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      meal.isCompleted ? 'Đã hoàn thành' : 'Chạm để xem chi tiết',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.semanticColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, WidgetRef ref) async {
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MealDetailSheet(
        meal: meal,
        onReplace: meal.isCompleted
            ? null
            : () => _showReplacementMenu(
                  pageContext: context,
                  sheetContext: sheetContext,
                  ref: ref,
                ),
      ),
    );
  }

  Future<void> _showReplacementMenu({
    required BuildContext pageContext,
    required BuildContext sheetContext,
    required WidgetRef ref,
  }) async {
    final controller = ref.read(mealPlanControllerProvider.notifier);
    final result = await showModalBottomSheet<MealReplacementResult>(
      context: sheetContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealReplacementSheet(
        candidatesFuture: controller.loadReplacementCandidates(meal.id),
        onConfirm: (candidate) => controller.replaceMealByCatalogCode(
          mealId: meal.id,
          catalogCode: candidate.code,
        ),
      ),
    );
    if (result == null) return;
    AppFeedbackService.instance.emit(AppFeedbackType.success);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!pageContext.mounted) return;
    final message = switch (result.syncStatus) {
      MealReplacementSyncStatus.synced => 'Đã đổi món và đồng bộ.',
      MealReplacementSyncStatus.pending =>
        'Đã đổi món. Dữ liệu sẽ được đồng bộ khi kết nối ổn định.',
      MealReplacementSyncStatus.localOnly => 'Đã đổi món trên thiết bị.',
    };
    ScaffoldMessenger.of(pageContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MacroStrip extends StatelessWidget {
  const _MacroStrip({required this.content});
  final MealDetailContent content;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _MacroCell(label: 'Protein', value: content.protein)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _MacroCell(label: 'Carb', value: content.carbs)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _MacroCell(label: 'Chất béo', value: content.fat)),
        ],
      );
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.semanticColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_number(value)} g',
              maxLines: 1,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

class _EnergyBadge extends StatelessWidget {
  const _EnergyBadge({required this.calories});
  final int calories;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.semanticColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text('$calories', style: AppTextStyles.heading4),
            Text('kcal', style: AppTextStyles.labelSmall),
          ],
        ),
      );
}

class _MealDetailSheet extends StatefulWidget {
  const _MealDetailSheet({required this.meal, required this.onReplace});
  final MealPlanEntity meal;
  final Future<void> Function()? onReplace;
  @override
  State<_MealDetailSheet> createState() => _MealDetailSheetState();
}

class _MealDetailSheetState extends State<_MealDetailSheet> {
  bool _replacing = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final content = MealDetailContentFormatter.fromMeal(meal);
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .58,
      maxChildSize: .96,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          children: [
            Row(
              children: [
                Expanded(child: Text(content.mealName, style: AppTextStyles.heading2)),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (content.topicName.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                content.topicName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.semanticColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            MealPhoto(meal: meal, height: 220, borderRadius: AppRadius.xl),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (content.servingSize.isNotEmpty) _Pill(content.servingSize),
                if (meal.startTime.trim().isNotEmpty) _Pill(meal.startTime),
              ],
            ),
            if (content.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(icon: Icons.notes_rounded, title: 'Mô tả món ăn'),
              const SizedBox(height: AppSpacing.sm),
              Text(content.description, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
            ],
            if (content.showNutrition) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              _NutritionPanel(content: content),
            ],
            if (content.ingredients.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(icon: Icons.shopping_basket_rounded, title: 'Nguyên liệu'),
              const SizedBox(height: AppSpacing.sm),
              ...content.ingredients.map((item) => _Bullet(text: item)),
            ],
            if (content.cookingSteps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(icon: Icons.soup_kitchen_rounded, title: 'Cách chế biến'),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < content.cookingSteps.length; i++)
                _RecipeStep(number: i + 1, text: content.cookingSteps[i]),
            ],
            if (content.benefits.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(icon: Icons.spa_rounded, title: 'Lợi ích'),
              const SizedBox(height: AppSpacing.sm),
              Text(content.benefits, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
            ],
            if (content.hasWarnings) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(icon: Icons.health_and_safety_outlined, title: 'Lưu ý'),
              const SizedBox(height: AppSpacing.sm),
              if (content.allergenTags.isNotEmpty)
                _Warning(title: 'Dị ứng', values: content.allergenTags),
              if (content.avoidConditionTags.isNotEmpty)
                _Warning(title: 'Nên tránh khi', values: content.avoidConditionTags),
            ],
            if (content.sourceLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: context.semanticColors.info.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  'Nguồn công thức: ${content.sourceLabel}. Dữ liệu dinh dưỡng ước tính không thay thế tư vấn chuyên môn.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sectionSpacing),
            if (widget.onReplace != null)
              FilledButton.icon(
                onPressed: _replacing ? null : _replace,
                icon: _replacing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                label: Text(_replacing ? 'Đang mở danh sách...' : 'Đổi món khác'),
              )
            else
              Text(
                'Bữa đã hoàn thành nên không thể đổi món.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.semanticColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _replace() async {
    final callback = widget.onReplace;
    if (callback == null) return;
    setState(() => _replacing = true);
    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() => _replacing = false);
      }
    }
  }
}

class _NutritionPanel extends StatelessWidget {
  const _NutritionPanel({required this.content});
  final MealDetailContent content;

  @override
  Widget build(BuildContext context) {
    final macro = <(String, String)>[
      if (content.protein > 0) ('Protein', '${_number(content.protein)} g'),
      if (content.carbs > 0) ('Carb', '${_number(content.carbs)} g'),
      if (content.fat > 0) ('Chất béo', '${_number(content.fat)} g'),
      if (content.fiber > 0) ('Chất xơ', '${_number(content.fiber)} g'),
      if (_positive(content.sugarG)) ('Đường', '${_number(content.sugarG!)} g'),
      if (_positive(content.saturatedFatG))
        ('Béo bão hòa', '${_number(content.saturatedFatG!)} g'),
    ];
    final micro = <(String, String)>[
      if (_positive(content.sodiumMg)) ('Natri', '${_number(content.sodiumMg!)} mg'),
      if (_positive(content.potassiumMg)) ('Kali', '${_number(content.potassiumMg!)} mg'),
      if (_positive(content.calciumMg)) ('Canxi', '${_number(content.calciumMg!)} mg'),
      if (_positive(content.ironMg)) ('Sắt', '${_number(content.ironMg!)} mg'),
      if (_positive(content.cholesterolMg))
        ('Cholesterol', '${_number(content.cholesterolMg!)} mg'),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: context.semanticColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(content.nutritionLabel, style: AppTextStyles.heading4),
              ),
            ],
          ),
          if (content.calories > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Năng lượng', style: AppTextStyles.labelSmall),
            Text(
              '${content.calories} kcal',
              style: AppTextStyles.heading2.copyWith(
                color: context.semanticColors.primary,
              ),
            ),
          ],
          if (macro.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Đa lượng', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            _NutrientGrid(items: macro),
          ],
          if (micro.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Khoáng chất & vi chất', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            _NutrientGrid(items: micro),
          ],
          if (content.waterMl > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Lượng chất lỏng trong công thức: ${content.waterMl} ml',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientGrid extends StatelessWidget {
  const _NutrientGrid({required this.items});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width >= 520 ? (width - AppSpacing.sm * 2) / 3 : (width - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in items)
                SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.semanticColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: AppTextStyles.labelSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(item.$2, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

class _MealReplacementSheet extends StatefulWidget {
  const _MealReplacementSheet({required this.candidatesFuture, required this.onConfirm});
  final Future<List<MealReplacementCandidateEntity>> candidatesFuture;
  final Future<MealReplacementResult> Function(MealReplacementCandidateEntity candidate) onConfirm;
  @override
  State<_MealReplacementSheet> createState() => _MealReplacementSheetState();
}

class _MealReplacementSheetState extends State<_MealReplacementSheet> {
  MealReplacementCandidateEntity? _selected;
  bool _saving = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .82,
        minChildSize: .55,
        maxChildSize: .95,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: context.semanticColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đổi món', style: AppTextStyles.heading2),
                          Text(
                            'Các món đã lọc theo hồ sơ và bữa ăn.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.semanticColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<MealReplacementCandidateEntity>>(
                  future: widget.candidatesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const _MealEmptyView(
                        title: 'Chưa tải được danh sách món',
                        subtitle: 'Bạn đóng cửa sổ này và thử lại nhé.',
                      );
                    }
                    final candidates = snapshot.data ?? const [];
                    if (candidates.isEmpty) {
                      return const _MealEmptyView(
                        title: 'Chưa có món thay thế phù hợp',
                        subtitle: 'Nabi sẽ giữ món hiện tại cho bạn.',
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePaddingLarge,
                      ),
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final selected = _selected?.code == candidate.code;
                        return InkWell(
                          onTap: _saving ? null : () => setState(() {
                            _selected = candidate;
                            _failed = false;
                          }),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: selected
                                  ? context.semanticColors.primarySoft
                                  : context.semanticColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: selected
                                    ? context.semanticColors.primary
                                    : context.semanticColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(candidate.mealName, style: AppTextStyles.heading4),
                                      if (candidate.healthTopicName.trim().isNotEmpty)
                                        Text(
                                          candidate.healthTopicName,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: context.semanticColors.primary,
                                          ),
                                        ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        children: [
                                          if (candidate.calories > 0) _Pill('${candidate.calories} kcal'),
                                          if (candidate.servingSize.trim().isNotEmpty) _Pill(candidate.servingSize),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: selected ? context.semanticColors.primary : context.semanticColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_failed) ...[
                      Text('Chưa thể đổi món này. Bạn thử lại nhé.', style: AppTextStyles.bodySmall.copyWith(color: context.semanticColors.error)),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    FilledButton.icon(
                      onPressed: _selected == null || _saving ? null : _confirm,
                      icon: _saving
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'Đang đổi món...' : _selected == null ? 'Chọn một món' : 'Chọn món này'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final result = await widget.onConfirm(selected);
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: AppTextStyles.heading4)),
        ],
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.semanticColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(text, style: AppTextStyles.bodySmall),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: CircleAvatar(radius: 3, backgroundColor: context.semanticColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(height: 1.5))),
          ],
        ),
      );
}

class _RecipeStep extends StatelessWidget {
  const _RecipeStep({required this.number, required this.text});
  final int number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.semanticColors.primary,
              child: Text('$number', style: AppTextStyles.labelMedium.copyWith(color: context.semanticColors.surface)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(height: 1.5))),
          ],
        ),
      );
}

class _Warning extends StatelessWidget {
  const _Warning({required this.title, required this.values});
  final String title;
  final List<String> values;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.semanticColors.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text('$title: ${values.join(' • ')}', style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
      );
}

class _MealLoadingView extends StatelessWidget {
  const _MealLoadingView();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _MealEmptyView extends StatelessWidget {
  const _MealEmptyView({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 44, color: context.semanticColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: context.semanticColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _MealErrorView extends StatelessWidget {
  const _MealErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 42, color: context.semanticColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Nabi chưa mở được thực đơn', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Thử lại')),
            ],
          ),
        ),
      );
}

String _mealLabel(String type, int order) => switch (type.trim().toLowerCase()) {
      'breakfast' => 'Bữa sáng',
      'morning_snack' => 'Bữa phụ sáng',
      'lunch' => 'Bữa trưa',
      'afternoon_snack' => 'Bữa phụ chiều',
      'dinner' => 'Bữa tối',
      'snack' => 'Bữa phụ',
      _ => 'Bữa ${order > 0 ? order : ''}'.trim(),
    };

String _timeLabel(MealPlanEntity meal) {
  if (meal.startTime.trim().isNotEmpty && meal.endTime.trim().isNotEmpty) {
    return '${meal.startTime} – ${meal.endTime}';
  }
  if (meal.startTime.trim().isNotEmpty) return meal.startTime;
  return switch (meal.mealType.trim().toLowerCase()) {
    'breakfast' => '06:30 – 08:00',
    'morning_snack' => '09:30 – 09:45',
    'lunch' => '11:30 – 13:00',
    'afternoon_snack' => '15:30 – 15:45',
    'dinner' => '18:00 – 19:30',
    _ => 'Theo lịch cá nhân',
  };
}

String _number(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
bool _positive(double? value) => value != null && value > 0;
