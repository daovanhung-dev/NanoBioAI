import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ConditionsStep extends ConsumerStatefulWidget {
  const ConditionsStep({super.key});

  @override
  ConsumerState<ConditionsStep> createState() => _ConditionsStepState();
}

class _ConditionsStepState extends ConsumerState<ConditionsStep> {
  void _openConditionPicker(BuildContext context) {
    final controller = ref.read(onboardingProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(onboardingProvider);
            final selectedCodes = Set<String>.from(state.conditions);

            final items = OnboardingCatalog.conditions
                .map(
                  (item) => _ConditionViewData(
                    code: item.code,
                    emoji: item.emoji,
                    label: item.label,
                  ),
                )
                .toList(growable: false);

            final selectedCount = selectedCodes.length;
            final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                decoration: AppDecoration.bottomSheet(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sheetHandleSpacing),
                    const _SheetHandle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.bottomSheetPadding,
                        AppSpacing.md,
                        AppSpacing.bottomSheetPadding,
                        AppSpacing.sm,
                      ),
                      child: _PickerHeader(selectedCount: selectedCount),
                    ),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth.isFinite
                              ? constraints.maxWidth
                              : MediaQuery.sizeOf(context).width -
                                    AppSpacing.bottomSheetPadding * 2;

                          final columns = availableWidth >= 760 ? 2 : 1;
                          final gap = AppSpacing.sm;

                          final itemWidth =
                              ((availableWidth - gap * (columns - 1)) / columns)
                                  .clamp(0.0, availableWidth)
                                  .toDouble();

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.bottomSheetPadding,
                              AppSpacing.sm,
                              AppSpacing.bottomSheetPadding,
                              AppSpacing.lg,
                            ),
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: items.map((item) {
                                final selected = selectedCodes.contains(
                                  item.code,
                                );

                                return _ConditionOptionTile(
                                  width: itemWidth,
                                  item: item,
                                  selected: selected,
                                  onTap: () {
                                    controller.toggleCondition(item.code);
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    _PickerFooter(
                      selectedCount: selectedCount,
                      onDone: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final selectedCodes = Set<String>.from(state.conditions);
    final selectedItems = OnboardingCatalog.conditions
        .where((item) => selectedCodes.contains(item.code))
        .map(
          (item) => _ConditionViewData(
            code: item.code,
            emoji: item.emoji,
            label: item.label,
          ),
        )
        .toList(growable: false);

    final selectedCount = selectedItems.length;

    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _SoftHealthBackground()),
        ),
        const Positioned(
          top: -120,
          right: -96,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.12,
              child: _DecorativeGlow(size: 280, gradient: AppGradients.ai),
            ),
          ),
        ),
        const Positioned(
          bottom: -160,
          left: -120,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.10,
              child: _DecorativeGlow(size: 340, gradient: AppGradients.health),
            ),
          ),
        ),
        OnboardingStepShell(
          stepIndex: 3,
          title: '',
          subtitle: '',
          isScrollable: false,
          onBack: controller.previousStep,
          onNext: controller.nextStep,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth =
                  constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;

              final contentMaxWidth = availableWidth >= 960
                  ? 860.0
                  : availableWidth;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NamiHeroCard(selectedCount: selectedCount),
                        const SizedBox(height: AppSpacing.xl),
                        _NamiInsightCard(selectedCount: selectedCount),
                        const SizedBox(height: AppSpacing.xl),
                        const _FriendlySectionHeader(
                          icon: AppIcons.health,
                          title: 'Cơ thể bạn đang muốn được quan tâm điều gì?',
                          subtitle:
                              'Bạn chỉ cần chọn những điều đang đúng với mình. Không cần hoàn hảo ngay từ đầu, Nami sẽ cùng bạn điều chỉnh dần.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ConditionPickerField(
                          selectedItems: selectedItems,
                          totalCount: OnboardingCatalog.conditions.length,
                          onTap: () => _openConditionPicker(context),
                        ),
                        if (selectedItems.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _SelectedConditionsPreview(
                            items: selectedItems,
                            onRemove: controller.toggleCondition,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        const _FriendlySectionHeader(
                          icon: AppIcons.chat,
                          title: 'Có điều gì khác bạn muốn kể với Nami không?',
                          subtitle:
                              'Bạn có thể viết theo cách tự nhiên nhất. Nami sẽ lắng nghe nhẹ nhàng, không phán xét và không ép buộc.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _OtherConditionCard(
                          otherCondition: state.otherCondition,
                          onChanged: controller.updateOtherCondition,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _NamiClosingCard(selectedCount: selectedCount),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConditionViewData {
  final String code;
  final String emoji;
  final String label;

  const _ConditionViewData({
    required this.code,
    required this.emoji,
    required this.label,
  });
}

class _NamiHeroCard extends StatelessWidget {
  final int selectedCount;

  const _NamiHeroCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;

          final metricWidth = ((maxWidth - AppSpacing.md) / 2)
              .clamp(160.0, 360.0)
              .toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [_NamiAvatar(), _SoftHeroBadge()],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Nami muốn hiểu bạn hơn một chút',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Những chia sẻ ở bước này giúp Nami chăm sóc bạn tinh tế hơn: từ bữa ăn, nhịp sinh hoạt đến những lời nhắc nhẹ nhàng hằng ngày.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite.withOpacity(0.92),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _HeroMetric(
                      icon: AppIcons.success,
                      title: 'Nami đã ghi nhận',
                      value: selectedCount == 0
                          ? 'Chưa chọn mục nào'
                          : '$selectedCount điều cần quan tâm',
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: const _HeroMetric(
                      icon: AppIcons.favorite,
                      title: 'Cách Nami đồng hành',
                      value: 'Nhẹ nhàng và tôn trọng',
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
}

class _NamiAvatar extends StatelessWidget {
  const _NamiAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: AppDecoration.glass(
        radius: AppRadius.circular,
        shadows: AppShadows.glass,
      ),
      child: Center(
        child: Container(
          width: 54,
          height: 54,
          decoration: AppDecoration.circle(
            color: AppColors.textWhite.withOpacity(0.18),
          ),
          child: const Icon(
            AppIcons.aiHealth,
            color: AppColors.textWhite,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _SoftHeroBadge extends StatelessWidget {
  const _SoftHeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecoration.glass(radius: AppRadius.circular),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.verified, color: AppColors.textWhite, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Nami đang lắng nghe',
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

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.glass(radius: AppRadius.xl),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconButtonSize,
            height: AppSpacing.iconButtonSize,
            decoration: AppDecoration.circle(
              color: AppColors.textWhite.withOpacity(0.16),
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
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

class _NamiInsightCard extends StatelessWidget {
  final int selectedCount;

  const _NamiInsightCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return _ResponsiveInfoCard(
      icon: hasSelection ? AppIcons.favorite : AppIcons.info,
      iconGradient: hasSelection ? AppGradients.health : AppGradients.ai,
      title: hasSelection
          ? 'Nami đã ghi nhớ điều này'
          : 'Bạn có thể bắt đầu thật nhẹ nhàng',
      message: hasSelection
          ? 'Từ những điều bạn chọn, Nami sẽ ưu tiên gợi ý chăm sóc phù hợp hơn, không đưa ra lời khuyên quá chung chung.'
          : 'Bạn chỉ cần chọn những tình trạng gần đúng nhất. Nếu chưa chắc, bạn có thể bỏ qua hoặc kể thêm ở phần bên dưới.',
    );
  }
}

class _ResponsiveInfoCard extends StatelessWidget {
  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String message;

  const _ResponsiveInfoCard({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.cardRaised,
        gradient: AppGradients.surface,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final iconBox = Container(
            width: 64,
            height: 64,
            decoration: AppDecoration.circle(
              gradient: iconGradient,
              shadows: AppShadows.primary,
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 30),
          );

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(height: AppSpacing.md),
                textContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBox,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: textContent),
            ],
          );
        },
      ),
    );
  }
}

class _FriendlySectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FriendlySectionHeader({
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
          width: AppSpacing.iconButtonSize,
          height: AppSpacing.iconButtonSize,
          decoration: AppDecoration.circle(color: AppColors.primarySoft),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.32,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionPickerField extends StatelessWidget {
  final List<_ConditionViewData> selectedItems;
  final int totalCount;
  final VoidCallback onTap;

  const _ConditionPickerField({
    required this.selectedItems,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedItems.isNotEmpty;
    final previewItems = selectedItems.take(5).toList(growable: false);
    final hiddenCount = selectedItems.length - previewItems.length;

    return AnimatedContainer(
      duration: AppDuration.card,
      curve: AppAnimations.emphasizedCurve,
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: hasSelection ? AppShadows.cardRaised : AppShadows.card,
        border: Border.all(
          color: hasSelection ? AppColors.primary : AppColors.border,
          width: hasSelection ? 1.4 : 1.0,
        ),
        gradient: hasSelection
            ? AppGradients.primarySoft
            : AppGradients.surface,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: AppDuration.card,
                      width: 52,
                      height: 52,
                      decoration: AppDecoration.circle(
                        color: hasSelection
                            ? AppColors.primary
                            : AppColors.primarySoft,
                      ),
                      child: Icon(
                        hasSelection ? AppIcons.success : AppIcons.add,
                        color: hasSelection
                            ? AppColors.textWhite
                            : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSelection
                                ? 'Bạn đã chọn ${selectedItems.length} điều'
                                : 'Chạm để chọn tình trạng',
                            style: AppTextStyles.heading5.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hasSelection
                                ? 'Nami sẽ ưu tiên quan tâm những điều này.'
                                : 'Có $totalCount lựa chọn sẵn, bạn không cần nhập tay.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: AppSpacing.iconButtonSize,
                      height: AppSpacing.iconButtonSize,
                      decoration: AppDecoration.circle(
                        color: AppColors.card,
                        shadows: AppShadows.xs,
                      ),
                      child: const Icon(
                        AppIcons.expand,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (hasSelection)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ...previewItems.map(
                        (item) => _SoftSelectionPill(
                          emoji: item.emoji,
                          label: item.label,
                        ),
                      ),
                      if (hiddenCount > 0)
                        _MoreSelectionPill(count: hiddenCount),
                    ],
                  )
                else
                  const _EmptyPickerHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPickerHint extends StatelessWidget {
  const _EmptyPickerHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.input(
        color: AppColors.inputBackground,
        radius: AppRadius.lg,
        borderColor: AppColors.border,
      ),
      child: Row(
        children: [
          const Icon(AppIcons.info, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Bạn có thể chọn nhiều mục, hoặc không chọn nếu chưa chắc.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftSelectionPill extends StatelessWidget {
  final String emoji;
  final String label;

  const _SoftSelectionPill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecoration.outlined(
        color: AppColors.card,
        borderColor: AppColors.border,
        radius: AppRadius.circular,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: AppTextStyles.bodyMedium),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreSelectionPill extends StatelessWidget {
  final int count;

  const _MoreSelectionPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecoration.outlined(
        color: AppColors.primarySoft,
        borderColor: AppColors.primaryLight,
        radius: AppRadius.circular,
      ),
      child: Text(
        '+$count mục nữa',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectedConditionsPreview extends StatelessWidget {
  final List<_ConditionViewData> items;
  final ValueChanged<String> onRemove;

  const _SelectedConditionsPreview({
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Những điều Nami đang ghi nhớ',
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bạn có thể bỏ chọn bất kỳ lúc nào nếu thấy chưa đúng.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: items.map((item) {
              return _RemovableConditionChip(
                item: item,
                onRemove: () => onRemove(item.code),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RemovableConditionChip extends StatelessWidget {
  final _ConditionViewData item;
  final VoidCallback onRemove;

  const _RemovableConditionChip({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.circular),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDecoration.outlined(
            color: Colors.transparent,
            borderColor: AppColors.primaryLight,
            radius: AppRadius.circular,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: AppTextStyles.bodyMedium),
              const SizedBox(width: AppSpacing.xs),
              Text(
                item.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(AppIcons.close, color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherConditionCard extends StatelessWidget {
  final String otherCondition;
  final ValueChanged<String> onChanged;

  const _OtherConditionCard({
    required this.otherCondition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = otherCondition.trim().isNotEmpty;

    return AnimatedContainer(
      duration: AppDuration.card,
      curve: AppAnimations.emphasizedCurve,
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.soft,
        border: Border.all(
          color: hasText ? AppColors.primary : AppColors.border,
          width: hasText ? 1.4 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.iconButtonSize,
                height: AppSpacing.iconButtonSize,
                decoration: AppDecoration.circle(
                  color: hasText ? AppColors.successSoft : AppColors.infoSoft,
                ),
                child: Icon(
                  hasText ? AppIcons.success : AppIcons.edit,
                  color: hasText ? AppColors.success : AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasText
                      ? 'Nami đã nhận thêm chia sẻ của bạn'
                      : 'Phần này hoàn toàn tuỳ bạn',
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingTextField(
            label: 'Bạn muốn Nami lưu ý thêm điều gì?',
            hint:
                'Ví dụ: mình hay đau đầu khi thiếu ngủ, mình dị ứng hải sản, mình dễ mệt vào buổi chiều...',
            initialValue: otherCondition,
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: AppDecoration.input(
              color: AppColors.inputBackground,
              radius: AppRadius.lg,
              borderColor: AppColors.border,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  AppIcons.shield,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Bạn không cần viết dài hay dùng từ chuyên môn. Chỉ cần vài dòng đúng với cảm nhận của bạn là đủ.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
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

class _NamiClosingCard extends StatelessWidget {
  final int selectedCount;

  const _NamiClosingCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Container(
      decoration: AppDecoration.gradient(
        colors: const [AppColors.textPrimary, AppColors.primaryDark],
        radius: AppRadius.xxl,
        shadows: AppShadows.floating,
      ),
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final icon = Container(
            width: 58,
            height: 58,
            decoration: AppDecoration.glass(radius: AppRadius.xl),
            child: Icon(
              hasSelection ? AppIcons.favorite : AppIcons.ai,
              color: AppColors.textWhite,
              size: 28,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSelection
                    ? 'Cảm ơn bạn đã chia sẻ với Nami'
                    : 'Bạn vẫn có thể tiếp tục thật thoải mái',
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w800,
                  height: 1.32,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasSelection
                    ? 'Nami sẽ dùng những thông tin này để chăm sóc bạn tinh tế hơn trong các gợi ý tiếp theo.'
                    : 'Nếu chưa muốn chọn gì ở bước này, bạn có thể đi tiếp. Nami sẽ dần hiểu bạn hơn qua quá trình sử dụng.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite.withOpacity(0.82),
                  height: 1.65,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: AppDecoration.container(
        color: AppColors.border,
        radius: AppRadius.sheetHandle,
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  final int selectedCount;

  const _PickerHeader({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: const [],
        gradient: AppGradients.primarySoft,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          Container(
            width: AppSpacing.avatarSizeLarge,
            height: AppSpacing.avatarSizeLarge,
            decoration: AppDecoration.circle(
              gradient: AppGradients.ai,
              shadows: AppShadows.primary,
            ),
            child: const Icon(
              AppIcons.aiHealth,
              color: AppColors.textWhite,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nami nên chú ý điều gì?',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  selectedCount == 0
                      ? 'Chọn những điều đang đúng với bạn.'
                      : 'Đã chọn $selectedCount mục. Chạm lại để bỏ chọn.',
                  style: AppTextStyles.bodySmall.copyWith(
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
}

class _ConditionOptionTile extends StatelessWidget {
  final double width;
  final _ConditionViewData item;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionOptionTile({
    required this.width,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: SizedBox(
        width: width,
        child: AnimatedContainer(
          duration: AppDuration.card,
          curve: AppAnimations.emphasizedCurve,
          decoration: AppDecoration.card(
            color: selected ? AppColors.primarySoft : AppColors.card,
            radius: AppRadius.lg,
            shadows: selected ? AppShadows.xs : const [],
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.2 : 1,
            ),
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
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppDuration.card,
                      curve: AppAnimations.emphasizedCurve,
                      width: 40,
                      height: 40,
                      decoration: AppDecoration.circle(
                        color: selected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.inputBackground,
                      ),
                      child: Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 21),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            selected
                                ? 'Nami đã ghi nhớ điều này'
                                : 'Chạm để Nami lưu ý hơn',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedContainer(
                      duration: AppDuration.fast,
                      curve: AppAnimations.emphasizedCurve,
                      width: 24,
                      height: 24,
                      decoration: AppDecoration.circle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.inputBackground,
                      ),
                      child: Icon(
                        selected ? AppIcons.success : AppIcons.add,
                        color: selected
                            ? AppColors.textWhite
                            : AppColors.textMuted,
                        size: 16,
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

class _PickerFooter extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDone;

  const _PickerFooter({required this.selectedCount, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.none,
        shadows: AppShadows.appBar,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.bottomSheetPadding,
        AppSpacing.md,
        AppSpacing.bottomSheetPadding,
        AppSpacing.bottomSheetPadding,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCount == 0
                  ? 'Bạn có thể chọn sau nếu chưa chắc.'
                  : 'Nami đã ghi nhớ $selectedCount điều để chăm sóc bạn tốt hơn.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
                child: InkWell(
                  onTap: onDone,
                  borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Center(
                      child: Text(
                        'Xong rồi',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeGlow extends StatelessWidget {
  final double size;
  final Gradient gradient;

  const _DecorativeGlow({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppDecoration.circle(gradient: gradient),
    );
  }
}

class _SoftHealthBackground extends CustomPainter {
  const _SoftHealthBackground();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = AppGradients.onboarding.createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final primaryOrb = Paint()
      ..shader =
          RadialGradient(
            colors: [AppColors.primary.withOpacity(0.12), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.86, size.height * 0.16),
              radius: 220,
            ),
          );

    final healthOrb = Paint()
      ..shader =
          RadialGradient(
            colors: [AppColors.success.withOpacity(0.10), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.10, size.height * 0.84),
              radius: 240,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.16),
      220,
      primaryOrb,
    );

    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.84),
      240,
      healthOrb,
    );
  }

  @override
  bool shouldRepaint(covariant _SoftHealthBackground oldDelegate) {
    return false;
  }
}
