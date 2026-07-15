import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final selectedCount = state.goals.length;
    final totalGoals = OnboardingCatalog.goals.length;

    return OnboardingStepShell(
      stepIndex: 2,
      title: 'Bạn muốn tiến gần điều gì?',
      subtitle:
          'Hãy chọn những ưu tiên thật sự quan trọng với bạn lúc này. Bạn có thể chọn nhiều mục tiêu.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _GoalsLayout.fromWidth(constraints.maxWidth);

          final otherGoalCard = _OtherGoalCard(
            compact: layout.isCompact,
            initialValue: state.otherGoal,
            onChanged: controller.updateOtherGoal,
          );

          final guidanceCard = _GoalGuidanceCard(
            compact: layout.isCompact,
            selectedCount: selectedCount,
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GoalProgressBanner(
                    selectedCount: selectedCount,
                    totalGoals: totalGoals,
                    compact: layout.isCompact,
                  ),
                  SizedBox(height: layout.sectionGap),

                  _GoalSelectionCard(
                    compact: layout.isCompact,
                    selectedCount: selectedCount,
                    totalGoals: totalGoals,
                    child: OnboardingChoiceGrid(
                      options: OnboardingCatalog.goals,
                      selectedCodes: state.goals,
                      multiSelect: true,
                      onSelected: controller.toggleGoal,
                    ),
                  ),

                  SizedBox(height: layout.sectionGap),

                  if (layout.showSupportingRow)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 12, child: otherGoalCard),
                        SizedBox(width: layout.desktopGap),
                        Expanded(flex: 9, child: guidanceCard),
                      ],
                    )
                  else ...[
                    otherGoalCard,
                    SizedBox(height: layout.sectionGap),
                    guidanceCard,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoalsLayout {
  final bool isCompact;
  final bool showSupportingRow;
  final double sectionGap;
  final double desktopGap;

  const _GoalsLayout({
    required this.isCompact,
    required this.showSupportingRow,
    required this.sectionGap,
    required this.desktopGap,
  });

  factory _GoalsLayout.fromWidth(double width) {
    final compact = width < 380;

    return _GoalsLayout(
      isCompact: compact,
      showSupportingRow: width >= 760,
      sectionGap: compact ? 12 : 16,
      desktopGap: 16,
    );
  }
}

class _GoalProgressBanner extends StatelessWidget {
  final int selectedCount;
  final int totalGoals;
  final bool compact;

  const _GoalProgressBanner({
    required this.selectedCount,
    required this.totalGoals,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final progress = totalGoals == 0
        ? 0.0
        : (selectedCount / totalGoals).clamp(0.0, 1.0).toDouble();

    final primary = hasSelection ? NabiPalette.cyan : NabiPalette.violet;
    final secondary = hasSelection ? NabiPalette.violet : NabiPalette.royalBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -42,
            top: -54,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 52,
            bottom: -82,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NabiPalette.amber.withValues(alpha: 0.14),
              ),
            ),
          ),
          Row(
            children: [
              _GoalCounterOrb(
                selectedCount: selectedCount,
                progress: progress,
                compact: compact,
              ),
              SizedBox(width: compact ? 12 : 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelection
                          ? 'Bản đồ mục tiêu đang hình thành'
                          : 'Bản đồ mục tiêu của bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 17,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        hasSelection
                            ? '$selectedCount mục tiêu đã được ưu tiên. Bạn có thể chọn thêm bất cứ lúc nào.'
                            : 'Chọn điều bạn muốn thay đổi trước tiên. Không cần hoàn hảo.',
                        key: ValueKey(selectedCount),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: compact ? 11.5 : 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: compact ? 5 : 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCounterOrb extends StatelessWidget {
  final int selectedCount;
  final double progress;
  final bool compact;

  const _GoalCounterOrb({
    required this.selectedCount,
    required this.progress,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 54.0 : 62.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: compact ? 4.5 : 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selectedCount == 0
                    ? Icon(
                        Icons.track_changes_rounded,
                        key: const ValueKey('target'),
                        color: Colors.white,
                        size: compact ? 23 : 26,
                      )
                    : Text(
                        '$selectedCount',
                        key: ValueKey(selectedCount),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 18 : 20,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalSelectionCard extends StatelessWidget {
  final bool compact;
  final int selectedCount;
  final int totalGoals;
  final Widget child;

  const _GoalSelectionCard({
    required this.compact,
    required this.selectedCount,
    required this.totalGoals,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCount > 0;
    final accent = isSelected ? NabiPalette.cyan : NabiPalette.violet;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            accent.withValues(alpha: 0.035),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isSelected ? 0.20 : 0.11),
          width: isSelected ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        child: Stack(
          children: [
            Positioned(
              right: -48,
              top: -54,
              child: Container(
                width: 146,
                height: 146,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GoalCardHeader(
                    accent: accent,
                    compact: compact,
                    selectedCount: selectedCount,
                    totalGoals: totalGoals,
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Text(
                    'Chọn tất cả những điều phù hợp. NaBi sẽ dùng mức ưu tiên này để xây dựng lịch ăn, vận động và nghỉ ngơi phù hợp hơn.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NabiPalette.mutedInk,
                      fontSize: compact ? 11.5 : null,
                      height: 1.42,
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 17),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(compact ? 9 : 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.035),
                      borderRadius: BorderRadius.circular(
                        compact ? 16 : 18,
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Semantics(
                      label: 'Danh sách mục tiêu sức khỏe có thể chọn nhiều mục',
                      child: child,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 14),
                  _SelectionStatus(
                    selectedCount: selectedCount,
                    compact: compact,
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

class _GoalCardHeader extends StatelessWidget {
  final Color accent;
  final bool compact;
  final int selectedCount;
  final int totalGoals;

  const _GoalCardHeader({
    required this.accent,
    required this.compact,
    required this.selectedCount,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 13 : 15),
            color: accent.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.flag_outlined,
            color: accent,
            size: compact ? 20 : 22,
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'MỤC TIÊU SỨC KHỎE',
                    style: TextStyle(
                      color: accent,
                      fontSize: compact ? 8.5 : 9.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.05,
                    ),
                  ),
                  _GoalCountBadge(
                    selectedCount: selectedCount,
                    totalGoals: totalGoals,
                    accent: accent,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Điều bạn muốn cải thiện',
                style: AppTextStyles.labelLarge.copyWith(
                  color: NabiPalette.ink,
                  fontSize: compact ? 14.5 : 15.5,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalCountBadge extends StatelessWidget {
  final int selectedCount;
  final int totalGoals;
  final Color accent;

  const _GoalCountBadge({
    required this.selectedCount,
    required this.totalGoals,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: hasSelection
            ? accent.withValues(alpha: 0.13)
            : NabiPalette.mutedInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Text(
          hasSelection
              ? '$selectedCount đã chọn'
              : '$totalGoals lựa chọn',
          key: ValueKey(selectedCount),
          style: TextStyle(
            color: hasSelection ? accent : NabiPalette.mutedInk,
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SelectionStatus extends StatelessWidget {
  final int selectedCount;
  final bool compact;

  const _SelectionStatus({
    required this.selectedCount,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final color = hasSelection ? NabiPalette.cyan : NabiPalette.amber;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 12,
        vertical: compact ? 10 : 11,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasSelection
                ? Icons.check_circle_outline_rounded
                : Icons.lightbulb_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                hasSelection
                    ? 'Tốt lắm. Các lựa chọn này sẽ được ưu tiên trong gợi ý đầu tiên của bạn.'
                    : 'Không cần chọn hết. Hãy bắt đầu với điều bạn muốn thay đổi nhiều nhất.',
                key: ValueKey(selectedCount > 0),
                style: AppTextStyles.bodySmall.copyWith(
                  color: NabiPalette.mutedInk,
                  height: 1.34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherGoalCard extends StatelessWidget {
  final bool compact;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _OtherGoalCard({
    required this.compact,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = initialValue.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 23),
        color: Colors.white,
        border: Border.all(
          color: hasText
              ? NabiPalette.rose.withValues(alpha: 0.20)
              : NabiPalette.rose.withValues(alpha: 0.11),
        ),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 39 : 43,
                height: compact ? 39 : 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 13 : 14),
                  color: NabiPalette.rose.withValues(alpha: 0.11),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: NabiPalette.rose,
                ),
              ),
              SizedBox(width: compact ? 10 : 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MỤC TIÊU KHÁC',
                      style: TextStyle(
                        color: NabiPalette.rose,
                        fontSize: compact ? 8.5 : 9.5,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Có điều gì NaBi chưa thấy?',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: NabiPalette.ink,
                        fontSize: compact ? 14.5 : 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            'Bạn có thể ghi thêm một mục tiêu riêng. Phần này hoàn toàn tùy chọn.',
            style: AppTextStyles.bodySmall.copyWith(
              color: NabiPalette.mutedInk,
              fontSize: compact ? 11.5 : null,
              height: 1.4,
            ),
          ),
          SizedBox(height: compact ? 13 : 15),
          OnboardingTextField(
            label: 'Ghi thêm mục tiêu',
            hint: 'Ví dụ: chuẩn bị cho giải chạy 5 km',
            initialValue: initialValue,
            maxLines: 2,
            prefixIcon: const Icon(Icons.edit_outlined),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _GoalGuidanceCard extends StatelessWidget {
  final bool compact;
  final int selectedCount;

  const _GoalGuidanceCard({
    required this.compact,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 23),
        color: NabiPalette.amber.withValues(alpha: 0.07),
        border: Border.all(
          color: NabiPalette.amber.withValues(alpha: 0.14),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 310;

          final icon = Container(
            width: compact ? 39 : 43,
            height: compact ? 39 : 43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.amber.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.tips_and_updates_outlined,
              color: NabiPalette.amber,
              size: 21,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSelection ? 'Bạn đang đi đúng hướng' : 'Một gợi ý nhỏ',
                style: AppTextStyles.labelLarge.copyWith(
                  color: NabiPalette.ink,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasSelection
                    ? 'Ưu tiên 1–3 mục tiêu chính giúp lịch trình dễ duy trì hơn và ít tạo áp lực.'
                    : 'Hãy ưu tiên điều ảnh hưởng nhiều nhất đến sức khỏe và cuộc sống hằng ngày của bạn.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: NabiPalette.mutedInk,
                  height: 1.4,
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 10),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
