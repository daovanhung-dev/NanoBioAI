import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/onboarding/presentation/controllers/onboarding_controller.dart';


import '../widgets/basic_info_step.dart';
import '../widgets/conditions_step.dart';
import '../widgets/extras_step.dart';
import '../widgets/goals_step.dart';
import '../widgets/lifestyle_step.dart';
import '../widgets/review_step.dart';
import '../widgets/welcome_step.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: switch (state.currentStep) {
            0 => const WelcomeStep(),
            1 => const BasicInfoStep(),
            2 => const GoalsStep(),
            3 => const ConditionsStep(),
            4 => const LifestyleStep(),
            5 => const ExtrasStep(),
            _ => const ReviewStep(),
          },
        ),
      ),
    );
  }
}
