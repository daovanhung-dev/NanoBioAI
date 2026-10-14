import 'package:flutter/material.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Shared Blue Wellness frame for every onboarding step.
class OnboardingStepShell extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool showBack;
  final bool showNextAction;
  final bool isScrollable;
  final bool safeArea;
  final NabiOnboardingMood? mood;
  final String? nabiMessage;
  final bool showCompanion;

  const OnboardingStepShell({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.totalSteps = OnboardingCatalog.totalSteps,
    this.footer,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.showBack = true,
    this.showNextAction = true,
    this.isScrollable = true,
    this.safeArea = true,
    this.mood,
    this.nabiMessage,
    this.showCompanion = true,
  });

  NabiOnboardingMood get _resolvedMood =>
      mood ??
      switch (stepIndex) {
        0 => NabiOnboardingMood.welcome,
        1 => NabiOnboardingMood.guide,
        2 => NabiOnboardingMood.goal,
        3 => NabiOnboardingMood.care,
        4 => NabiOnboardingMood.lifestyle,
        5 => NabiOnboardingMood.thinking,
        6 => NabiOnboardingMood.routine,
        7 => NabiOnboardingMood.consent,
        _ => NabiOnboardingMood.review,
      };

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _WellnessTopBar(
          stepIndex: stepIndex,
          totalSteps: totalSteps,
          showBack: showBack,
          onBack: onBack,
          mood: _resolvedMood,
          showCompanion: showCompanion,
        ),
        Expanded(
          child: _StepBody(
            title: title,
            subtitle: subtitle,
            nabiMessage: nabiMessage,
            isScrollable: isScrollable,
            child: child,
          ),
        ),
        if (footer != null || showNextAction)
          _BottomAction(footer: footer, onNext: onNext, nextLabel: nextLabel),
      ],
    );

    return safeArea ? SafeArea(child: content) : content;
  }
}

class _WellnessTopBar extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final bool showBack;
  final VoidCallback? onBack;
  final NabiOnboardingMood mood;
  final bool showCompanion;

  const _WellnessTopBar({
    required this.stepIndex,
    required this.totalSteps,
    required this.showBack,
    required this.onBack,
    required this.mood,
    required this.showCompanion,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    const labels = [
      'Khởi đầu',
      'Hồ sơ sức khỏe',
      'Mục tiêu sức khỏe',
      'Lưu ý sức khỏe',
      'Nhịp sống',
      'Thông tin bổ sung',
      'Nhịp sinh học',
      'Quyền riêng tư',
      'Xem lại hồ sơ',
    ];
    final label = stepIndex >= 0 && stepIndex < labels.length
        ? labels[stepIndex]
        : 'Hành trình của bạn';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: showBack
                ? IconButton.filledTonal(
                    key: const Key('onboarding_back'),
                    tooltip: 'Quay lại',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 19,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.card,
                      foregroundColor: colors.textPrimary,
                      padding: EdgeInsets.zero,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var index = 0; index < totalSteps; index++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: nabiReducedMotion(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          height: 4,
                          decoration: BoxDecoration(
                            color: index < stepIndex
                                ? colors.secondary
                                : index == stepIndex
                                ? colors.primary
                                : colors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      if (index != totalSteps - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Bước ${stepIndex + 1}/$totalSteps',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.circle,
                        size: 4,
                        color: colors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (showCompanion)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.secondarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  mood.assetPath,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  semanticLabel: 'Nabi',
                ),
              ),
            ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: colors.onBrand, size: 18),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? nabiMessage;
  final Widget child;
  final bool isScrollable;

  const _StepBody({
    required this.title,
    required this.subtitle,
    required this.nabiMessage,
    required this.child,
    required this.isScrollable,
  });

  @override
  Widget build(BuildContext context) {
    final body = Semantics(
      container: true,
      label: title,
      hint: nabiMessage ?? subtitle,
      child: child,
    );

    if (!isScrollable) {
      return Padding(padding: const EdgeInsets.all(16), child: body);
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final Widget? footer;
  final VoidCallback? onNext;
  final String? nextLabel;

  const _BottomAction({
    required this.footer,
    required this.onNext,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: AppDuration.button,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset > 0 ? 4 : 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: colors.divider)),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox(
              width: double.infinity,
              child:
                  footer ??
                  NabiPrimaryButton(
                    onPressed: onNext,
                    label: nextLabel ?? 'Tiếp tục',
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
