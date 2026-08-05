import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

import 'package:nano_app/core/theme/app_spacing.dart';
class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 2,
      title: 'Điều bạn muốn cải thiện',
      subtitle: 'Chọn một hoặc nhiều mục tiêu.',
      mood: NabiOnboardingMood.goal,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Mục tiêu của bạn',
            icon: Icons.flag_rounded,
            accent: NabiPalette.energyYellow,
            selectedCount: state.goals.length,
            trailing: state.goals.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Bỏ chọn tất cả',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      for (final code in [...state.goals]) {
                        controller.toggleGoal(code);
                      }
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    color: NabiPalette.greenDeep,
                  ),
            child: OnboardingChoiceGrid(
              options: OnboardingCatalog.goals,
              selectedCodes: state.goals,
              multiSelect: true,
              onSelected: controller.toggleGoal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Mục tiêu khác',
            icon: Icons.edit_note_rounded,
            accent: NabiPalette.personalPurple,
            child: OnboardingTextField(
              label: 'Tùy chọn',
              hint: 'Ví dụ: ngủ sớm hơn',
              initialValue: state.otherGoal,
              maxLines: 2,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              onChanged: controller.updateOtherGoal,
            ),
          ),
          if (state.goals.isNotEmpty || state.otherGoal.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            NabiAssistantMessage(
              message: state.goals.length <= 1
                  ? 'Mình đã ghi lại mục tiêu'
                  : 'Mình đã ghi ${state.goals.length} mục tiêu',
              icon: Icons.check_circle_rounded,
              accent: NabiPalette.greenPrimary,
            ),
          ],
        ],
      ),
    );
  }
}
