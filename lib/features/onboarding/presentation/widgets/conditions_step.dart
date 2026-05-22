import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_chip.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ConditionsStep extends ConsumerWidget {
  const ConditionsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 3,
      title: 'Tình trạng sức khỏe hiện tại',
      subtitle:
          'Chọn đúng các vấn đề bạn đang gặp để BioAI hiểu cơ thể bạn tốt hơn.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: OnboardingCatalog.conditions.map((item) {
              return OnboardingChip(
                label: item.label,
                emoji: item.emoji,
                selected: state.conditions.contains(item.code),
                onTap: () => controller.toggleCondition(item.code),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          OnboardingTextField(
            label: 'Tình trạng khác',
            hint: 'Nếu có tình trạng khác',
            initialValue: state.otherCondition,
            onChanged: controller.updateOtherCondition,
          ),
        ],
      ),
    );
  }
}
