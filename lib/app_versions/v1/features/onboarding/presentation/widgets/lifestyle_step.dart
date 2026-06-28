import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

class LifestyleStep extends ConsumerWidget {
  const LifestyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 4,
      title: 'Nhịp sống hằng ngày',
      subtitle:
          'Chọn các thói quen thật nhất với bạn. Không có đáp án đúng hay sai.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Thói quen ăn uống & sinh hoạt',
            subtitle: '25 lựa chọn, gồm cả thói quen bạn đã duy trì tốt.',
            selectedCount: state.habits.length,
            child: OnboardingChoiceGrid(
              options: OnboardingCatalog.habits,
              selectedCodes: state.habits,
              multiSelect: true,
              onSelected: controller.toggleHabit,
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Ba tín hiệu cơ bản',
            subtitle: 'Các lựa chọn đơn sẽ dùng chung một kiểu chọn.',
            child: Column(
              children: [
                OnboardingChoicePickerField(
                  label: 'Giấc ngủ gần đây',
                  hint: 'Chọn mô tả',
                  icon: Icons.bedtime_outlined,
                  options: OnboardingOptions.sleepQualityChoices,
                  selectedCode: OnboardingOptions.codeForLabel(
                    OnboardingOptions.sleepQualityChoices,
                    state.sleepQuality,
                  ),
                  onSelected: (code) => controller.updateSleepQuality(
                    OnboardingCatalog.labelOf(
                      OnboardingOptions.sleepQualityChoices,
                      code,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OnboardingChoicePickerField(
                  label: 'Mức độ vận động',
                  hint: 'Chọn mức độ',
                  icon: Icons.directions_walk_rounded,
                  options: OnboardingOptions.activityChoices,
                  selectedCode: OnboardingOptions.codeForLabel(
                    OnboardingOptions.activityChoices,
                    state.activityLevel,
                  ),
                  onSelected: (code) => controller.updateActivityLevel(
                    OnboardingCatalog.labelOf(
                      OnboardingOptions.activityChoices,
                      code,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OnboardingChoicePickerField(
                  label: 'Nước uống mỗi ngày',
                  hint: 'Chọn ước lượng',
                  icon: Icons.water_drop_outlined,
                  options: OnboardingOptions.waterChoices,
                  selectedCode: OnboardingOptions.codeForLabel(
                    OnboardingOptions.waterChoices,
                    state.waterPerDay,
                  ),
                  onSelected: (code) => controller.updateWaterPerDay(
                    OnboardingCatalog.labelOf(
                      OnboardingOptions.waterChoices,
                      code,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
