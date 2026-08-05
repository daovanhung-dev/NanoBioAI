import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────

class MealPlanPage extends ConsumerStatefulWidget {
  const MealPlanPage({super.key});

  @override
  ConsumerState<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends ConsumerState<MealPlanPage> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final ui = _MealPlanResponsiveUi.of(context);
    final mealState = ref.watch(mealPlanControllerProvider);

    return MedicalPageScaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _MealPlanHeader(
            ui: ui,
            onRefresh: () => ref
                .read(mealPlanControllerProvider.notifier)
                .refreshMealPlans(),
          ),
          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: mealState.when(
              loading: () => _MealLoadingView(ui: ui),
              error: (error, _) => _MealErrorView(
                ui: ui,
                error:
                    'Nabi chưa thể mở thực đơn lúc này. Bạn thử làm mới lại sau một chút nhé.',
                onRetry: () => ref
                    .read(mealPlanControllerProvider.notifier)
                    .refreshMealPlans(),
              ),
              data: (meals) {
                if (meals.isEmpty) {
                  return _MealEmptyView(
                    ui: ui,
                    title: 'Mình chưa chuẩn bị xong thực đơn',
                    subtitle:
                        'Bạn quay lại sau một chút nhé, mình đang chọn những món phù hợp.',
                  );
                }

                final availableDates = _extractAvailableDates(meals);
                if (availableDates.isEmpty) {
                  return _MealEmptyView(
                    ui: ui,
                    title: 'Mình chưa sắp được lịch ăn',
                    subtitle:
                        'Dữ liệu đang được chuẩn bị, bạn chờ mình một chút nhé.',
                  );
                }

                final today = DateUtils.dateOnly(DateTime.now());
                final defaultDate =
                    availableDates.any((d) => DateUtils.isSameDay(d, today))
                    ? today
                    : availableDates.first;

                if (_selectedDate == null ||
                    !_containsDate(availableDates, _selectedDate!)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final current = _extractAvailableDates(meals);
                    if (current.isEmpty) return;
                    final currentToday = DateUtils.dateOnly(DateTime.now());
                    final currentDefault =
                        current.any((d) => DateUtils.isSameDay(d, currentToday))
                        ? currentToday
                        : current.first;
                    if (_selectedDate == null ||
                        !_containsDate(current, _selectedDate!)) {
                      setState(() => _selectedDate = currentDefault);
                    }
                  });
                }

                final selectedDate = _selectedDate ?? defaultDate;
                final filteredMeals = meals.where((m) {
                  final d = _parseMealDate(m.planDate);
                  return d != null && DateUtils.isSameDay(d, selectedDate);
                }).toList()..sort((a, b) => a.mealOrder.compareTo(b.mealOrder));

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ui.contentMaxWidth),
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async => ref
                        .read(mealPlanControllerProvider.notifier)
                        .refreshMealPlans(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // ── Date chip selector ─────────────────────────
                        SliverToBoxAdapter(
                          child: _DateChipSelector(
                            ui: ui,
                            selectedDate: selectedDate,
                            availableDates: availableDates,
                            onChanged: (d) => setState(() => _selectedDate = d),
                          ),
                        ),

                        // ── Selected day summary ───────────────────────
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            ui.pagePadding,
                            ui.sectionSpacing,
                            ui.pagePadding,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _DaySummaryBanner(
                              ui: ui,
                              selectedDate: selectedDate,
                              mealCount: filteredMeals.length,
                            ),
                          ),
                        ),

                        // ── Meal cards ─────────────────────────────────
                        if (filteredMeals.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _MealEmptyView(
                              ui: ui,
                              title: 'Hôm nay mình chưa có món để gợi ý',
                              subtitle:
                                  'Hãy chọn một ngày khác ở thanh chọn ngày bên trên.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              ui.pagePadding,
                              ui.sectionSpacing,
                              ui.pagePadding,
                              ui.pagePadding * 2,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                if (i.isOdd) {
                                  return SizedBox(height: ui.cardGap);
                                }
                                final meal = filteredMeals[i ~/ 2];
                                return _AnimatedMealCard(
                                  ui: ui,
                                  meal: meal,
                                  index: i ~/ 2,
                                );
                              }, childCount: filteredMeals.length * 2 - 1),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _extractAvailableDates(List<MealPlanEntity> meals) {
    final dates = <DateTime>{};
    for (final m in meals) {
      final p = _parseMealDate(m.planDate);
      if (p != null) dates.add(DateUtils.dateOnly(p));
    }
    return dates.toList()..sort((a, b) => a.compareTo(b));
  }

  bool _containsDate(List<DateTime> dates, DateTime target) =>
      dates.any((d) => DateUtils.isSameDay(d, target));

  DateTime? _parseMealDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateUtils.dateOnly(iso);

    final isoRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final isoM = isoRe.firstMatch(trimmed);
    if (isoM != null) {
      return DateTime(
        int.parse(isoM.group(1)!),
        int.parse(isoM.group(2)!),
        int.parse(isoM.group(3)!),
      );
    }

    final slashRe = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final slashM = slashRe.firstMatch(trimmed);
    if (slashM != null) {
      return DateTime(
        int.parse(slashM.group(3)!),
        int.parse(slashM.group(2)!),
        int.parse(slashM.group(1)!),
      );
    }

    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER  (replaces _MealPlanAppBar)
// ─────────────────────────────────────────────────────────────────────────────

class _MealPlanHeader extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final VoidCallback onRefresh;

  const _MealPlanHeader({required this.ui, required this.onRefresh});

  String _todayLabel() {
    final now = DateTime.now();
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    const months = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -ui.pagePadding * 1.5,
              right: -ui.pagePadding * 1.5,
              child: _DecorativeCircle(
                size: ui.headerDecorSize,
                color: AppColors.surface.withValues(alpha: 0.07),
              ),
            ),
            Positioned(
              bottom: ui.pagePadding * 0.5,
              left: -ui.pagePadding,
              child: _DecorativeCircle(
                size: ui.headerDecorSize * 0.55,
                color: AppColors.surface.withValues(alpha: 0.05),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(
                ui.pagePadding,
                ui.headerTopPadding,
                ui.pagePadding,
                ui.headerBottomPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                _todayLabel(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: ui.headerDateFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.surface.withValues(alpha: 0.9),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ui.smallGap),
                        Text(
                          'Thực đơn',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: ui.titleFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.surface,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: ui.xsGap),
                        Text(
                          'Dinh dưỡng theo ngày',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: ui.headerSubtitleFontSize,
                            color: AppColors.surface.withValues(alpha: 0.72),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: ui.smallGap),
                  Semantics(
                    button: true,
                    label: 'Giúp mình chuẩn bị lại thực đơn',
                    child: GestureDetector(
                      onTap: onRefresh,
                      child: Container(
                        height: ui.actionButtonSize,
                        width: ui.actionButtonSize,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(ui.radiusLg),
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: AppColors.surface,
                          size: ui.actionIconSize,
                        ),
                      ),
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
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE CHIP SELECTOR  (replaces _MealDateFilterCard with dropdown)
// ─────────────────────────────────────────────────────────────────────────────

class _DateChipSelector extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final DateTime selectedDate;
  final List<DateTime> availableDates;
  final ValueChanged<DateTime> onChanged;

  const _DateChipSelector({
    required this.ui,
    required this.selectedDate,
    required this.availableDates,
    required this.onChanged,
  });

  static const _dayAbbr = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(vertical: ui.chipSectionVertical),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ui.pagePadding),
            child: Text(
              'Chọn ngày',
              style: AppTextStyles.heading4.copyWith(
                fontSize: ui.bodySmallFontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: ui.smallGap),
          SizedBox(
            height: ui.chipHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: ui.pagePadding),
              itemCount: availableDates.length,
              separatorBuilder: (_, __) => SizedBox(width: ui.chipGap),
              itemBuilder: (context, index) {
                final date = availableDates[index];
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                final isToday = DateUtils.isSameDay(date, today);
                final dayAbbr = _dayAbbr[date.weekday - 1];

                return _DateChip(
                  ui: ui,
                  date: date,
                  dayAbbr: dayAbbr,
                  isSelected: isSelected,
                  isToday: isToday,
                  onTap: () => onChanged(date),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final DateTime date;
  final String dayAbbr;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DateChip({
    required this.ui,
    required this.date,
    required this.dayAbbr,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        width: ui.chipWidth,
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primary : null,
          color: isSelected ? null : AppColors.background,
          borderRadius: BorderRadius.circular(ui.radiusLg),
          border: isToday && !isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected ? AppShadows.primary : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayAbbr,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: ui.chipDayFontSize,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.surface.withValues(alpha: 0.85)
                    : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: ui.tinyGap),
            Text(
              '${date.day}',
              style: AppTextStyles.heading4.copyWith(
                fontSize: ui.chipDateFontSize,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
            if (isToday) ...[
              SizedBox(height: ui.tinyGap),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.surface : AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY SUMMARY BANNER  (replaces _TodaySummaryCard)
// ─────────────────────────────────────────────────────────────────────────────

class _DaySummaryBanner extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final DateTime selectedDate;
  final int mealCount;

  const _DaySummaryBanner({
    required this.ui,
    required this.selectedDate,
    required this.mealCount,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = DateUtils.isSameDay(selectedDate, today);
    final dd = selectedDate.day.toString().padLeft(2, '0');
    final mm = selectedDate.month.toString().padLeft(2, '0');
    final dateStr = '$dd/$mm/${selectedDate.year}';

    const dayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayName = dayNames[selectedDate.weekday - 1];

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'Hôm nay' : dayName,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: ui.summaryTitleFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              SizedBox(height: ui.tinyGap),
              Text(
                dateStr,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: ui.bodySmallFontSize,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ui.cardPadding,
            vertical: ui.smallPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(ui.circularRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_rounded,
                size: ui.filterIconSize,
                color: AppColors.primary,
              ),
              SizedBox(width: ui.xsGap + 2),
              Text(
                '$mealCount bữa',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: ui.bodySmallFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED WRAPPER  (staggered entrance)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedMealCard extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final MealPlanEntity meal;
  final int index;

  const _AnimatedMealCard({
    required this.ui,
    required this.meal,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: _MealPlanCard(ui: ui, meal: meal),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEAL PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MealPlanCard extends ConsumerStatefulWidget {
  final _MealPlanResponsiveUi ui;
  final MealPlanEntity meal;

  const _MealPlanCard({required this.ui, required this.meal});

  @override
  ConsumerState<_MealPlanCard> createState() => _MealPlanCardState();
}

class _MealPlanCardState extends ConsumerState<_MealPlanCard> {
  bool _isPressed = false;

  static String _mealLabel(String type, int order) {
    switch (type.toLowerCase().trim()) {
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
        switch (order) {
          case 1:
            return 'Bữa sáng';
          case 2:
            return 'Bữa trưa';
          case 3:
            return 'Bữa tối';
          case 4:
            return 'Bữa phụ';
          default:
            return 'Bữa ăn';
        }
    }
  }

  static String _timeLabel(MealPlanEntity meal) {
    if (meal.startTime.isNotEmpty && meal.endTime.isNotEmpty) {
      return '${meal.startTime} - ${meal.endTime}';
    }
    if (meal.startTime.isNotEmpty) return meal.startTime;

    final type = meal.mealType;
    final order = meal.mealOrder;
    switch (type.toLowerCase().trim()) {
      case 'breakfast':
        return '06:30 – 08:00';
      case 'morning_snack':
        return '09:30 - 09:45';
      case 'lunch':
        return '11:30 – 13:00';
      case 'afternoon_snack':
        return '15:30 - 15:45';
      case 'dinner':
        return '18:00 – 19:30';
      case 'snack':
        return '09:30 & 15:30';
      default:
        switch (order) {
          case 1:
            return 'Buổi sáng';
          case 2:
            return 'Buổi trưa';
          case 3:
            return 'Buổi tối';
          default:
            return 'Bữa phụ';
        }
    }
  }

  static Color _accentColor(String type, int order) {
    switch (type.toLowerCase().trim()) {
      case 'breakfast':
        return AppColors.warning; // amber
      case 'morning_snack':
        return AppColors.error; // pink
      case 'lunch':
        return AppColors.primary; // emerald
      case 'afternoon_snack':
        return AppColors.secondary; // cyan
      case 'dinner':
        return AppColors.tertiary; // indigo
      case 'snack':
        return AppColors.error; // pink
      default:
        switch (order) {
          case 1:
            return AppColors.warning;
          case 2:
            return AppColors.primary;
          case 3:
            return AppColors.tertiary;
          default:
            return AppColors.error;
        }
    }
  }

  static IconData _mealIcon(String type) {
    switch (type.toLowerCase().trim()) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'morning_snack':
        return Icons.cookie_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'afternoon_snack':
        return Icons.local_cafe_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Future<void> _showMealDetails() async {
    setState(() => _isPressed = false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MealDetailSheet(
        meal: widget.meal,
        onReplace: widget.meal.isCompleted
            ? null
            : () async {
                try {
                  await ref
                      .read(mealPlanControllerProvider.notifier)
                      .replaceMealById(widget.meal.id);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nabi đã đổi sang món phù hợp khác.'),
                    ),
                  );
                } catch (_) {
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'NaBi chưa thể đổi món lúc này. Bạn thử lại sau một chút nhé.',
                      ),
                    ),
                  );
                }
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final meal = widget.meal;
    final label = _mealLabel(meal.mealType, meal.mealOrder);
    final time = _timeLabel(meal);
    final accent = _accentColor(meal.mealType, meal.mealOrder);
    final icon = _mealIcon(meal.mealType);

    return Semantics(
      container: true,
      label: '$label, ${meal.mealName}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _showMealDetails,
        child: AnimatedScale(
          duration: AppDuration.fast,
          scale: _isPressed ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: AppDuration.fast,
            decoration: AppDecoration.card(
              color: AppColors.surface,
              radius: ui.radiusXl,
              shadows: _isPressed ? AppShadows.sm : AppShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ui.radiusXl),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left accent bar ─────────────────────────────
                    Container(
                      width: ui.accentBarWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accent, accent.withValues(alpha: 0.6)],
                        ),
                      ),
                    ),

                    // ── Card content ────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(ui.cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon badge
                                Container(
                                  padding: EdgeInsets.all(ui.smallPadding),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      ui.radiusMd,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: accent,
                                    size: ui.mealIconSize,
                                  ),
                                ),
                                SizedBox(width: ui.cardGap),
                                // Title block
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          label.toUpperCase(),
                                          style: AppTextStyles.labelSmall.copyWith(
                                            fontSize: ui.chipDayFontSize,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: ui.xsGap),
                                      Text(
                                        meal.mealName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.heading3.copyWith(
                                          fontSize: ui.mealTitleFontSize,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: ui.cardGap),

                            // Meal metadata. Keep it compact and wrap-safe.
                            Wrap(
                              spacing: ui.cardGap,
                              runSpacing: ui.smallGap,
                              children: [
                                _InlineTag(
                                  icon: Icons.person_outline_rounded,
                                  label: meal.servingSize.trim().isEmpty
                                      ? 'Khẩu phần 1 người'
                                      : meal.servingSize,
                                  color: AppColors.secondary,
                                ),
                                _InlineTag(
                                  icon: Icons.schedule_rounded,
                                  label: time,
                                  color: AppColors.textSecondary,
                                ),
                                _InlineTag(
                                  icon: Icons.local_fire_department_rounded,
                                  label: '${meal.calories} kcal',
                                  color: AppColors.warning,
                                ),
                                _InlineTag(
                                  icon: Icons.water_drop_rounded,
                                  label: '${meal.waterMl} ml',
                                  color: AppColors.info,
                                ),
                              ],
                            ),

                            SizedBox(height: ui.cardGap),

                            // Description
                            Text(
                              meal.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: ui.mealDescriptionFontSize,
                                height: 1.55,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            SizedBox(height: ui.cardGap),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meal.hasRecipeDetails
                                        ? 'Chạm để xem nguyên liệu và cách chế biến'
                                        : 'Chạm để xem thông tin chi tiết',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),

                            SizedBox(height: ui.cardGap),

                            // Badges
                            Wrap(
                              spacing: ui.smallGap,
                              runSpacing: ui.smallGap,
                              children: [
                                _MealStatusBadge(
                                  ui: ui,
                                  icon: meal.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  label: meal.isCompleted
                                      ? 'Đã hoàn thành'
                                      : 'Chờ thực hiện',
                                  backgroundColor: meal.isCompleted
                                      ? AppColors.successSoft
                                      : AppColors.warningSoft,
                                  textColor: meal.isCompleted
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                _MealStatusBadge(
                                  ui: ui,
                                  icon: meal.aiGenerated
                                      ? Icons.auto_awesome_rounded
                                      : Icons.edit_rounded,
                                  label: meal.aiGenerated
                                      ? 'Nabi tạo'
                                      : 'Thủ công',
                                  backgroundColor: AppColors.primarySoft,
                                  textColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE TAG  (time / calories / water — replaces MealTimeHighlight banner)
// ─────────────────────────────────────────────────────────────────────────────


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
    final steps = meal.cookingSteps.isNotEmpty
        ? meal.cookingSteps
        : _RecipeInstructionParser.parse(meal.cookingInstructions);

    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
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
                color: AppColors.border,
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
                            Text(meal.mealName, style: AppTextStyles.heading2),
                            if (meal.topicName.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                meal.topicName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _DetailPill('${meal.calories} kcal'),
                      if (meal.servingSize.trim().isNotEmpty)
                        _DetailPill(meal.servingSize),
                      if (meal.startTime.trim().isNotEmpty)
                        _DetailPill(meal.startTime),
                    ],
                  ),
                  if (meal.description.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Text(meal.description, style: AppTextStyles.bodyLarge),
                  ],
                  if (meal.ingredients.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.shopping_basket_rounded,
                      title: 'Nguyên liệu',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...meal.ingredients.map(
                      (ingredient) => _BulletLine(text: ingredient),
                    ),
                  ],
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.soup_kitchen_rounded,
                      title: 'Cách chế biến',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var index = 0; index < steps.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RecipeStep(
                          number: index + 1,
                          text: steps[index],
                        ),
                      ),
                  ],
                  if (meal.benefits.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const _DetailHeading(
                      icon: Icons.spa_rounded,
                      title: 'Công dụng theo tài liệu tham khảo',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(meal.benefits, style: AppTextStyles.bodyMedium),
                  ],
                  if (meal.provenanceSource.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        'Nguồn tham khảo: ${meal.provenanceSource}. Nội dung công dụng chỉ mang tính tham khảo, không thay thế tư vấn y tế.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Icon(Icons.swap_horiz_rounded),
                      label: Text(
                        _replacing ? 'Nabi đang chọn món...' : 'Đổi món khác',
                      ),
                    )
                  else
                    const Text(
                      'Bữa đã hoàn thành nên không thể đổi món.',
                      textAlign: TextAlign.center,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi sang món khác?'),
        content: const Text(
          'NaBi sẽ chọn một món khác phù hợp với hồ sơ dinh dưỡng của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ món này'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đổi món'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _replacing = true);
    try {
      await callback();
    } finally {
      if (mounted) setState(() => _replacing = false);
    }
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
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
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
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: AppTextStyles.heading4)),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _RecipeStep extends StatelessWidget {
  final int number;
  final String text;

  const _RecipeStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.48,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class _RecipeInstructionParser {
  static List<String> parse(String value) {
    final normalized = value
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
    if (normalized.isEmpty) return const [];

    final lines = normalized
        .split('\n')
        .expand((line) => line.split(RegExp(r'\s*[;•]\s*')))
        .map(_removeStepPrefix)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return lines.isEmpty ? [normalized] : lines;
  }

  static String _removeStepPrefix(String value) {
    return value
        .trim()
        .replaceFirst(RegExp(r'^(?:bước\s*)?\d+[\.)\-:]?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^[-–—]\s*'), '')
        .trim();
  }
}

class _InlineTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InlineTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE  (with icon)
// ─────────────────────────────────────────────────────────────────────────────

class _MealStatusBadge extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final IconData? icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _MealStatusBadge({
    required this.ui,
    this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ui.cardPadding * 0.75,
        vertical: ui.smallPadding * 0.6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ui.circularRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: textColor,
              fontSize: ui.badgeFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _MealEmptyView extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final String title;
  final String subtitle;

  const _MealEmptyView({
    required this.ui,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ui.pagePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ui.emptyIconPadding),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: ui.emptyIconSize,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: ui.sectionSpacing),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3.copyWith(
                fontSize: ui.emptyTitleFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: ui.smallGap),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: ui.emptySubtitleFontSize,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING VIEW  (shimmer-style skeleton)
// ─────────────────────────────────────────────────────────────────────────────

class _MealLoadingView extends StatefulWidget {
  final _MealPlanResponsiveUi ui;
  const _MealLoadingView({required this.ui});

  @override
  State<_MealLoadingView> createState() => _MealLoadingViewState();
}

class _MealLoadingViewState extends State<_MealLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.4 + _anim.value * 0.35;
        return ListView.separated(
          padding: EdgeInsets.all(ui.pagePadding),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(height: ui.cardGap),
          itemBuilder: (_, __) => _SkeletonCard(ui: ui, opacity: opacity),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final double opacity;

  const _SkeletonCard({required this.ui, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final base = AppColors.textHint.withValues(alpha: opacity);
    return Container(
      decoration: AppDecoration.card(
        color: AppColors.surface,
        radius: ui.radiusXl,
        shadows: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ui.radiusXl),
        child: Row(
          children: [
            Container(
              width: ui.accentBarWidth,
              height: ui.loadingCardHeight,
              color: base,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ui.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(ui.radiusMd),
                          ),
                        ),
                        SizedBox(width: ui.cardGap),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerBar(width: 60, height: 12, color: base),
                            SizedBox(height: ui.xsGap),
                            _ShimmerBar(width: 160, height: 18, color: base),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: ui.cardGap),
                    _ShimmerBar(width: 200, height: 12, color: base),
                    SizedBox(height: ui.cardGap),
                    _ShimmerBar(
                      width: double.infinity,
                      height: 14,
                      color: base,
                    ),
                    SizedBox(height: ui.xsGap),
                    _ShimmerBar(
                      width: double.infinity * 0.8,
                      height: 14,
                      color: base,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width, height;
  final Color color;

  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.xs),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _MealErrorView extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final String error;
  final VoidCallback onRetry;

  const _MealErrorView({
    required this.ui,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ui.pagePadding),
        child: Container(
          padding: EdgeInsets.all(ui.cardPadding),
          decoration: AppDecoration.card(
            color: AppColors.surface,
            radius: ui.radiusXl,
            shadows: AppShadows.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(ui.smallPadding),
                decoration: const BoxDecoration(
                  color: AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: ui.errorIconSize,
                ),
              ),
              SizedBox(height: ui.cardGap),
              Text(
                'Nabi chưa mở được thực đơn',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: ui.emptyTitleFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: ui.smallGap),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: ui.bodyFontSize,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: ui.cardGap),
              SizedBox(
                width: double.infinity,
                height: ui.primaryButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'Thử lại',
                    style: AppTextStyles.button.copyWith(
                      fontSize: ui.buttonFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE UI HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _MealPlanResponsiveUi {
  final double width;
  const _MealPlanResponsiveUi._(this.width);

  factory _MealPlanResponsiveUi.of(BuildContext context) =>
      _MealPlanResponsiveUi._(MediaQuery.sizeOf(context).width);

  bool get isCompact => width < 360;
  bool get isTablet => width >= 600;
  bool get isLarge => width >= 900;

  double get contentMaxWidth =>
      isLarge ? 920 : (isTablet ? 760 : double.infinity);

  // ── Spacing ──────────────────────────────────────────────────────────────
  double get pagePadding => isCompact ? 10 : (isTablet ? 20 : 14);
  double get cardPadding => isCompact ? 10 : (isTablet ? 16 : 12);
  double get smallPadding => isCompact ? 6 : 8;
  double get smallGap => isCompact ? 6 : 8;
  double get xsGap => 4.0;
  double get tinyGap => 2.0;
  double get cardGap => isCompact ? 8 : 10;
  double get sectionSpacing => isCompact ? 10 : 14;

  // ── Radius ───────────────────────────────────────────────────────────────
  double get radiusMd => isCompact ? 8 : 10;
  double get radiusLg => isCompact ? 12 : 14;
  double get radiusXl => isCompact ? 14 : 16;
  double get circularRadius => 999;

  // ── Header ───────────────────────────────────────────────────────────────
  double get headerTopPadding => isCompact ? 8 : 10;
  double get headerBottomPadding => isCompact ? 12 : 14;
  double get headerDecorSize => isCompact ? 120 : 150;
  double get headerDateFontSize => isCompact ? 10 : 11;
  double get headerSubtitleFontSize => isCompact ? 12 : 13;

  // ── Typography ───────────────────────────────────────────────────────────
  double get titleFontSize => isCompact ? 24 : (isTablet ? 30 : 27);
  double get summaryTitleFontSize => isCompact ? 18 : 20;
  double get sectionTitleFontSize => isCompact ? 16 : 17;
  double get bodyFontSize => isCompact ? 14 : 15;
  double get bodySmallFontSize => isCompact ? 12 : 13;
  double get mealTitleFontSize => isCompact ? 16 : 18;
  double get mealLabelFontSize => isCompact ? 14 : 15;
  double get mealDescriptionFontSize => isCompact ? 13 : 14;
  double get badgeTitleFontSize => isCompact ? 11 : 12;
  double get badgeFontSize => isCompact ? 12 : 13;
  double get nutritionValueFontSize => isCompact ? 15 : 16;
  double get emptyTitleFontSize => isCompact ? 18 : 20;
  double get emptySubtitleFontSize => isCompact ? 13 : 14;
  double get buttonFontSize => isCompact ? 14 : 15;

  // ── Icons ────────────────────────────────────────────────────────────────
  double get actionButtonSize => 44;
  double get actionIconSize => isCompact ? 20 : 22;
  double get filterIconSize => isCompact ? 15 : 16;
  double get mealIconSize => isCompact ? 20 : 22;
  double get errorIconSize => isCompact ? 28 : 32;
  double get emptyIconSize => isCompact ? 42 : 48;
  double get emptyIconPadding => isCompact ? 14 : 16;

  // ── Date chips ───────────────────────────────────────────────────────────
  double get chipHeight => isCompact ? 58 : 64;
  double get chipWidth => isCompact ? 48 : 54;
  double get chipGap => isCompact ? 6 : 8;
  double get chipSectionVertical => isCompact ? 8 : 10;
  double get chipDayFontSize => isCompact ? 10 : 11;
  double get chipDateFontSize => isCompact ? 15 : 17;

  // ── Card details ─────────────────────────────────────────────────────────
  double get accentBarWidth => 4;
  double get loadingCardHeight => isCompact ? 132 : 148;
  double get primaryButtonHeight => 44;

  // ── Nutrition ────────────────────────────────────────────────────────────
  int get nutritionCrossAxisCount => isTablet ? 4 : 2;
  double get nutritionAspectRatio => isTablet ? 2.2 : (isCompact ? 1.75 : 1.9);
}
