import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

import 'package:nano_app/core/theme/app_spacing.dart';
class ExtrasStep extends ConsumerWidget {
  const ExtrasStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 5,
      title: 'Thông tin cần lưu ý',
      subtitle: 'Chỉ chọn những gì đúng với bạn.',
      mood: NabiOnboardingMood.thinking,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Dị ứng / cần tránh',
            icon: Icons.no_food_rounded,
            accent: NabiPalette.careCoral,
            selectedCount: _split(state.allergyName).length,
            child: Column(
              children: [
                OnboardingMultiChoicePickerField(
                  label: 'Thực phẩm hoặc thành phần',
                  hint: 'Chọn nhiều nếu cần',
                  icon: Icons.restaurant_rounded,
                  options: OnboardingOptions.allergyChoices,
                  selectedLabels: _split(state.allergyName),
                  onChanged: (values) =>
                      controller.updateAllergyName(_join(values)),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingTextField(
                  label: 'Ghi chú',
                  hint: 'Ví dụ: phản ứng khi ăn nhiều',
                  initialValue: state.allergyNote,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  onChanged: controller.updateAllergyNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Đang theo dõi',
            icon: Icons.monitor_heart_rounded,
            accent: NabiPalette.calmBlue,
            selectedCount: _split(state.treatmentName).length,
            child: OnboardingMultiChoicePickerField(
              label: 'Tình trạng / điều trị',
              hint: 'Chọn nhiều nếu cần',
              icon: Icons.medical_information_rounded,
              options: OnboardingOptions.treatmentChoices,
              selectedLabels: _split(state.treatmentName),
              onChanged: (values) =>
                  controller.updateTreatmentName(_join(values)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Thuốc / sản phẩm',
            icon: Icons.medication_rounded,
            accent: NabiPalette.personalPurple,
            selectedCount: _split(state.medicationName).length,
            child: Column(
              children: [
                OnboardingMultiChoicePickerField(
                  label: 'Đang sử dụng',
                  hint: 'Chọn nhiều nếu cần',
                  icon: Icons.medication_liquid_rounded,
                  options: OnboardingOptions.medicationChoices,
                  selectedLabels: _split(state.medicationName),
                  onChanged: (values) =>
                      controller.updateMedicationName(_join(values)),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingTextField(
                  label: 'Ghi chú điều trị',
                  hint: 'Ví dụ: dùng theo chỉ định buổi tối',
                  initialValue: state.treatmentNote,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.notes_rounded),
                  onChanged: controller.updateTreatmentNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Bạn quan tâm nhất',
            icon: Icons.favorite_rounded,
            accent: NabiPalette.energyYellow,
            selectedCount: _split(state.concernText).length,
            child: OnboardingMultiChoicePickerField(
              label: 'Mối quan tâm',
              hint: 'Chọn nhiều nếu cần',
              icon: Icons.auto_awesome_rounded,
              options: OnboardingOptions.concernChoices,
              selectedLabels: _split(state.concernText),
              onChanged: (values) =>
                  controller.updateConcernText(_join(values)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const OnboardingInlineInfo(
            icon: Icons.verified_user_rounded,
            text: 'NaBi dùng thông tin này để gợi ý phù hợp hơn.',
            color: NabiPalette.greenPrimary,
          ),
        ],
      ),
    );
  }

  static List<String> _split(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _join(List<String> values) => values.join(', ');
}
