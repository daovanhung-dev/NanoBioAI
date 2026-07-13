import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/theme/medical_ui.dart';

import '../widgets/basic_info_step.dart';
import '../widgets/consent_step.dart';
import '../widgets/conditions_step.dart';
import '../widgets/extras_step.dart';
import '../widgets/goals_step.dart';
import '../widgets/lifestyle_step.dart';
import '../widgets/nabi_onboarding_experience.dart';
import '../widgets/review_step.dart';
import '../widgets/welcome_step.dart';

class OnboardingPage extends ConsumerWidget {
  static const _tag = 'ONBOARDING_PAGE';

  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    AppLogger.info(
      _tag,
      'Rendering step ${state.currentStep + 1}/${OnboardingCatalog.totalSteps}',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || state.currentStep <= 0) return;
        ref.read(onboardingProvider.notifier).previousStep();
      },
      child: MedicalPageScaffold(
        ambientBackground: false,
        backgroundColor: Colors.transparent,
        body: NabiAmbientBackground(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            reverseDuration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.035, 0.018),
                end: Offset.zero,
              ).animate(animation);
              final scale = Tween<double>(
                begin: 0.985,
                end: 1,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slide,
                  child: ScaleTransition(scale: scale, child: child),
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(state.currentStep),
              child: switch (state.currentStep) {
                0 => const WelcomeStep(),
                1 => const BasicInfoStep(),
                2 => const GoalsStep(),
                3 => const ConditionsStep(),
                4 => const LifestyleStep(),
                5 => const ExtrasStep(),
                6 => const ConsentStep(),
                _ => const ReviewStep(),
              },
            ),
          ),
        ),
      ),
    );
  }
}
