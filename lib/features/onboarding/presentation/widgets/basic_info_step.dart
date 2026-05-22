import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/onboarding_controller.dart';
import '../../../../core/constants/onboarding_constants.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class BasicInfoStep extends ConsumerWidget {
  const BasicInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 1,
      title: 'Thông tin cơ bản',
      subtitle:
          'Hãy nhập các thông tin nền tảng để BioAI tạo hồ sơ sức khỏe chính xác hơn.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingTextField(
            label: 'Email',
            hint: 'you@email.com',
            initialValue: state.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: controller.updateEmail,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Số điện thoại',
            hint: '09xxxxxxxx',
            initialValue: state.phone,
            keyboardType: TextInputType.phone,
            onChanged: controller.updatePhone,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Họ và tên',
            hint: 'Nhập họ tên của bạn',
            initialValue: state.fullName,
            onChanged: controller.updateFullName,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.gender.isEmpty ? null : state.gender,
            decoration: const InputDecoration(labelText: 'Giới tính'),
            items: OnboardingCatalog.genders
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.code,
                    child: Text('${item.emoji} ${item.label}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateGender(value);
            },
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Năm sinh',
            hint: '2000',
            initialValue: state.birthYear.toString(),
            keyboardType: TextInputType.number,
            onChanged: controller.updateBirthYear,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            label: 'Nghề nghiệp',
            hint: 'Sinh viên, nhân viên văn phòng...',
            initialValue: state.occupation,
            onChanged: controller.updateOccupation,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OnboardingTextField(
                  label: 'Chiều cao (cm)',
                  hint: '170',
                  initialValue: state.heightCm.toStringAsFixed(1),
                  keyboardType: TextInputType.number,
                  onChanged: controller.updateHeight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OnboardingTextField(
                  label: 'Cân nặng (kg)',
                  hint: '65',
                  initialValue: state.weightKg.toStringAsFixed(1),
                  keyboardType: TextInputType.number,
                  onChanged: controller.updateWeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
