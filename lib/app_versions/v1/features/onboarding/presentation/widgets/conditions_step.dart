import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ConditionsStep extends ConsumerWidget {
  const ConditionsStep({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final c = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 3,
      title: 'Cơ thể bạn đang cần lưu ý gì?',
      subtitle:
          'Chọn gần đúng để NaBi thận trọng hơn khi gợi ý. Đây không phải chẩn đoán.',
      onBack: c.previousStep,
      onNext: c.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Triệu chứng / tình trạng',
            subtitle:
                '“Không có vấn đề đặc biệt” sẽ tự thay thế các lựa chọn khác.',
            selectedCount: state.conditions.length,
            child: OnboardingChoiceGrid(
              options: OnboardingCatalog.conditions,
              selectedCodes: state.conditions,
              multiSelect: true,
              onSelected: c.toggleCondition,
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Thông tin cần lưu ý khác',
            child: OnboardingTextField(
              label: 'Ghi thêm nếu cần',
              hint: 'Ví dụ: bác sĩ dặn hạn chế đồ mặn',
              initialValue: state.otherCondition,
              onChanged: c.updateOtherCondition,
              maxLines: 2,
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
