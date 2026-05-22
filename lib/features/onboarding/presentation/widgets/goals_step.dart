import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_chip.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 2,
      title: 'Mục tiêu sức khỏe',
      subtitle:
          'Chọn một hoặc nhiều mục tiêu để BioAI cá nhân hóa lộ trình phù hợp.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: OnboardingCatalog.goals.map((goal) {
              return OnboardingChip(
                label: goal.label,
                emoji: goal.emoji,
                selected: state.goals.contains(goal.code),
                onTap: () => controller.toggleGoal(goal.code),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          OnboardingTextField(
            label: 'Mục tiêu khác',
            hint: 'Nếu có thêm mục tiêu',
            initialValue: state.otherGoal,
            onChanged: controller.updateOtherGoal,
          ),
        ],
      ),
    );
  }
}
