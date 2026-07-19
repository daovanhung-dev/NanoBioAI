import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../daily_routine/presentation/widgets/daily_routine_preferences_editor.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class DailyRoutineStep extends ConsumerWidget {
  const DailyRoutineStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final errors = state.routinePreferences.validate();
    return OnboardingStepShell(
      stepIndex: 6,
      title: 'Khung giờ thường ngày',
      subtitle:
          'Chọn giờ để NaBi sắp lịch phù hợp.',
      onBack: controller.previousStep,
      footer: FilledButton.icon(
        onPressed: errors.isEmpty ? controller.confirmRoutineAndContinue : null,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Xác nhận khung giờ'),
      ),
      child: Column(
        children: [
          if (errors.isNotEmpty) ...[
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(errors.first),
              ),
            ),
            const SizedBox(height: 12),
          ],
          DailyRoutinePreferencesEditor(
            value: state.routinePreferences,
            onChanged: controller.updateRoutinePreferences,
          ),
        ],
      ),
    );
  }
}
