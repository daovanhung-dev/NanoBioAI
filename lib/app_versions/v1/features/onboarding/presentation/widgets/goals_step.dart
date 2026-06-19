import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class GoalsStep extends ConsumerStatefulWidget {
  const GoalsStep({super.key});

  @override
  ConsumerState<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends ConsumerState<GoalsStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  String _activeCategoryId = _GoalCategoryCatalog.all.id;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final selectedCodes = _selectedCodesOf(state.goals);
    final selectedGoals = _GoalCatalog.items
        .where((goal) => selectedCodes.contains(goal.code))
        .toList(growable: false);

    final visibleGoals = _activeCategoryId == _GoalCategoryCatalog.all.id
        ? _GoalCatalog.items
        : _GoalCatalog.items
              .where((goal) => goal.categoryId == _activeCategoryId)
              .toList(growable: false);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (_, __) {
              return CustomPaint(
                painter: _GoalsBackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),
        Positioned(
          top: -90,
          right: -80,
          child: _FloatingGlow(
            controller: _floatingController,
            size: 250,
            gradient: AppGradients.ai,
            opacity: 0.055,
          ),
        ),
        Positioned(
          bottom: -130,
          left: -90,
          child: _FloatingGlow(
            controller: _floatingController,
            size: 310,
            gradient: AppGradients.health,
            opacity: 0.05,
          ),
        ),
        Positioned.fill(
          child: OnboardingStepShell(
            stepIndex: 2,
            title: '',
            subtitle: '',
            isScrollable: false,
            onBack: controller.previousStep,
            onNext: controller.nextStep,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final horizontalPadding = width < 380 ? 0.0 : AppSpacing.xs;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.xs,
                    horizontalPadding,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroSection(selectedGoals: selectedGoals),
                      const SizedBox(height: AppSpacing.lg),
                      _NamiReflectionCard(selectedGoals: selectedGoals),
                      const SizedBox(height: AppSpacing.xl),
                      const _HumanSectionHeader(
                        eyebrow: 'Mục tiêu sức khỏe',
                        title: 'Bạn muốn Nami ưu tiên chăm sóc điều gì?',
                        subtitle:
                            'Bạn có thể chọn nhiều mục tiêu. Không cần chọn thật hoàn hảo, Nami sẽ cùng bạn điều chỉnh dần theo cơ thể và nhịp sống của bạn.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _GoalCategorySelector(
                        activeCategoryId: _activeCategoryId,
                        selectedCodes: selectedCodes,
                        onChanged: (categoryId) {
                          if (!mounted) return;
                          setState(() => _activeCategoryId = categoryId);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GoalsWrap(
                        goals: visibleGoals,
                        selectedCodes: selectedCodes,
                        onToggle: controller.toggleGoal,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _HumanSectionHeader(
                        eyebrow: 'Chia sẻ thêm',
                        title: 'Có điều gì bạn muốn Nami hiểu kỹ hơn không?',
                        subtitle:
                            'Bạn cứ viết như đang kể với một người đồng hành. Ví dụ: “Mình hay mệt về chiều”, “mình muốn ngủ sớm hơn”, hoặc “mình cần ăn uống dễ duy trì”.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _OtherGoalCard(
                        initialValue: state.otherGoal,
                        onChanged: controller.updateOtherGoal,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _NamiPromiseCard(selectedCount: selectedGoals.length),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Set<String> _selectedCodesOf(dynamic rawGoals) {
    if (rawGoals is Iterable) {
      return rawGoals.map((goal) => goal.toString()).toSet();
    }

    return <String>{};
  }
}

class _HeroSection extends StatelessWidget {
  final List<_HealthGoal> selectedGoals;

  const _HeroSection({required this.selectedGoals});

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedGoals.length;
    final message = selectedCount == 0
        ? 'Nami sẽ lắng nghe điều bạn đang cần, rồi nhẹ nhàng gợi ý bữa ăn, thói quen và lời nhắc phù hợp hơn với bạn.'
        : 'Nami đã ghi nhận $selectedCount điều bạn quan tâm. Mình sẽ ưu tiên những mục tiêu này khi xây lộ trình chăm sóc cho bạn.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_adaptivePadding(context)),
      decoration: AppDecoration.primaryGradient(radius: AppRadius.xxxl),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -54,
            right: -38,
            child: IgnorePointer(
              child: Container(
                width: 156,
                height: 156,
                decoration: AppDecoration.circle(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -62,
            left: -46,
            child: IgnorePointer(
              child: Container(
                width: 130,
                height: 130,
                decoration: AppDecoration.circle(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: compact ? 58 : 68,
                        height: compact ? 58 : 68,
                        decoration: AppDecoration.glass(
                          opacity: 0.17,
                          radius: AppRadius.circular,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: compact ? 28 : 34,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: AppDecoration.glass(
                          opacity: 0.13,
                          radius: AppRadius.circular,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Nami đang lắng nghe',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Bạn muốn Nami\nchăm sóc điều gì trước?',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.93),
                  height: 1.65,
                ),
              ),
              if (selectedGoals.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _SelectedGoalPreview(goals: selectedGoals),
              ],
            ],
          ),
        ],
      ),
    );
  }

  double _adaptivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 380) return AppSpacing.lg;
    return AppSpacing.containerPaddingXl;
  }
}

class _SelectedGoalPreview extends StatelessWidget {
  final List<_HealthGoal> goals;

  const _SelectedGoalPreview({required this.goals});

  @override
  Widget build(BuildContext context) {
    final previewGoals = goals.take(4).toList(growable: false);
    final remaining = goals.length - previewGoals.length;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ...previewGoals.map(
          (goal) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: AppDecoration.glass(
              opacity: 0.15,
              radius: AppRadius.circular,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: AppDecoration.glass(
              opacity: 0.15,
              radius: AppRadius.circular,
            ),
            child: Text(
              '+$remaining mục tiêu nữa',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _NamiReflectionCard extends StatelessWidget {
  final List<_HealthGoal> selectedGoals;

  const _NamiReflectionCard({required this.selectedGoals});

  @override
  Widget build(BuildContext context) {
    final hasSelected = selectedGoals.isNotEmpty;
    final title = hasSelected
        ? 'Nami đã hiểu điều bạn đang ưu tiên'
        : 'Mình bắt đầu thật nhẹ thôi nhé';
    final body = hasSelected
        ? 'Những lựa chọn này sẽ giúp Nami gợi ý bữa ăn, lịch sinh hoạt và lời nhắc phù hợp hơn. Bạn vẫn có thể đổi lại bất cứ lúc nào.'
        : 'Bạn không cần đặt quá nhiều mục tiêu ngay từ đầu. Chỉ cần chọn những điều bạn thật sự muốn cải thiện trước, còn lại Nami sẽ cùng bạn đi từng bước.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.premiumCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final icon = Container(
            width: compact ? 58 : 68,
            height: compact ? 58 : 68,
            decoration: AppDecoration.gradient(
              colors: hasSelected
                  ? const [AppColors.success, AppColors.secondary]
                  : const [AppColors.primary, AppColors.secondary],
              radius: AppRadius.xl,
              shadows: hasSelected ? AppShadows.success : AppShadows.primary,
            ),
            child: Icon(
              hasSelected
                  ? Icons.volunteer_activism_rounded
                  : Icons.self_improvement_rounded,
              color: Colors.white,
              size: compact ? 28 : 32,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.62,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: AppSpacing.md),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _HumanSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _HumanSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: AppDecoration.outlined(
              color: AppColors.primarySoft,
              borderColor: AppColors.primary.withOpacity(0.18),
              radius: AppRadius.circular,
            ),
            child: Text(
              eyebrow.toUpperCase(),
              style: AppTextStyles.overline.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.62,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCategorySelector extends StatelessWidget {
  final String activeCategoryId;
  final Set<String> selectedCodes;
  final ValueChanged<String> onChanged;

  const _GoalCategorySelector({
    required this.activeCategoryId,
    required this.selectedCodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _GoalCategoryCatalog.items
              .map((category) {
                final selectedCount = category.id == _GoalCategoryCatalog.all.id
                    ? selectedCodes.length
                    : _GoalCatalog.items
                          .where(
                            (goal) =>
                                goal.categoryId == category.id &&
                                selectedCodes.contains(goal.code),
                          )
                          .length;
                final active = activeCategoryId == category.id;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _GoalCategoryPill(
                    category: category,
                    active: active,
                    selectedCount: selectedCount,
                    onTap: () => onChanged(category.id),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _GoalCategoryPill extends StatelessWidget {
  final _GoalCategory category;
  final bool active;
  final int selectedCount;
  final VoidCallback onTap;

  const _GoalCategoryPill({
    required this.category,
    required this.active,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        child: AnimatedContainer(
          duration: AppDuration.card,
          curve: AppAnimations.smoothCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: active
              ? AppDecoration.gradient(
                  colors: const [AppColors.primary, AppColors.secondary],
                  radius: AppRadius.circular,
                  shadows: AppShadows.primary,
                )
              : AppDecoration.outlined(
                  color: Colors.white.withOpacity(0.92),
                  borderColor: AppColors.border,
                  radius: AppRadius.circular,
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                category.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: active ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (selectedCount > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: AppDecoration.circle(
                    color: active
                        ? Colors.white.withOpacity(0.20)
                        : AppColors.primarySoft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$selectedCount',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: active ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
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

class _GoalsWrap extends StatelessWidget {
  final List<_HealthGoal> goals;
  final Set<String> selectedCodes;
  final ValueChanged<String> onToggle;

  const _GoalsWrap({
    required this.goals,
    required this.selectedCodes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = _columnCount(width);
        final spacing = width < 420 ? AppSpacing.sm : AppSpacing.md;
        final itemWidth = math.max(
          0,
          (width - spacing * (columns - 1)) / columns,
        );

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: goals
              .map((goal) {
                final selected = selectedCodes.contains(goal.code);

                return SizedBox(
                  width: itemWidth.toDouble(),
                  child: _GoalCard(
                    goal: goal,
                    selected: selected,
                    onTap: () => onToggle(goal.code),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= 1120) return 4;
    if (width >= 760) return 3;
    if (width >= 430) return 2;
    return 1;
  }
}

class _GoalCard extends StatelessWidget {
  final _HealthGoal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.card,
          curve: AppAnimations.emphasizedCurve,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: selected
              ? AppDecoration.gradient(
                  colors: goal.gradient.colors,
                  radius: AppRadius.cardLarge,
                  shadows: AppShadows.primary,
                )
              : AppDecoration.card(
                  radius: AppRadius.cardLarge,
                  border: Border.all(color: AppColors.border.withOpacity(0.82)),
                  shadows: AppShadows.soft,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppDuration.card,
                    width: 40,
                    height: 40,
                    decoration: AppDecoration.container(
                      color: selected
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.primarySoft,
                      radius: AppRadius.lg,
                    ),
                    child: Center(
                      child: Text(
                        goal.emoji,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: AppDuration.card,
                    width: 24,
                    height: 24,
                    decoration: AppDecoration.circle(
                      color: selected
                          ? Colors.white.withOpacity(0.20)
                          : AppColors.primarySoft,
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      color: selected ? Colors.white : AppColors.primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                goal.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                goal.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected
                      ? Colors.white.withOpacity(0.88)
                      : AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: AppDecoration.outlined(
                    color: selected
                        ? Colors.white.withOpacity(0.14)
                        : AppColors.primarySoft,
                    borderColor: selected
                        ? Colors.white.withOpacity(0.18)
                        : AppColors.primary.withOpacity(0.12),
                    radius: AppRadius.circular,
                  ),
                  child: Text(
                    selected ? 'Nami đã ghi nhớ' : goal.microCopy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w900,
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

class _OtherGoalCard extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _OtherGoalCard({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.glass(
        opacity: 0.94,
        radius: AppRadius.cardLarge,
        shadows: AppShadows.soft,
      ).copyWith(border: Border.all(color: Colors.white.withOpacity(0.72))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final icon = Container(
                width: 46,
                height: 46,
                decoration: AppDecoration.gradient(
                  colors: const [AppColors.primary, AppColors.secondary],
                  radius: AppRadius.lg,
                  shadows: AppShadows.primary,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              );

              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nami sẽ đọc phần này thật kỹ',
                    style: AppTextStyles.heading5.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Những điều bạn tự viết thường là phần quan trọng nhất để Nami hiểu bạn hơn.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: AppSpacing.md),
                    text,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: text),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          OnboardingTextField(
            label: 'Mục tiêu hoặc mong muốn khác',
            hint: 'Ví dụ: Mình muốn bớt mệt, ngủ sớm hơn và ăn uống đều hơn...',
            initialValue: initialValue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NamiPromiseCard extends StatelessWidget {
  final int selectedCount;

  const _NamiPromiseCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final title = selectedCount == 0
        ? 'Bạn có thể chọn sau, không sao cả'
        : 'Nami sẽ bắt đầu từ những điều bạn chọn';
    final body = selectedCount == 0
        ? 'Nếu hôm nay bạn chưa chắc mình cần gì, cứ tiếp tục. Nami vẫn có thể đồng hành và giúp bạn điều chỉnh dần trong quá trình sử dụng.'
        : 'Mình sẽ không ép bạn thay đổi quá nhanh. Nami sẽ nhắc nhẹ, gợi ý vừa sức và giúp bạn duy trì những thói quen nhỏ nhưng có ý nghĩa.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.gradient(
        colors: const [AppColors.success, AppColors.secondary],
        radius: AppRadius.xxxl,
        shadows: AppShadows.success,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;

          final icon = Container(
            width: compact ? 58 : 66,
            height: compact ? 58 : 66,
            decoration: AppDecoration.glass(
              opacity: 0.15,
              radius: AppRadius.xl,
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 32),
          );

          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.heading4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  height: 1.62,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _PromiseChip(label: 'Không phán xét'),
                  _PromiseChip(label: 'Nhắc nhẹ nhàng'),
                  _PromiseChip(label: 'Dễ duy trì'),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: AppSpacing.md),
                text,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

class _PromiseChip extends StatelessWidget {
  final String label;

  const _PromiseChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecoration.glass(
        opacity: 0.13,
        radius: AppRadius.circular,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FloatingGlow extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Gradient gradient;
  final double opacity;

  const _FloatingGlow({
    required this.controller,
    required this.size,
    required this.gradient,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(
              math.sin(controller.value * math.pi * 2) * 18,
              math.cos(controller.value * math.pi * 2) * 18,
            ),
            child: child,
          );
        },
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsBackgroundPainter extends CustomPainter {
  final double animation;

  const _GoalsBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.52),
          Colors.white,
          AppColors.secondarySoft.withOpacity(0.36),
        ],
        transform: GradientRotation(animation * math.pi * 0.75),
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.026)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 46) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y <= size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pulsePaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pulse = 0.5 + math.sin(animation * math.pi * 2) * 0.5;
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.18),
      70 + pulse * 18,
      pulsePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.72),
      95 + pulse * 24,
      pulsePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalsBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _GoalCategory {
  final String id;
  final String label;
  final String emoji;

  const _GoalCategory({
    required this.id,
    required this.label,
    required this.emoji,
  });
}

class _GoalCategoryCatalog {
  const _GoalCategoryCatalog._();

  static const all = _GoalCategory(id: 'all', label: 'Tất cả', emoji: '✨');

  static const items = [
    all,
    _GoalCategory(id: 'body', label: 'Cơ thể', emoji: '💪'),
    _GoalCategory(id: 'nutrition', label: 'Ăn uống', emoji: '🥗'),
    _GoalCategory(id: 'mind', label: 'Tinh thần', emoji: '🌿'),
    _GoalCategory(id: 'routine', label: 'Thói quen', emoji: '⏰'),
    _GoalCategory(id: 'medical', label: 'Theo dõi', emoji: '🩺'),
  ];
}

class _HealthGoal {
  final String code;
  final String categoryId;
  final String emoji;
  final String title;
  final String description;
  final String microCopy;
  final LinearGradient gradient;

  const _HealthGoal({
    required this.code,
    required this.categoryId,
    required this.emoji,
    required this.title,
    required this.description,
    required this.microCopy,
    required this.gradient,
  });
}

class _GoalCatalog {
  const _GoalCatalog._();

  static const items = [
    _HealthGoal(
      code: 'lose_weight',
      categoryId: 'body',
      emoji: '⚖️',
      title: 'Giảm cân lành mạnh',
      description: 'Điều chỉnh bữa ăn và vận động nhẹ để giảm cân bền hơn.',
      microCopy: 'Nhẹ nhàng từng chút',
      gradient: AppGradients.primary,
    ),
    _HealthGoal(
      code: 'gain_weight',
      categoryId: 'body',
      emoji: '🍚',
      title: 'Tăng cân an toàn',
      description: 'Ăn đủ chất, tăng năng lượng và theo dõi thay đổi cơ thể.',
      microCopy: 'Tăng đều, không vội',
      gradient: AppGradients.energy,
    ),
    _HealthGoal(
      code: 'maintain_shape',
      categoryId: 'body',
      emoji: '🌤️',
      title: 'Giữ dáng ổn định',
      description: 'Duy trì vóc dáng, cân bằng ăn uống và sinh hoạt mỗi ngày.',
      microCopy: 'Duy trì vừa sức',
      gradient: AppGradients.health,
    ),
    _HealthGoal(
      code: 'build_muscle',
      categoryId: 'body',
      emoji: '💪',
      title: 'Tăng cơ, khỏe hơn',
      description: 'Ưu tiên protein, lịch tập và phục hồi hợp lý hơn.',
      microCopy: 'Khỏe hơn mỗi tuần',
      gradient: AppGradients.success,
    ),
    _HealthGoal(
      code: 'more_energy',
      categoryId: 'body',
      emoji: '⚡',
      title: 'Bớt mệt, nhiều năng lượng',
      description: 'Tìm lại nhịp sinh hoạt giúp bạn tỉnh táo và bền sức hơn.',
      microCopy: 'Đỡ uể oải hơn',
      gradient: AppGradients.energy,
    ),
    _HealthGoal(
      code: 'balanced_meals',
      categoryId: 'nutrition',
      emoji: '🥗',
      title: 'Ăn uống cân bằng',
      description: 'Gợi ý món ăn gần gũi, đủ chất và dễ duy trì lâu dài.',
      microCopy: 'Ăn tốt hơn',
      gradient: AppGradients.health,
    ),
    _HealthGoal(
      code: 'meal_routine',
      categoryId: 'nutrition',
      emoji: '🍱',
      title: 'Ăn đúng bữa hơn',
      description:
          'Nhắc nhẹ để bạn không bỏ bữa khi học, làm việc hoặc bận rộn.',
      microCopy: 'Đều bữa hơn',
      gradient: AppGradients.primaryReverse,
    ),
    _HealthGoal(
      code: 'drink_water',
      categoryId: 'nutrition',
      emoji: '💧',
      title: 'Uống nước đều hơn',
      description: 'Tạo lời nhắc nhỏ để cơ thể được cấp nước tốt hơn mỗi ngày.',
      microCopy: 'Một ngụm nhỏ thôi',
      gradient: AppGradients.info,
    ),
    _HealthGoal(
      code: 'digestive_health',
      categoryId: 'nutrition',
      emoji: '🌾',
      title: 'Chăm tiêu hóa',
      description: 'Ưu tiên món dễ chịu, chất xơ và nhịp ăn phù hợp hơn.',
      microCopy: 'Êm bụng hơn',
      gradient: AppGradients.success,
    ),
    _HealthGoal(
      code: 'less_sugar',
      categoryId: 'nutrition',
      emoji: '🍬',
      title: 'Giảm đồ ngọt',
      description:
          'Giảm dần thói quen ăn ngọt mà không tạo cảm giác bị ép buộc.',
      microCopy: 'Giảm từ từ',
      gradient: AppGradients.warning,
    ),
    _HealthGoal(
      code: 'better_sleep',
      categoryId: 'mind',
      emoji: '😴',
      title: 'Ngủ ngon hơn',
      description: 'Tạo nhịp nghỉ ngơi, thư giãn và ngủ đúng giờ hơn.',
      microCopy: 'Ngủ sâu hơn',
      gradient: AppGradients.sleep,
    ),
    _HealthGoal(
      code: 'reduce_stress',
      categoryId: 'mind',
      emoji: '🌿',
      title: 'Giảm căng thẳng',
      description: 'Nhắc bạn nghỉ ngắn, thở chậm và chăm cảm xúc của mình.',
      microCopy: 'Bình tĩnh hơn',
      gradient: AppGradients.meditation,
    ),
    _HealthGoal(
      code: 'better_focus',
      categoryId: 'mind',
      emoji: '🎯',
      title: 'Tập trung tốt hơn',
      description: 'Sắp xếp nhịp sinh hoạt để đầu óc tỉnh táo và ít xao nhãng.',
      microCopy: 'Rõ đầu hơn',
      gradient: AppGradients.ai,
    ),
    _HealthGoal(
      code: 'better_mood',
      categoryId: 'mind',
      emoji: '😊',
      title: 'Tâm trạng tích cực hơn',
      description:
          'Theo dõi những ngày lên xuống và tìm thói quen giúp bạn dễ chịu.',
      microCopy: 'Dịu lại một chút',
      gradient: AppGradients.primary,
    ),
    _HealthGoal(
      code: 'morning_routine',
      categoryId: 'routine',
      emoji: '🌅',
      title: 'Xây thói quen buổi sáng',
      description:
          'Bắt đầu ngày mới bằng vài việc nhỏ dễ làm và có lợi cho cơ thể.',
      microCopy: 'Sáng nhẹ hơn',
      gradient: AppGradients.energy,
    ),
    _HealthGoal(
      code: 'evening_routine',
      categoryId: 'routine',
      emoji: '🌙',
      title: 'Thư giãn buổi tối',
      description: 'Giảm nhịp trước khi ngủ để cơ thể có thời gian hồi phục.',
      microCopy: 'Tối yên hơn',
      gradient: AppGradients.sleep,
    ),
    _HealthGoal(
      code: 'move_more',
      categoryId: 'routine',
      emoji: '🚶',
      title: 'Vận động nhiều hơn',
      description:
          'Gợi ý đi bộ, giãn cơ hoặc hoạt động nhỏ phù hợp lịch của bạn.',
      microCopy: 'Di chuyển nhẹ',
      gradient: AppGradients.success,
    ),
    _HealthGoal(
      code: 'healthy_habits',
      categoryId: 'routine',
      emoji: '✅',
      title: 'Duy trì thói quen tốt',
      description:
          'Theo dõi các việc nhỏ mỗi ngày để bạn thấy mình đang tiến bộ.',
      microCopy: 'Tích lũy mỗi ngày',
      gradient: AppGradients.primaryReverse,
    ),
    _HealthGoal(
      code: 'heart_health',
      categoryId: 'medical',
      emoji: '❤️',
      title: 'Quan tâm tim mạch',
      description: 'Ưu tiên nhịp sống, vận động và bữa ăn thân thiện hơn.',
      microCopy: 'Chăm tim nhẹ nhàng',
      gradient: AppGradients.danger,
    ),
    _HealthGoal(
      code: 'blood_pressure',
      categoryId: 'medical',
      emoji: '🩺',
      title: 'Theo dõi huyết áp',
      description: 'Ghi nhận đều hơn để bạn dễ quan sát biến động hằng ngày.',
      microCopy: 'Theo dõi sát hơn',
      gradient: AppGradients.info,
    ),
    _HealthGoal(
      code: 'blood_sugar',
      categoryId: 'medical',
      emoji: '🩸',
      title: 'Quan tâm đường huyết',
      description: 'Gợi ý ăn uống điều độ hơn và theo dõi phản ứng cơ thể.',
      microCopy: 'Ổn định hơn',
      gradient: AppGradients.warning,
    ),
    _HealthGoal(
      code: 'immune_support',
      categoryId: 'medical',
      emoji: '🛡️',
      title: 'Tăng sức đề kháng',
      description: 'Chăm giấc ngủ, bữa ăn và vận động để cơ thể bền hơn.',
      microCopy: 'Bền sức hơn',
      gradient: AppGradients.health,
    ),
  ];
}
