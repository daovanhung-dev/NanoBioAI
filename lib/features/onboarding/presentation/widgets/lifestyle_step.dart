import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class LifestyleStep extends ConsumerStatefulWidget {
  const LifestyleStep({super.key});

  @override
  ConsumerState<LifestyleStep> createState() => _LifestyleStepState();
}

class _LifestyleStepState extends ConsumerState<LifestyleStep> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final selectedHabits = state.habits.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _LifestyleCalmBackground()),
          ),
          Positioned(
            top: -92,
            right: -96,
            child: IgnorePointer(
              child: _SoftOrb(size: 260, gradient: AppGradients.ai),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -110,
            child: IgnorePointer(
              child: _SoftOrb(size: 300, gradient: AppGradients.health),
            ),
          ),
          OnboardingStepShell(
            stepIndex: 4,
            title: '',
            subtitle: '',
            isScrollable: false,
            onBack: controller.previousStep,
            onNext: controller.nextStep,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final maxContentWidth = screenWidth >= 900
                    ? 860.0
                    : double.infinity;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    _pagePadding(screenWidth),
                    AppSpacing.sm,
                    _pagePadding(screenWidth),
                    AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NamiHeroCard(selectedHabits: selectedHabits),
                          const SizedBox(
                            height: AppSpacing.sectionSpacingLarge,
                          ),
                          _GentleReminderCard(selectedHabits: selectedHabits),
                          const SizedBox(
                            height: AppSpacing.sectionSpacingLarge,
                          ),
                          const _SectionIntro(
                            icon: AppIcons.meditation,
                            title: 'Một ngày thường của bạn diễn ra thế nào?',
                            subtitle:
                                'Bạn chọn những điều gần đúng với mình nhé. Không cần hoàn hảo, Nami chỉ muốn hiểu nhịp sống thật của bạn hơn một chút.',
                          ),
                          const SizedBox(height: AppSpacing.sectionSpacing),
                          _HabitsChoiceGrid(
                            habits: state.habits,
                            onToggle: controller.toggleHabit,
                          ),
                          const SizedBox(
                            height: AppSpacing.sectionSpacingLarge,
                          ),
                          const _SectionIntro(
                            icon: AppIcons.sleep,
                            title:
                                'Nami muốn lắng nghe cơ thể bạn thêm một chút',
                            subtitle:
                                'Giấc ngủ, vận động và nước uống là những tín hiệu nhỏ nhưng rất quan trọng để Nami chăm sóc bạn dịu dàng hơn.',
                          ),
                          const SizedBox(height: AppSpacing.sectionSpacing),
                          _ResponsivePickerPanel(
                            children: [
                              _ChoicePickerField(
                                icon: AppIcons.sleep,
                                title: 'Giấc ngủ gần đây',
                                subtitle: 'Chọn mô tả giống bạn nhất',
                                emptyText: 'Bạn ngủ thế nào dạo này?',
                                value: state.sleepQuality,
                                options: OnboardingCatalog.sleepQualities,
                                gradient: AppGradients.sleep,
                                onChanged: controller.updateSleepQuality,
                              ),
                              _ChoicePickerField(
                                icon: AppIcons.fitness,
                                title: 'Mức độ vận động',
                                subtitle: 'Mình sẽ điều chỉnh lời nhắc phù hợp',
                                emptyText: 'Bạn vận động ở mức nào?',
                                value: state.activityLevel,
                                options: OnboardingCatalog.activityLevels,
                                gradient: AppGradients.health,
                                onChanged: controller.updateActivityLevel,
                              ),
                              _ChoicePickerField(
                                icon: AppIcons.water,
                                title: 'Nước uống mỗi ngày',
                                subtitle: 'Chỉ cần ước lượng gần đúng là được',
                                emptyText: 'Bạn thường uống bao nhiêu nước?',
                                value: state.waterPerDay,
                                options: OnboardingCatalog.waterIntakeOptions,
                                gradient: AppGradients.info,
                                onChanged: controller.updateWaterPerDay,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: AppSpacing.sectionSpacingLarge,
                          ),
                          _NamiMemoryCard(
                            selectedHabits: selectedHabits,
                            sleepQuality: state.sleepQuality,
                            activityLevel: state.activityLevel,
                            waterPerDay: state.waterPerDay,
                          ),
                        ],
                      ),
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

  double _pagePadding(double width) {
    if (width >= 900) return AppSpacing.pagePaddingLarge;
    return AppSpacing.pagePadding;
  }
}

class _NamiHeroCard extends StatelessWidget {
  final int selectedHabits;

  const _NamiHeroCard({required this.selectedHabits});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: AppSpacing.avatarSizeLarge,
                    height: AppSpacing.avatarSizeLarge,
                    decoration: AppDecoration.glass(
                      radius: AppRadius.circular,
                      opacity: 0.16,
                    ),
                    child: const Icon(
                      AppIcons.aiHealth,
                      color: AppColors.textWhite,
                      size: 30,
                    ),
                  ),
                  _HeroBadge(
                    icon: AppIcons.favorite,
                    label: 'Nami đang lắng nghe',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Nami muốn hiểu\nnhịp sống của bạn',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textWhite,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mỗi người có một cách sống riêng. Bạn cứ chia sẻ nhẹ nhàng, Nami sẽ ghi nhớ để đồng hành cùng bạn theo cách vừa đủ và thoải mái nhất.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite.withOpacity(0.88),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              isCompact
                  ? Column(
                      children: [
                        _HeroInfoTile(
                          icon: AppIcons.checkIn,
                          title: 'Đã chọn',
                          value: _habitText(selectedHabits),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _HeroInfoTile(
                          icon: AppIcons.shield,
                          title: 'Cách Nami dùng dữ liệu',
                          value: 'Chỉ để cá nhân hóa chăm sóc',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _HeroInfoTile(
                            icon: AppIcons.checkIn,
                            title: 'Đã chọn',
                            value: _habitText(selectedHabits),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: _HeroInfoTile(
                            icon: AppIcons.shield,
                            title: 'Cách Nami dùng dữ liệu',
                            value: 'Chỉ để cá nhân hóa chăm sóc',
                          ),
                        ),
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }

  static String _habitText(int count) {
    if (count == 0) return 'Chưa có thói quen nào';
    return '$count thói quen';
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecoration.glass(
        radius: AppRadius.circular,
        opacity: 0.14,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textWhite, size: 18),
          const SizedBox(width: AppSpacing.iconTextSpacingLarge),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HeroInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.touchTargetMin),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.glass(opacity: 0.13, radius: AppRadius.xl),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconButtonSize,
            height: AppSpacing.iconButtonSize,
            decoration: AppDecoration.circle(
              color: AppColors.textWhite.withOpacity(0.14),
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textWhite,
                    height: 1.35,
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

class _GentleReminderCard extends StatelessWidget {
  final int selectedHabits;

  const _GentleReminderCard({required this.selectedHabits});

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedHabits > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.premiumCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.avatarSizeLarge,
            height: AppSpacing.avatarSizeLarge,
            decoration: AppDecoration.gradient(
              colors: const [AppColors.primary, AppColors.secondary],
              radius: AppRadius.xl,
              shadows: AppShadows.primary,
            ),
            child: Icon(
              hasSelection ? AppIcons.success : AppIcons.mood,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection
                      ? 'Nami đã ghi nhớ những thói quen đầu tiên'
                      : 'Bạn có thể bắt đầu từ vài điều đơn giản',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasSelection
                      ? 'Những lựa chọn này giúp Nami hiểu bối cảnh sinh hoạt của bạn, từ đó gợi ý bữa ăn, giấc ngủ và nhắc nhở hằng ngày dịu dàng hơn.'
                      : 'Chỉ cần chọn những điều đang đúng với hiện tại. Khi cuộc sống thay đổi, mình có thể điều chỉnh dần cùng nhau.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.65,
                    color: AppColors.textSecondary,
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

class _SectionIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.avatarSizeMedium,
          height: AppSpacing.avatarSizeMedium,
          decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
          child: Icon(icon, color: AppColors.textWhite, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitsChoiceGrid extends StatelessWidget {
  final List<dynamic> habits;
  final ValueChanged<String> onToggle;

  const _HabitsChoiceGrid({required this.habits, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        if (availableWidth <= 0) return const SizedBox.shrink();

        final columns = availableWidth >= 760
            ? 3
            : availableWidth >= 480
            ? 2
            : 1;

        final rawItemWidth =
            (availableWidth - ((columns - 1) * AppSpacing.md)) / columns;

        final itemWidth = columns == 1
            ? availableWidth
            : rawItemWidth.clamp(150.0, 280.0).toDouble();

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: OnboardingCatalog.habits.map<Widget>((item) {
            final selected = habits.contains(item.code);

            return SizedBox(
              width: itemWidth,
              child: _HabitChoiceCard(
                emoji: item.emoji,
                label: item.label,
                selected: selected,
                onTap: () => onToggle(item.code),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HabitChoiceCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HabitChoiceCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppDuration.tap,
      curve: AppAnimations.smoothCurve,
      scale: selected ? 1.0 : 0.985,
      child: AnimatedContainer(
        duration: AppDuration.card,
        curve: AppAnimations.smoothCurve,
        decoration: AppDecoration.base(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
          shadows: selected ? AppShadows.primary : AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: AppDecoration.circle(
                      color: selected
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.cardAlt,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: AppTextStyles.heading5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    width: 24,
                    height: 24,
                    decoration: AppDecoration.circle(
                      color: selected ? AppColors.primary : AppColors.cardAlt,
                    ),
                    child: Icon(
                      selected ? AppIcons.success : AppIcons.add,
                      color: selected
                          ? AppColors.textWhite
                          : AppColors.textHint,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsivePickerPanel extends StatelessWidget {
  final List<Widget> children;

  const _ResponsivePickerPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(
        opacity: 0.86,
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
        borderColor: AppColors.border.withOpacity(0.72),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth >= 720;

          if (!useTwoColumns) {
            return Column(
              children: _withSpacing(children, AppSpacing.formFieldSpacing),
            );
          }

          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: children.map((child) {
              final width = ((constraints.maxWidth - AppSpacing.md) / 2)
                  .clamp(260.0, 420.0)
                  .toDouble();

              return SizedBox(width: width, child: child);
            }).toList(),
          );
        },
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets, double spacing) {
    final spaced = <Widget>[];

    for (var i = 0; i < widgets.length; i++) {
      spaced.add(widgets[i]);
      if (i != widgets.length - 1) {
        spaced.add(SizedBox(height: spacing));
      }
    }

    return spaced;
  }
}

class _ChoicePickerField extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String emptyText;
  final String? value;
  final List<String> options;
  final Gradient gradient;
  final ValueChanged<String> onChanged;

  const _ChoicePickerField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.value,
    required this.options,
    required this.gradient,
    required this.onChanged,
  });

  bool get _hasValue => value != null && value!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.card,
      curve: AppAnimations.smoothCurve,
      decoration: AppDecoration.base(
        color: _hasValue
            ? AppColors.primarySoft.withOpacity(0.48)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: _hasValue ? AppColors.primaryLight : AppColors.border,
          width: _hasValue ? 1.4 : 1,
        ),
        shadows: _hasValue ? AppShadows.primary : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppDecoration.base(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    shadows: AppShadows.md,
                  ),
                  child: Icon(icon, color: AppColors.textWhite, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_hasValue)
                            _TinyStatusPill(
                              icon: AppIcons.success,
                              label: 'Đã chọn',
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: AppDecoration.input(
                          color: _hasValue
                              ? AppColors.surface
                              : AppColors.inputBackground,
                          radius: AppRadius.inputLarge,
                          borderColor: _hasValue
                              ? AppColors.primaryLight
                              : AppColors.border,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _hasValue ? value!.trim() : emptyText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _hasValue
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                  fontWeight: _hasValue
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              AppIcons.expand,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PickerBottomSheet(
          icon: icon,
          title: title,
          subtitle: subtitle,
          selectedValue: value,
          options: options,
        );
      },
    );

    if (selected != null && selected.trim().isNotEmpty) {
      onChanged(selected.trim());
    }
  }
}

class _PickerBottomSheet extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? selectedValue;
  final List<String> options;

  const _PickerBottomSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedValue,
    required this.options,
  });

  @override
  State<_PickerBottomSheet> createState() => _PickerBottomSheetState();
}

class _PickerBottomSheetState extends State<_PickerBottomSheet> {
  late final TextEditingController _customController;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();

    final selectedValue = widget.selectedValue?.trim() ?? '';
    final isCustomValue =
        selectedValue.isNotEmpty && !widget.options.contains(selectedValue);

    _showCustomInput = isCustomValue;
    _customController = TextEditingController(
      text: isCustomValue ? selectedValue : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: sheetMaxHeight),
        decoration: AppDecoration.bottomSheet(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sheetHandleSpacing),
            Container(
              width: 44,
              height: 5,
              decoration: AppDecoration.container(
                color: AppColors.border,
                radius: AppRadius.sheetHandle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.bottomSheetPadding,
                AppSpacing.lg,
                AppSpacing.bottomSheetPadding,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppSpacing.avatarSizeMedium,
                    height: AppSpacing.avatarSizeMedium,
                    decoration: AppDecoration.primaryGradient(
                      radius: AppRadius.lg,
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.textWhite,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.bottomSheetPadding,
                  AppSpacing.xs,
                  AppSpacing.bottomSheetPadding,
                  AppSpacing.md,
                ),
                children: [
                  ...widget.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PickerOptionTile(
                        label: option,
                        selected: option == widget.selectedValue,
                        onTap: () => Navigator.of(context).pop(option),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CustomOptionEntry(
                    selected: _showCustomInput,
                    onTap: () {
                      setState(() {
                        _showCustomInput = true;
                      });
                    },
                  ),
                  if (_showCustomInput) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _customController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      minLines: 1,
                      maxLines: 3,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      onSubmitted: _submitCustomValue,
                      decoration: InputDecoration(
                        hintText: 'Bạn có thể ghi theo cách của mình...',
                        prefixIcon: const Icon(AppIcons.edit),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.inputLarge,
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.inputLarge,
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.inputLarge,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _submitCustomValue(_customController.text),
                        icon: const Icon(AppIcons.success),
                        label: const Text('Nami ghi nhớ điều này'),
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

  void _submitCustomValue(String rawValue) {
    final value = rawValue.trim();

    if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }
}

class _PickerOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.card,
      curve: AppAnimations.smoothCurve,
      decoration: AppDecoration.base(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
        shadows: selected ? AppShadows.primary : AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? AppIcons.success : AppIcons.forward,
                  color: selected ? AppColors.primary : AppColors.textHint,
                  size: selected ? 22 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomOptionEntry extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CustomOptionEntry({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.card,
      curve: AppAnimations.smoothCurve,
      decoration: AppDecoration.outlined(
        color: selected ? AppColors.infoSoft : AppColors.cardAlt,
        borderColor: selected ? AppColors.info : AppColors.border,
        radius: AppRadius.lg,
        borderWidth: selected ? 1.4 : 1,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: AppSpacing.iconButtonSize,
                  height: AppSpacing.iconButtonSize,
                  decoration: AppDecoration.circle(
                    color: AppColors.info.withOpacity(0.12),
                  ),
                  child: const Icon(
                    AppIcons.edit,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khác / Tự nhập',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Bạn có thể viết đúng theo tình trạng của mình.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? AppIcons.success : AppIcons.add,
                  color: selected ? AppColors.info : AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NamiMemoryCard extends StatelessWidget {
  final int selectedHabits;
  final String? sleepQuality;
  final String? activityLevel;
  final String? waterPerDay;

  const _NamiMemoryCard({
    required this.selectedHabits,
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyInfo =
        selectedHabits > 0 ||
        _hasText(sleepQuality) ||
        _hasText(activityLevel) ||
        _hasText(waterPerDay);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.base(
        gradient: AppGradients.futuristic,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        shadows: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.avatarSizeLarge,
                height: AppSpacing.avatarSizeLarge,
                decoration: AppDecoration.glass(
                  opacity: 0.14,
                  radius: AppRadius.xl,
                ),
                child: const Icon(
                  AppIcons.aiInsight,
                  color: AppColors.textWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điều Nami đang ghi nhớ',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasAnyInfo
                          ? 'Những thông tin này sẽ giúp Nami chăm sóc bạn gần gũi và đúng nhịp hơn.'
                          : 'Bạn chưa cần điền hết ngay. Mình có thể bắt đầu chậm rãi từ những điều bạn thấy thoải mái.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withOpacity(0.84),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _MemoryTile(
            icon: AppIcons.meditation,
            title: 'Thói quen sinh hoạt',
            value: selectedHabits == 0
                ? 'Bạn chưa chọn thói quen nào'
                : '$selectedHabits thói quen đã được chia sẻ',
          ),
          const SizedBox(height: AppSpacing.md),
          _MemoryTile(
            icon: AppIcons.sleep,
            title: 'Giấc ngủ',
            value: _valueOrWaiting(sleepQuality),
          ),
          const SizedBox(height: AppSpacing.md),
          _MemoryTile(
            icon: AppIcons.fitness,
            title: 'Vận động',
            value: _valueOrWaiting(activityLevel),
          ),
          const SizedBox(height: AppSpacing.md),
          _MemoryTile(
            icon: AppIcons.water,
            title: 'Nước uống',
            value: _valueOrWaiting(waterPerDay),
          ),
        ],
      ),
    );
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String _valueOrWaiting(String? value) {
    if (_hasText(value)) return value!.trim();
    return 'Nami sẽ chờ bạn chia sẻ thêm';
  }
}

class _MemoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MemoryTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(opacity: 0.11, radius: AppRadius.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.iconButtonSize,
            height: AppSpacing.iconButtonSize,
            decoration: AppDecoration.circle(
              color: AppColors.textWhite.withOpacity(0.12),
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textWhite,
                    height: 1.4,
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

class _TinyStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyStatusPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecoration.container(
        color: AppColors.successSoft,
        radius: AppRadius.circular,
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.success, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Gradient gradient;

  const _SoftOrb({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.13,
      child: Container(
        width: size,
        height: size,
        decoration: AppDecoration.circle(gradient: gradient),
      ),
    );
  }
}

class _LifestyleCalmBackground extends StatelessWidget {
  const _LifestyleCalmBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LifestyleCalmBackgroundPainter());
  }
}

class _LifestyleCalmBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft,
          AppColors.surface,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += AppSpacing.xl) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y < size.height; y += AppSpacing.xl) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LifestyleCalmBackgroundPainter oldDelegate) {
    return false;
  }
}
