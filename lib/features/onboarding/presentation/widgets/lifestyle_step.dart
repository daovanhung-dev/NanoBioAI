import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_chip.dart';
import 'onboarding_step_shell.dart';

class LifestyleStep extends ConsumerWidget {
  const LifestyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 4,
      title: 'Thói quen ăn uống & sinh hoạt',
      subtitle: 'Phần này giúp BioAI hiểu cách bạn đang sống mỗi ngày.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thói quen ăn uống',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: OnboardingCatalog.habits.map((item) {
              return OnboardingChip(
                label: item.label,
                emoji: item.emoji,
                selected: state.habits.contains(item.code),
                onTap: () => controller.toggleHabit(item.code),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: state.sleepQuality,
            decoration: const InputDecoration(labelText: 'Giấc ngủ hiện tại'),
            items: OnboardingCatalog.sleepQualities
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateSleepQuality(value);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: state.activityLevel,
            decoration: const InputDecoration(labelText: 'Mức độ vận động'),
            items: OnboardingCatalog.activityLevels
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateActivityLevel(value);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: state.waterPerDay,
            decoration: const InputDecoration(labelText: 'Lượng nước mỗi ngày'),
            items: OnboardingCatalog.waterIntakeOptions
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateWaterPerDay(value);
            },
          ),
        ],
      ),
    );
  }
}
