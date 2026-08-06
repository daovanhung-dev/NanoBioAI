import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

import '../widgets/basic_info_step.dart';
import '../widgets/conditions_step.dart';
import '../widgets/consent_step.dart';
import '../widgets/daily_routine_step.dart';
import '../widgets/extras_step.dart';
import '../widgets/goals_step.dart';
import '../widgets/lifestyle_step.dart';
import '../widgets/nabi_onboarding_experience.dart';
import '../widgets/review_step.dart';
import '../widgets/welcome_step.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _tag = 'ONBOARDING_PAGE';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    AppLogger.info(
      _tag,
      'Rendering step ${state.currentStep + 1}/${OnboardingCatalog.totalSteps}',
    );
    final hasHistory = context.canPop();
    return PopScope(
      canPop: state.currentStep <= 0 && !state.isSaving && hasHistory,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || state.isSaving) return;
        if (state.currentStep > 0) {
          ref.read(onboardingProvider.notifier).previousStep();
          return;
        }
        context.go(V1RoutePaths.onboardingEntry);
      },
      child: MedicalPageScaffold(
        ambientBackground: false,
        backgroundColor: Colors.transparent,
        body: NabiAmbientBackground(
          child: AppDirectionalSwitcher(
            index: state.currentStep,
            duration: AppDuration.emphasized,
            child: KeyedSubtree(
              key: ValueKey(state.currentStep),
              child: switch (state.currentStep) {
                0 => const WelcomeStep(),
                1 => const BasicInfoStep(),
                2 => const GoalsStep(),
                3 => const ConditionsStep(),
                4 => const LifestyleStep(),
                5 => const ExtrasStep(),
                6 => const DailyRoutineStep(),
                7 => const ConsentStep(),
                _ => const ReviewStep(),
              },
            ),
          ),
        ),
      ),
    );
  }
}
