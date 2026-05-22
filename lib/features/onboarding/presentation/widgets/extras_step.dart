import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/onboarding_controller.dart';
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
      title: 'Thông tin bổ sung',
      subtitle: 'Những thông tin này giúp BioAI tạo hồ sơ đầy đủ hơn cho bạn.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingTextField(
            label: 'Dị ứng hoặc kiêng thực phẩm',
            hint: 'Ví dụ: hải sản, sữa, đậu phộng...',
            initialValue: state.allergyName,
            onChanged: controller.updateAllergyName,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Ghi chú dị ứng',
            hint: 'Nếu có thêm mô tả',
            initialValue: state.allergyNote,
            onChanged: controller.updateAllergyNote,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Đang điều trị / thuốc đang dùng',
            hint: 'Nếu không có, để trống',
            initialValue: state.treatmentName,
            onChanged: controller.updateTreatmentName,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Tên thuốc',
            hint: 'Nếu có',
            initialValue: state.medicationName,
            onChanged: controller.updateMedicationName,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Ghi chú điều trị',
            hint: 'Ví dụ: đang theo dõi bác sĩ...',
            initialValue: state.treatmentNote,
            maxLines: 3,
            onChanged: controller.updateTreatmentNote,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Điều bạn lo lắng nhất về sức khỏe',
            hint: 'Chia sẻ ngắn gọn',
            initialValue: state.concernText,
            maxLines: 3,
            onChanged: controller.updateConcernText,
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state.agreed,
            onChanged: controller.setAgreed,
            title: const Text('Tôi đồng ý với cam kết đồng hành'),
            subtitle: const Text(
              'Sức khỏe được cải thiện nhờ thay đổi thói quen và sự kiên trì mỗi ngày.',
            ),
          ),
        ],
      ),
    );
  }
}
