import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
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
      title: 'Một vài thông tin cơ bản',
      subtitle:
          'Chỉ cần chọn gần đúng. NaBi dùng dữ liệu này để gợi ý phù hợp hơn.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Thông tin cá nhân',
            subtitle: 'Các mục có dấu * sẽ cần để tạo lịch trình.',
            child: Column(
              children: [
                OnboardingTextField(
                  label: 'Họ và tên *',
                  hint: 'Ví dụ: Nguyễn Minh Anh',
                  initialValue: state.fullName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  onChanged: controller.updateFullName,
                ),
                const SizedBox(height: 12),
                _ResponsivePair(
                  first: _BirthYearField(
                    value: state.birthYear,
                    onChanged: (year) =>
                        controller.updateBirthYear(year.toString()),
                  ),
                  second: OnboardingChoicePickerField(
                    label: 'Giới tính *',
                    hint: 'Chọn giới tính',
                    icon: Icons.person_outline_rounded,
                    options: OnboardingCatalog.genders,
                    selectedCode: state.gender,
                    onSelected: controller.updateGender,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Thể trạng hiện tại',
            subtitle: 'Bạn có thể ước lượng; NaBi sẽ tính BMI tự động.',
            child: _ResponsivePair(
              first: OnboardingTextField(
                label: 'Chiều cao (cm)',
                hint: '170',
                initialValue: state.heightCm.toStringAsFixed(0),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                prefixIcon: const Icon(Icons.height_rounded),
                onChanged: controller.updateHeight,
              ),
              second: OnboardingTextField(
                label: 'Cân nặng (kg)',
                hint: '65',
                initialValue: state.weightKg.toStringAsFixed(1),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                onChanged: controller.updateWeight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Nhịp sống thường ngày *',
            subtitle: 'Danh sách có 25 nhóm để bạn chọn nhanh.',
            child: OnboardingChoicePickerField(
              label: 'Nhóm công việc / sinh hoạt',
              hint: 'Chọn nhóm gần đúng nhất',
              icon: Icons.work_outline_rounded,
              options: OnboardingCatalog.occupations,
              selectedCode: state.occupation,
              onSelected: controller.updateOccupation,
            ),
          ),
          const SizedBox(height: 12),
          OnboardingInlineInfo(
            icon: Icons.lock_outline_rounded,
            text:
                'Thông tin chỉ dùng để cá nhân hóa hành trình sức khỏe; bạn có thể điều chỉnh sau.',
          ),
        ],
      ),
    );
  }
}

class _BirthYearField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _BirthYearField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final years = OnboardingOptions.birthYears;
    final effectiveValue = years.contains(value) ? value : years.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Năm sinh *',
          style: AppTextStyles.labelMedium.copyWith(
            color: NabiPalette.mutedInk,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<int>(
          value: effectiveValue,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(
              Icons.cake_outlined,
              size: 20,
              color: NabiPalette.mutedInk,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.88),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: _border(NabiPalette.line),
            enabledBorder: _border(NabiPalette.line),
            focusedBorder: _border(NabiPalette.royalBlue, width: 1.5),
          ),
          items: years
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: NabiPalette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (year) {
            if (year != null) onChanged(year);
          },
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsivePair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        if (!isWide) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }
        final width = (constraints.maxWidth - 10) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: width, child: first),
            const SizedBox(width: 10),
            SizedBox(width: width, child: second),
          ],
        );
      },
    );
  }
}
