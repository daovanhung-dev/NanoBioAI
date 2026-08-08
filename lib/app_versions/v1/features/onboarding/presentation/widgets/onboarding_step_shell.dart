import 'package:flutter/material.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Shared Green Wellness frame for every onboarding step.
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
        ),
        Expanded(
          child: _StepBody(
            title: title,
            subtitle: subtitle,
            mood: _resolvedMood,
            nabiMessage: nabiMessage,
            showCompanion: showCompanion,
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

  const _WellnessTopBar({
    required this.stepIndex,
    required this.totalSteps,
    required this.showBack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final progress = ((stepIndex + 1) / totalSteps).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: showBack
                ? IconButton(
                    tooltip: 'Quay lại',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: colors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface.withValues(alpha: 0.92),
                      side: BorderSide(color: colors.border),
                      shadowColor: colors.primary.withValues(alpha: 0.14),
                      elevation: 2,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    NabiMoodPill(
                      icon: Icons.eco_rounded,
                      label: '${stepIndex + 1}/$totalSteps',
                    ),
                    const Spacer(),
                    Text(
                      stepIndex + 1 == totalSteps
                          ? 'Sắp xong'
                          : 'Hồ sơ của bạn',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: nabiReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 480),
                  curve: Curves.easeOutBack,
                  builder: (context, value, _) => _LeafProgress(
                    value: value,
                    totalSteps: totalSteps,
                    currentStep: stepIndex,
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

class _LeafProgress extends StatelessWidget {
  final double value;
  final int totalSteps;
  final int currentStep;

  const _LeafProgress({
    required this.value,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return SizedBox(
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: NabiPalette.button,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: NabiPalette.greenBright.withValues(alpha: 0.30),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 0; index < totalSteps; index++)
                AnimatedContainer(
                  duration: AppDuration.ripple,
                  width: index == currentStep ? 14 : 10,
                  height: index == currentStep ? 14 : 10,
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? NabiPalette.greenPrimary
                        : colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: index <= currentStep
                          ? NabiPalette.greenPrimary
                          : colors.border,
                      width: 1.5,
                    ),
                    boxShadow: index == currentStep
                        ? [
                            BoxShadow(
                              color: NabiPalette.greenPrimary.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : const [],
                  ),
                  child: index < currentStep
                      ? const Icon(
                          Icons.check_rounded,
                          size: 7,
                          color: AppColors.textInverse,
                        )
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final NabiOnboardingMood mood;
  final String? nabiMessage;
  final bool showCompanion;
  final Widget child;
  final bool isScrollable;

  const _StepBody({
    required this.title,
    required this.subtitle,
    required this.mood,
    required this.nabiMessage,
    required this.showCompanion,
    required this.child,
    required this.isScrollable,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCompanion) ...[
          NabiStepHero(mood: mood, message: nabiMessage, compact: true),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -0.35,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionSpacing),
        child,
      ],
    );

    if (!isScrollable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: body,
      );
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: colors.divider)),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
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
