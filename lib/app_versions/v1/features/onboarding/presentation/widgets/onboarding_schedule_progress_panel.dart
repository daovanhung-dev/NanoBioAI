import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/shared/widgets/generated_plan_progress_panel.dart';

class OnboardingScheduleProgressPanel extends ConsumerWidget {
  const OnboardingScheduleProgressPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      onboardingProvider.select((state) => state.initialPlanProgress),
    );
    return GeneratedPlanProgressPanel(progress: progress);
  }
}
