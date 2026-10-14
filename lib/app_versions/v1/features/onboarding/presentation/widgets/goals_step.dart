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
      title: 'Điều bạn muốn cải thiện',
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
                'Mỗi bước khởi đầu nhỏ đều có ý nghĩa. Hãy chọn điều bạn muốn chăm sóc trước nhé.',
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.semanticColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: context.semanticColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tùy biến lộ trình cá nhân',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.semanticColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const OnboardingScreenHeading(
            title: 'Điều bạn muốn cải thiện',
            subtitle:
                'Bạn có thể chọn một hoặc nhiều mục tiêu quan trọng nhất với mình hiện tại.',
            bottomSpacing: AppSpacing.md,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Danh sách mục tiêu',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.semanticColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
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
