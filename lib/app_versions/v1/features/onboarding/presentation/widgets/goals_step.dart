import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_stitch_components.dart';
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
      title: 'Bạn muốn cải thiện điều gì?',
      subtitle: 'Chọn một hoặc nhiều mục tiêu.',
      mood: NabiOnboardingMood.goal,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: OnboardingRevealColumn(
        children: [
          const OnboardingNabiNote(
            mood: NabiOnboardingMood.goal,
            eyebrow: 'NABI ĐỒNG HÀNH',
            message:
                'Bạn muốn chăm sóc điều gì trước? Chọn mục tiêu phù hợp nhé.',
          ),
          const SizedBox(height: AppSpacing.md),
          const OnboardingScreenHeading(
            title: 'Bạn muốn cải thiện điều gì?',
            subtitle: 'Chọn điều phù hợp với bạn lúc này.',
            bottomSpacing: AppSpacing.md,
          ),
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.semanticColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  state.goals.isEmpty
                      ? 'Chưa chọn mục tiêu'
                      : '${state.goals.length} mục tiêu đã chọn',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.semanticColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingChoiceGrid(
            options: OnboardingCatalog.goals,
            selectedCodes: state.goals,
            multiSelect: true,
            onSelected: controller.toggleGoal,
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingStitchCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: OnboardingTextField(
              label: 'Mục tiêu khác (tùy chọn)',
              hint: 'Điều bạn muốn chia sẻ thêm',
              initialValue: state.otherGoal,
              maxLines: 2,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              onChanged: controller.updateOtherGoal,
            ),
          ),
        ],
      ),
    );
  }
}
