import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final colors = context.semanticColors;
    return OnboardingStepShell(
      stepIndex: 1,
      title: 'Để NaBi hiểu bạn',
      subtitle: 'Thông tin gần đúng là đủ.',
      mood: NabiOnboardingMood.guide,
      onBack: controller.previousStep,
      onNext: state.canContinueBasicInfo ? controller.nextStep : null,
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Thông tin chính',
            icon: Icons.person_rounded,
            accent: NabiPalette.greenPrimary,
            child: Column(
              children: [
                OnboardingTextField(
                  label: 'Họ và tên *',
                  hint: 'Nguyễn Minh Anh',
                  initialValue: state.fullName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  onChanged: controller.updateFullName,
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Giới tính *',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingChoiceGrid(
                  options: genders,
                  selectedCodes: state.gender.isEmpty
                      ? const []
                      : [state.gender],
                  onSelected: controller.updateGender,
                  multiSelect: false,
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _ResponsivePair(
                  first: _BirthYearField(
                    value: state.birthYear,
                    onChanged: (year) =>
                        controller.updateBirthYear(year.toString()),
                  ),
                  second: OnboardingChoicePickerField(
                    label: 'Công việc / sinh hoạt *',
                    hint: 'Chọn nhóm gần đúng',
                    icon: Icons.work_outline_rounded,
                    options: occupations,
                    selectedCode: state.occupation,
                    onSelected: controller.updateOccupation,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Thể trạng',
            icon: Icons.monitor_heart_rounded,
            accent: NabiPalette.calmBlue,
            child: Column(
              children: [
                _ResponsivePair(
                  first: OnboardingTextField(
                    label: 'Chiều cao (cm)',
                    hint: '170',
                    initialValue: state.heightCm > 0
                        ? state.heightCm.toStringAsFixed(0)
                        : '',
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
                    initialValue: state.weightKg > 0
                        ? state.weightKg.toStringAsFixed(1)
                        : '',
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
                const SizedBox(height: AppSpacing.sm),
                _BmiInsight(value: state.bmi),
              ],
            ),
          ),
          if (!state.canContinueBasicInfo) ...[
            const SizedBox(height: AppSpacing.sm),
            const OnboardingInlineInfo(
              icon: Icons.info_outline_rounded,
              text: 'Hoàn thành các mục có dấu * để tiếp tục.',
              color: NabiPalette.warning,
            ),
          ],
        ],
      ),
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
        if (constraints.maxWidth < 540) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.sm),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: second),
          ],
        );
      },
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
    final effective = years.contains(value) ? value : years.first;
    final colors = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Năm sinh *',
          style: AppTextStyles.labelMedium.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<int>(
          initialValue: effective,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: NabiPalette.greenPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.cake_outlined, size: 20),
            filled: true,
            fillColor: colors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(
                color: NabiPalette.greenPrimary,
                width: 1.5,
              ),
            ),
          ),
          items: years
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
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
}

class _BmiInsight extends StatelessWidget {
  final double value;

  const _BmiInsight({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final label = value <= 0
        ? 'Chưa đủ dữ liệu'
        : value < 18.5
        ? 'Hơi thấp'
        : value < 25
        ? 'Trong khoảng tham khảo'
        : value < 30
        ? 'Hơi cao'
        : 'Cao';
    final progress = value <= 0 ? 0.0 : (value / 40).clamp(0.0, 1.0).toDouble();
    final color = value <= 0
        ? colors.textMuted
        : value >= 18.5 && value < 25
        ? NabiPalette.greenPrimary
        : NabiPalette.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.10), colors.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.insights_rounded, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value > 0 ? 'BMI ${value.toStringAsFixed(1)}' : 'BMI',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.primarySubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
