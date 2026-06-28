import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ExtrasStep extends ConsumerWidget {
  const ExtrasStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 5,
      title: 'Thông tin để NaBi chăm sóc kỹ hơn',
      subtitle:
          'Các mục này không bắt buộc. Bạn chỉ cần chọn phần nào bạn muốn chia sẻ.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Dị ứng hoặc thực phẩm cần tránh',
            subtitle: '25 lựa chọn trong danh sách; có thể để trống.',
            child: Column(
              children: [
                _Picker(
                  label: 'Dị ứng / hạn chế thực phẩm',
                  hint: 'Không / chưa rõ',
                  icon: Icons.no_food_outlined,
                  options: OnboardingOptions.allergyChoices,
                  value: state.allergyName,
                  onChanged: controller.updateAllergyName,
                ),
                const SizedBox(height: 10),
                OnboardingTextField(
                  label: 'Ghi chú dị ứng (nếu có)',
                  hint: 'Ví dụ: phản ứng khi ăn nhiều hải sản',
                  initialValue: state.allergyNote,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  onChanged: controller.updateAllergyNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Theo dõi sức khỏe & thuốc',
            subtitle:
                'Chỉ dùng để điều chỉnh gợi ý, không thay thế tư vấn y tế.',
            child: Column(
              children: [
                _Picker(
                  label: 'Bạn đang theo dõi / điều trị gì?',
                  hint: 'Không điều trị hiện tại',
                  icon: Icons.medical_information_outlined,
                  options: OnboardingOptions.treatmentChoices,
                  value: state.treatmentName,
                  onChanged: controller.updateTreatmentName,
                ),
                const SizedBox(height: 10),
                _Picker(
                  label: 'Thuốc hoặc sản phẩm đang dùng',
                  hint: 'Không dùng thường xuyên',
                  icon: Icons.medication_outlined,
                  options: OnboardingOptions.medicationChoices,
                  value: state.medicationName,
                  onChanged: controller.updateMedicationName,
                ),
                const SizedBox(height: 10),
                OnboardingTextField(
                  label: 'Ghi chú điều trị (nếu có)',
                  hint: 'Ví dụ: dùng theo chỉ định vào buổi tối',
                  initialValue: state.treatmentNote,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.notes_rounded),
                  onChanged: controller.updateTreatmentNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Điều bạn đang quan tâm',
            subtitle: 'NaBi sẽ đặt ưu tiên này vào các gợi ý đầu tiên.',
            child: _Picker(
              label: 'Mối quan tâm hiện tại',
              hint: 'Chưa có băn khoăn cụ thể',
              icon: Icons.favorite_outline_rounded,
              options: OnboardingOptions.concernChoices,
              value: state.concernText,
              onChanged: controller.updateConcernText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<OnboardingChoiceOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _Picker({
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final typedOptions = options;
    final selectedCode = OnboardingOptions.codeForLabel(typedOptions, value);

    return OnboardingChoicePickerField(
      label: label,
      hint: hint,
      icon: icon,
      options: typedOptions,
      selectedCode: selectedCode,
      onSelected: (code) {
        if (code == 'none') {
          onChanged('');
          return;
        }
        onChanged(OnboardingOptions.labelFor(typedOptions, code));
      },
    );
  }
}
