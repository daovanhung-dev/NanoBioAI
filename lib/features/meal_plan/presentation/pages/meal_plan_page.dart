import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/features/meal_plan/presentation/controllers/meal_plan_controller.dart';

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

    return Scaffold(
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
              loading: () => MealLoadingView(ui: ui),
              error: (error, _) => MealErrorView(
                ui: ui,
                error: error.toString(),
                onRetry: () => ref
                    .read(mealPlanControllerProvider.notifier)
                    .refreshMealPlans(),
              ),
              data: (meals) {
                if (meals.isEmpty) {
                  return MealEmptyView(
                    ui: ui,
                    title: 'Mình chưa chuẩn bị xong thực đơn',
                    subtitle:
                        'Bạn quay lại sau một chút nhé, mình đang chọn những món phù hợp.',
                  );
                }

                final availableDates = _extractAvailableDates(meals);
                if (availableDates.isEmpty) {
                  return MealEmptyView(
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
                            child: MealEmptyView(
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
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.82)],
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
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            Positioned(
              bottom: ui.pagePadding * 0.5,
              left: -ui.pagePadding,
              child: _DecorativeCircle(
                size: ui.headerDecorSize * 0.55,
                color: Colors.white.withOpacity(0.05),
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
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _todayLabel(),
                                style: TextStyle(
                                  fontSize: ui.headerDateFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
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
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: ui.xsGap),
                        Text(
                          'Theo dõi dinh dưỡng theo từng ngày',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: ui.headerSubtitleFontSize,
                            color: Colors.white.withOpacity(0.72),
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
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(ui.radiusLg),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
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
                  color: AppColors.primary.withOpacity(0.4),
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
              style: TextStyle(
                fontSize: ui.chipDayFontSize,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: ui.tinyGap),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: ui.chipDateFontSize,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isToday) ...[
              SizedBox(height: ui.tinyGap),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : AppColors.primary,
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
      child: MealPlanCard(ui: ui, meal: meal),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEAL PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class MealPlanCard extends StatefulWidget {
  final _MealPlanResponsiveUi ui;
  final MealPlanEntity meal;

  const MealPlanCard({super.key, required this.ui, required this.meal});

  @override
  State<MealPlanCard> createState() => _MealPlanCardState();
}

class _MealPlanCardState extends State<MealPlanCard> {
  bool _isPressed = false;

  static String _mealLabel(String type, int order) {
    switch (type.toLowerCase().trim()) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
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

  static String _timeLabel(String type, int order) {
    switch (type.toLowerCase().trim()) {
      case 'breakfast':
        return '06:30 – 08:00';
      case 'lunch':
        return '11:30 – 13:00';
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
        return const Color(0xFFF59E0B); // amber
      case 'lunch':
        return const Color(0xFF10B981); // emerald
      case 'dinner':
        return const Color(0xFF6366F1); // indigo
      case 'snack':
        return const Color(0xFFEC4899); // pink
      default:
        switch (order) {
          case 1:
            return const Color(0xFFF59E0B);
          case 2:
            return const Color(0xFF10B981);
          case 3:
            return const Color(0xFF6366F1);
          default:
            return const Color(0xFFEC4899);
        }
    }
  }

  static IconData _mealIcon(String type) {
    switch (type.toLowerCase().trim()) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final meal = widget.meal;
    final label = _mealLabel(meal.mealType, meal.mealOrder);
    final time = _timeLabel(meal.mealType, meal.mealOrder);
    final accent = _accentColor(meal.mealType, meal.mealOrder);
    final icon = _mealIcon(meal.mealType);

    return Semantics(
      container: true,
      label: '$label, ${meal.mealName}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
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
                          colors: [accent, accent.withOpacity(0.6)],
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
                                    color: accent.withOpacity(0.12),
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
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          label.toUpperCase(),
                                          style: TextStyle(
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

                            // Time & calories inline row
                            Row(
                              children: [
                                _InlineTag(
                                  icon: Icons.schedule_rounded,
                                  label: time,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: ui.cardGap),
                                _InlineTag(
                                  icon: Icons.local_fire_department_rounded,
                                  label: '${meal.calories} kcal',
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: ui.cardGap),
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
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: ui.mealDescriptionFontSize,
                                height: 1.55,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            SizedBox(height: ui.cardGap),

                            // Divider
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.textHint.withOpacity(0.12),
                            ),

                            SizedBox(height: ui.cardGap),

                            // Nutrition row
                            _NutritionRow(ui: ui, meal: meal),

                            SizedBox(height: ui.cardGap),

                            // Badges
                            Wrap(
                              spacing: ui.smallGap,
                              runSpacing: ui.smallGap,
                              children: [
                                MealStatusBadge(
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
                                MealStatusBadge(
                                  ui: ui,
                                  icon: meal.aiGenerated
                                      ? Icons.auto_awesome_rounded
                                      : Icons.edit_rounded,
                                  label: meal.aiGenerated
                                      ? 'AI tạo'
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// NUTRITION ROW  (horizontal compact — replaces 2-column grid)
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionRow extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final MealPlanEntity meal;

  const _NutritionRow({required this.ui, required this.meal});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NutrientDot(
        label: 'Đạm',
        value: '${meal.protein}g',
        color: AppColors.success,
      ),
      _NutrientDot(
        label: 'Tinh bột',
        value: '${meal.carbs}g',
        color: AppColors.primary,
      ),
      _NutrientDot(
        label: 'Chất béo',
        value: '${meal.fat}g',
        color: AppColors.warning,
      ),
      _NutrientDot(
        label: 'Chất xơ',
        value: '${meal.fiber}g',
        color: AppColors.info,
      ),
    ];

    return Row(
      children: items
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.value.value,
                    style: TextStyle(
                      fontSize: ui.nutritionValueFontSize,
                      fontWeight: FontWeight.w800,
                      color: e.value.color,
                    ),
                  ),
                  SizedBox(height: ui.tinyGap),
                  Text(
                    e.value.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: ui.bodySmallFontSize - 1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    height: 3,
                    margin: EdgeInsets.only(
                      right: e.key < items.length - 1 ? ui.smallGap : 0,
                    ),
                    decoration: BoxDecoration(
                      color: e.value.color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(ui.circularRadius),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: e.value.color,
                          borderRadius: BorderRadius.circular(
                            ui.circularRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NutrientDot {
  final String label, value;
  final Color color;
  const _NutrientDot({
    required this.label,
    required this.value,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE  (with icon)
// ─────────────────────────────────────────────────────────────────────────────

class MealStatusBadge extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final IconData? icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const MealStatusBadge({
    super.key,
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
            const SizedBox(width: 4),
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

class MealEmptyView extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final String title;
  final String subtitle;

  const MealEmptyView({
    super.key,
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

class MealLoadingView extends StatefulWidget {
  final _MealPlanResponsiveUi ui;
  const MealLoadingView({super.key, required this.ui});

  @override
  State<MealLoadingView> createState() => _MealLoadingViewState();
}

class _MealLoadingViewState extends State<MealLoadingView>
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
    final base = AppColors.textHint.withOpacity(opacity);
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
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────────────────────

class MealErrorView extends StatelessWidget {
  final _MealPlanResponsiveUi ui;
  final String error;
  final VoidCallback onRetry;

  const MealErrorView({
    super.key,
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
                'Đã xảy ra lỗi',
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
                    style: TextStyle(
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
  double get pagePadding => isCompact ? 12 : (isTablet ? 24 : 16);
  double get cardPadding => isCompact ? 14 : (isTablet ? 20 : 16);
  double get smallPadding => isCompact ? 8 : 10;
  double get smallGap => isCompact ? 8 : 10;
  double get xsGap => 4.0;
  double get tinyGap => 2.0;
  double get cardGap => isCompact ? 12 : 16;
  double get sectionSpacing => isCompact ? 12 : 16;

  // ── Radius ───────────────────────────────────────────────────────────────
  double get radiusMd => isCompact ? 10 : 12;
  double get radiusLg => isCompact ? 14 : 16;
  double get radiusXl => isCompact ? 18 : 22;
  double get circularRadius => 999;

  // ── Header ───────────────────────────────────────────────────────────────
  double get headerTopPadding => isCompact ? 12 : 16;
  double get headerBottomPadding => isCompact ? 18 : 22;
  double get headerDecorSize => isCompact ? 160 : 200;
  double get headerDateFontSize => isCompact ? 11 : 12;
  double get headerSubtitleFontSize => isCompact ? 13 : 14;

  // ── Typography ───────────────────────────────────────────────────────────
  double get titleFontSize => isCompact ? 28 : (isTablet ? 36 : 32);
  double get summaryTitleFontSize => isCompact ? 22 : 26;
  double get sectionTitleFontSize => isCompact ? 17 : 18;
  double get bodyFontSize => isCompact ? 15 : 16;
  double get bodySmallFontSize => isCompact ? 13 : 14;
  double get mealTitleFontSize => isCompact ? 18 : 20;
  double get mealLabelFontSize => isCompact ? 15 : 16;
  double get mealDescriptionFontSize => isCompact ? 14 : 15;
  double get badgeTitleFontSize => isCompact ? 11 : 12;
  double get badgeFontSize => isCompact ? 12 : 13;
  double get nutritionValueFontSize => isCompact ? 16 : 17;
  double get emptyTitleFontSize => isCompact ? 20 : 22;
  double get emptySubtitleFontSize => isCompact ? 14 : 15;
  double get buttonFontSize => isCompact ? 15 : 16;

  // ── Icons ────────────────────────────────────────────────────────────────
  double get actionButtonSize => isCompact ? 44 : 48;
  double get actionIconSize => isCompact ? 22 : 24;
  double get filterIconSize => isCompact ? 16 : 18;
  double get mealIconSize => isCompact ? 22 : 24;
  double get errorIconSize => isCompact ? 32 : 36;
  double get emptyIconSize => isCompact ? 50 : 56;
  double get emptyIconPadding => isCompact ? 18 : 22;

  // ── Date chips ───────────────────────────────────────────────────────────
  double get chipHeight => isCompact ? 68 : 76;
  double get chipWidth => isCompact ? 52 : 60;
  double get chipGap => isCompact ? 8 : 10;
  double get chipSectionVertical => isCompact ? 12 : 14;
  double get chipDayFontSize => isCompact ? 11 : 12;
  double get chipDateFontSize => isCompact ? 17 : 19;

  // ── Card details ─────────────────────────────────────────────────────────
  double get accentBarWidth => isCompact ? 4 : 5;
  double get loadingCardHeight => isCompact ? 160 : 180;
  double get primaryButtonHeight => isCompact ? 48 : 52;

  // ── Nutrition ────────────────────────────────────────────────────────────
  int get nutritionCrossAxisCount => isTablet ? 4 : 2;
  double get nutritionAspectRatio => isTablet ? 2.2 : (isCompact ? 1.75 : 1.9);
}
