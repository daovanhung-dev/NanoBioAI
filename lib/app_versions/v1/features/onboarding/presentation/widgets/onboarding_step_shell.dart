import 'package:flutter/material.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Shared visual frame for the whole NaBi onboarding journey.
///
/// Each step keeps the same navigation, progress feedback and primary action
/// while individual pages only provide their data-entry content.
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
  final bool isScrollable;
  final bool safeArea;

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
    this.isScrollable = true,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((stepIndex + 1) / totalSteps).clamp(0.0, 1.0).toDouble();
    final page = Column(
      children: [
        _TopBar(
          stepIndex: stepIndex,
          totalSteps: totalSteps,
          progress: progress,
          showBack: showBack,
          onBack: onBack,
        ),
        Expanded(
          child: isScrollable
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  child: _Content(
                    title: title,
                    subtitle: subtitle,
                    child: child,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  child: _Content(
                    title: title,
                    subtitle: subtitle,
                    child: child,
                  ),
                ),
        ),
        if (footer != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 7, 18, 14),
              child: footer!,
            ),
          )
        else if (onNext != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 7, 18, 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: NabiPrimaryButton(
                  onPressed: onNext,
                  label: nextLabel ?? 'Tiếp tục cùng NaBi',
                ),
              ),
            ),
          ),
      ],
    );

    return safeArea ? SafeArea(child: page) : page;
  }
}

class _Content extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Content({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.trim().isNotEmpty) ...[
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    NabiPalette.hero.createShader(bounds),
                child: Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.42,
                  ),
                ),
              ],
              const SizedBox(height: 15),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final double progress;
  final bool showBack;
  final VoidCallback? onBack;

  const _TopBar({
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
    required this.showBack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: NabiGlassPanel(
            elevated: false,
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.82),
                const Color(0xFFF5FAFF).withValues(alpha: 0.82),
              ],
            ),
            child: Row(
              children: [
                _BackButton(showBack: showBack, onBack: onBack),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'HỒ SƠ CÙNG NaBi',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: NabiPalette.deepBlue,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.55,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: NabiPalette.cyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'đang cá nhân hoá',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: NabiPalette.mutedInk,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0, end: progress),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: NabiPalette.line,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  NabiPalette.royalBlue,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: NabiPalette.royalBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    '${stepIndex + 1}/$totalSteps',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: NabiPalette.deepBlue,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const NabiCompanionAvatar(size: 31, showStatus: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const _BackButton({required this.showBack, required this.onBack});

  @override
  Widget build(BuildContext context) {
    if (!showBack) {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          gradient: NabiPalette.button,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 19,
        ),
      );
    }

    return Material(
      color: NabiPalette.royalBlue.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: NabiPalette.deepBlue,
          ),
        ),
      ),
    );
  }
}
