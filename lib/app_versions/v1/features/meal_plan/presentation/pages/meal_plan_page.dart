import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_detail_content_formatter.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';
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

    final availableDates = _extractAvailableDates(meals);
    if (availableDates.isEmpty) {
      return const _MealEmptyView(
        title: 'Mình chưa sắp được lịch ăn',
        subtitle: 'Dữ liệu thực đơn đang được chuẩn bị.',
      );
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final defaultDate = availableDates.any((date) => DateUtils.isSameDay(date, today))
        ? today
        : availableDates.first;
    final selected = _selectedDate != null &&
            availableDates.any((date) => DateUtils.isSameDay(date, _selectedDate))
        ? _selectedDate!
        : defaultDate;

    if (_selectedDate == null || !DateUtils.isSameDay(_selectedDate, selected)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !DateUtils.isSameDay(_selectedDate, selected)) {
          setState(() => _selectedDate = selected);
        }
      });
    }

    final filtered = meals.where((meal) {
      final date = _parseMealDate(meal.planDate);
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

  List<DateTime> _extractAvailableDates(List<MealPlanEntity> meals) {
    final dates = <DateTime>{};
    for (final meal in meals) {
      final date = _parseMealDate(meal.planDate);
      if (date != null) dates.add(DateUtils.dateOnly(date));
    }
    return dates.toList()..sort();
  }

  DateTime? _parseMealDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateUtils.dateOnly(iso);

    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(trimmed);
    if (slash == null) return null;
    return DateTime(
      int.parse(slash.group(3)!),
      int.parse(slash.group(2)!),
      int.parse(slash.group(1)!),
    );
  }
}

class _MealPlanHeader extends StatelessWidget {
  const _MealPlanHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                        color: context.semanticColors.surface.withValues(alpha: .78),
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

  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.semanticColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          itemCount: dates.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final date = dates[index];
            final active = DateUtils.isSameDay(date, selected);
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => onChanged(date),
              child: AnimatedContainer(
                duration: AppDuration.fast,
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
                      _dayLabels[date.weekday - 1],
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
                        fontWeight: FontWeight.w900,
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
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    const names = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final today = DateUtils.isSameDay(date, DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today ? 'Hôm nay' : names[date.weekday - 1],
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.semanticColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count bữa',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MealPlanCard extends ConsumerWidget {
  const _MealPlanCard({required this.meal});

  final MealPlanEntity meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = MealDetailContentFormatter.fromMeal(meal);
    final label = _mealLabel(meal.mealType, meal.mealOrder);
    final time = _timeLabel(meal);

    return Semantics(
      button: true,
      label: '$label, ${detail.mealName}',
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
              MealPhoto(
                meal: meal,
                height: 176,
                borderRadius: AppRadius.lg,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.semanticColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail.mealName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3,
              ),
              if (detail.topicName.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail.topicName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
              ],
              if (detail.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.semanticColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _InlineTag(icon: Icons.schedule_rounded, label: time),
                  if (detail.servingSize.isNotEmpty)
                    _InlineTag(
                      icon: Icons.person_outline_rounded,
                      label: detail.servingSize,
                    ),
                  if (detail.showNutrition && detail.calories > 0)
                    _InlineTag(
                      icon: Icons.local_fire_department_rounded,
                      label: '${detail.calories} kcal',
                    ),
                  if (detail.showNutrition && detail.waterMl > 0)
                    _InlineTag(
                      icon: Icons.water_drop_rounded,
                      label: '${detail.waterMl} ml',
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatusBadge(
                    icon: meal.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    label: meal.isCompleted ? 'Đã hoàn thành' : 'Chờ thực hiện',
                  ),
                  _StatusBadge(
                    icon: meal.aiGenerated
                        ? Icons.auto_awesome_rounded
                        : Icons.edit_rounded,
                    label: meal.aiGenerated ? 'Nabi tạo' : 'Thủ công',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      detail.hasRecipe
                          ? 'Chạm để xem nguyên liệu và cách chế biến'
                          : 'Chạm để xem thông tin chi tiết',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.primary,
                        fontWeight: FontWeight.w700,
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
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
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

  static String _mealLabel(String type, int order) {
    switch (type.trim().toLowerCase()) {
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
      case 'snack':
        return 'Bữa phụ';
      default:
        return 'Bữa ${order > 0 ? order : ''}'.trim();
    }
  }

  static String _timeLabel(MealPlanEntity meal) {
    if (meal.startTime.trim().isNotEmpty && meal.endTime.trim().isNotEmpty) {
      return '${meal.startTime} – ${meal.endTime}';
    }
    if (meal.startTime.trim().isNotEmpty) return meal.startTime;
    switch (meal.mealType.trim().toLowerCase()) {
      case 'breakfast':
        return '06:30 – 08:00';
      case 'morning_snack':
        return '09:30 – 09:45';
      case 'lunch':
        return '11:30 – 13:00';
      case 'afternoon_snack':
        return '15:30 – 15:45';
      case 'dinner':
        return '18:00 – 19:30';
      default:
        return 'Theo lịch cá nhân';
    }
  }
}


class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.semanticColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
      initialChildSize: .84,
      minChildSize: .56,
      maxChildSize: .96,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.semanticColors.border,
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(content.mealName, style: AppTextStyles.heading2),
                            if (content.topicName.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: context.semanticColors.primarySoft,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  content.topicName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.semanticColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
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
                  const SizedBox(height: AppSpacing.md),
                  MealPhoto(
                    meal: meal,
                    height: 220,
                    borderRadius: AppRadius.xl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (content.showNutrition && content.calories > 0)
                        _DetailPill('${content.calories} kcal'),
                      if (content.servingSize.isNotEmpty)
                        _DetailPill(content.servingSize),
                      if (meal.startTime.trim().isNotEmpty)
                        _DetailPill(meal.startTime),
                    ],
                  ),
                  if (content.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.notes_rounded,
                      title: 'Mô tả món ăn',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      content.description,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                    ),
                  ],
                  if (content.showNutrition) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.monitor_heart_outlined,
                      title: 'Dinh dưỡng',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _NutritionSummary(content: content),
                  ],
                  if (content.ingredients.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.shopping_basket_rounded,
                      title: 'Nguyên liệu',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...content.ingredients.map(
                      (ingredient) => _BulletLine(text: ingredient),
                    ),
                  ],
                  if (content.cookingSteps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.soup_kitchen_rounded,
                      title: 'Cách chế biến',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var index = 0; index < content.cookingSteps.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index == content.cookingSteps.length - 1
                              ? 0
                              : AppSpacing.md,
                        ),
                        child: _RecipeStep(
                          number: index + 1,
                          text: content.cookingSteps[index],
                        ),
                      ),
                  ],
                  if (content.benefits.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.spa_rounded,
                      title: 'Lợi ích',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      content.benefits,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                    ),
                  ],
                  if (content.hasWarnings) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Lưu ý',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (content.allergenTags.isNotEmpty)
                      _WarningGroup(
                        title: 'Dị ứng',
                        values: content.allergenTags,
                      ),
                    if (content.avoidConditionTags.isNotEmpty)
                      _WarningGroup(
                        title: 'Nên tránh khi',
                        values: content.avoidConditionTags,
                      ),
                  ],
                  if (content.sourceLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: context.semanticColors.info.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nguồn tham khảo',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.semanticColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            content.sourceLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.semanticColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Nội dung tham khảo, không thay thế tư vấn chuyên môn.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.semanticColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Icon(Icons.swap_horiz_rounded),
                      label: Text(
                        _replacing ? 'Đang mở danh sách...' : 'Đổi món khác',
                      ),
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
      if (mounted) setState(() => _replacing = false);
    }
  }
}


class _MealReplacementSheet extends StatefulWidget {
  const _MealReplacementSheet({
    required this.candidatesFuture,
    required this.onConfirm,
  });

  final Future<List<MealReplacementCandidateEntity>> candidatesFuture;
  final Future<MealReplacementResult> Function(
    MealReplacementCandidateEntity candidate,
  ) onConfirm;

  @override
  State<_MealReplacementSheet> createState() => _MealReplacementSheetState();
}

class _MealReplacementSheetState extends State<_MealReplacementSheet> {
  MealReplacementCandidateEntity? _selected;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .86,
      minChildSize: .58,
      maxChildSize: .96,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.semanticColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.semanticColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingLarge,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đổi món', style: AppTextStyles.heading2),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Các món phù hợp với bạn',
                          style: AppTextStyles.heading4.copyWith(
                            color: context.semanticColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Danh sách đã lọc theo bữa ăn, hồ sơ sức khỏe và các lưu ý ăn uống của bạn.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.semanticColors.textSecondary,
                            height: 1.4,
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
                    return _ReplacementMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Chưa tải được danh sách món',
                      message:
                          'Bạn đóng cửa sổ này và thử lại sau một chút nhé.',
                    );
                  }

                  final candidates =
                      snapshot.data ?? const <MealReplacementCandidateEntity>[];
                  if (candidates.isEmpty) {
                    return const _ReplacementMessage(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Chưa có món thay thế phù hợp',
                      message:
                          'Hiện chưa có món khác phù hợp với bữa ăn và hồ sơ sức khỏe của bạn.',
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePaddingLarge,
                      AppSpacing.sm,
                      AppSpacing.pagePaddingLarge,
                      AppSpacing.pagePaddingLarge,
                    ),
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      return _ReplacementCandidateCard(
                        candidate: candidate,
                        selected: _selected?.code == candidate.code,
                        enabled: !_saving,
                        onTap: () => setState(() {
                          _selected = candidate;
                          _saveFailed = false;
                        }),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingLarge,
                AppSpacing.sm,
                AppSpacing.pagePaddingLarge,
                AppSpacing.pagePaddingLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveFailed) ...[
                    Text(
                      'Chưa thể đổi sang món này. Bạn chọn món khác hoặc thử lại nhé.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.semanticColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FilledButton.icon(
                    onPressed: _selected == null || _saving ? null : _confirm,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _saving
                          ? 'Đang đổi món...'
                          : _selected == null
                              ? 'Chọn một món'
                              : 'Chọn món này',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _saving) return;

    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final result = await widget.onConfirm(selected);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }
}

class _ReplacementCandidateCard extends StatelessWidget {
  const _ReplacementCandidateCard({
    required this.candidate,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MealReplacementCandidateEntity candidate;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? context.semanticColors.primary
        : context.semanticColors.border;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Chọn ${candidate.mealName}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: AppMotionScope.duration(context, AppDuration.fast),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? context.semanticColors.primarySoft
                : context.semanticColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReplacementCandidateImage(candidate: candidate),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            candidate.mealName,
                            style: AppTextStyles.heading4,
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? context.semanticColors.primary
                              : context.semanticColors.textSecondary,
                        ),
                      ],
                    ),
                    if (candidate.healthTopicName.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        candidate.healthTopicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.semanticColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (candidate.description.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        candidate.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.semanticColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (candidate.calories > 0 ||
                        candidate.servingSize.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (candidate.calories > 0)
                            _DetailPill('${candidate.calories} kcal'),
                          if (candidate.servingSize.trim().isNotEmpty)
                            _DetailPill(candidate.servingSize),
                        ],
                      ),
                    ],
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

class _ReplacementCandidateImage extends StatelessWidget {
  const _ReplacementCandidateImage({required this.candidate});

  final MealReplacementCandidateEntity candidate;

  @override
  Widget build(BuildContext context) {
    final assetPath = MealImageResolver.resolveAssetPath(candidate.mealName);
    final fallback = Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.semanticColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: context.semanticColors.primary,
      ),
    );
    if (assetPath == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.asset(
        assetPath,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _ReplacementMessage extends StatelessWidget {
  const _ReplacementMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: context.semanticColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({required this.content});

  final MealDetailContent content;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (content.calories > 0) ('Năng lượng', '${content.calories} kcal'),
      if (content.protein > 0) ('Protein', '${_number(content.protein)} g'),
      if (content.carbs > 0) ('Carb', '${_number(content.carbs)} g'),
      if (content.fat > 0) ('Chất béo', '${_number(content.fat)} g'),
      if (content.fiber > 0) ('Chất xơ', '${_number(content.fiber)} g'),
      if (content.waterMl > 0) ('Nước', '${content.waterMl} ml'),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.semanticColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.$1,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.$2,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _number(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.semanticColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: AppTextStyles.heading4)),
      ],
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.semanticColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: context.semanticColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeStep extends StatelessWidget {
  const _RecipeStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.semanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semanticColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.semanticColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.semanticColors.surface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningGroup extends StatelessWidget {
  const _WarningGroup({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.semanticColors.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              values.join(' • '),
              style: AppTextStyles.bodySmall.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealLoadingView extends StatelessWidget {
  const _MealLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MealEmptyView extends StatelessWidget {
  const _MealEmptyView({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 46,
              color: context.semanticColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealErrorView extends StatelessWidget {
  const _MealErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: context.semanticColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Nabi chưa mở được thực đơn', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bạn thử làm mới lại sau một chút nhé.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
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
    );
  }
}
