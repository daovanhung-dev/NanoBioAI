import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final c = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 2,
      title: 'Bạn muốn cải thiện điều gì?',
      subtitle: 'Chọn những mục tiêu ưu tiên; có thể chọn nhiều mục.',
      onBack: c.previousStep,
      onNext: c.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Mục tiêu sức khỏe',
            subtitle: '25 lựa chọn, chọn tất cả điều phù hợp.',
            selectedCount: state.goals.length,
            child: OnboardingChoiceGrid(
              options: OnboardingCatalog.goals,
              selectedCodes: state.goals,
              multiSelect: true,
              onSelected: c.toggleGoal,
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Mục tiêu khác',
            subtitle: 'Không thấy điều bạn cần?',
            child: OnboardingTextField(
              label: 'Ghi thêm mục tiêu',
              hint: 'Ví dụ: chuẩn bị cho giải chạy 5 km',
              initialValue: state.otherGoal,
              onChanged: c.updateOtherGoal,
              maxLines: 2,
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
