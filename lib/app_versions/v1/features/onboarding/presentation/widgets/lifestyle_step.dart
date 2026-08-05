import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

import 'package:nano_app/core/theme/app_spacing.dart';
import 'package:nano_app/core/theme/app_radius.dart';
class LifestyleStep extends ConsumerWidget {
  const LifestyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 4,
      title: 'Nhịp sống của bạn',
      subtitle: 'Chọn điều gần nhất với hôm nay.',
      mood: NabiOnboardingMood.lifestyle,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Thói quen hiện tại',
            icon: Icons.spa_rounded,
            accent: NabiPalette.greenPrimary,
            selectedCount: state.habits.length,
            trailing: state.habits.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Bỏ chọn tất cả',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      for (final code in [...state.habits]) {
                        controller.toggleHabit(code);
                      }
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    color: NabiPalette.greenDeep,
                  ),
            child: OnboardingChoiceGrid(
              options: OnboardingCatalog.habits,
              selectedCodes: state.habits,
              multiSelect: true,
              onSelected: controller.toggleHabit,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Một ngày thường',
            icon: Icons.wb_sunny_rounded,
            accent: NabiPalette.energyYellow,
            child: Column(
              children: [
                _LifestylePicker(
                  color: NabiPalette.personalPurple,
                  child: OnboardingChoicePickerField(
                    label: 'Giấc ngủ',
                    hint: 'Chọn mô tả',
                    icon: Icons.bedtime_rounded,
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
                ),
                const SizedBox(height: AppSpacing.sm),
                _LifestylePicker(
                  color: NabiPalette.careCoral,
                  child: OnboardingChoicePickerField(
                    label: 'Vận động',
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
                ),
                const SizedBox(height: AppSpacing.sm),
                _LifestylePicker(
                  color: NabiPalette.calmBlue,
                  child: OnboardingChoicePickerField(
                    label: 'Nước uống',
                    hint: 'Chọn ước lượng',
                    icon: Icons.water_drop_rounded,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const NabiAssistantMessage(
            message: 'Không cần ngày nào cũng giống nhau',
            icon: Icons.favorite_outline_rounded,
            accent: NabiPalette.careCoral,
          ),
        ],
      ),
    );
  }
}

class _LifestylePicker extends StatelessWidget {
  final Color color;
  final Widget child;

  const _LifestylePicker({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}
