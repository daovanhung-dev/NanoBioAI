import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import '../../providers/onboarding_provider.dart';
import '../constants/gender_options.dart';
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
      title: 'Để Nabi hiểu bạn',
      subtitle: 'Thông tin gần đúng là đủ.',
      mood: NabiOnboardingMood.guide,
      onBack: controller.previousStep,
      onNext: state.canContinueBasicInfo ? controller.nextStep : null,
      child: OnboardingRevealColumn(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: colors.secondaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Để Nabi hiểu bạn',
                        style: AppTextStyles.heading5.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thông tin gần đúng là đủ.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Thông tin chính'),
          const SizedBox(height: AppSpacing.sm),
          OnboardingTextField(
            label: 'Họ và tên *',
            hint: 'Nhập họ và tên',
            initialValue: state.fullName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: controller.updateFullName,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SectionLabel(title: 'Giới tính *'),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (
                var index = 0;
                index < onboardingGenderOptions.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GenderChoice(
                    option: onboardingGenderOptions[index],
                    selected:
                        state.gender == onboardingGenderOptions[index].code,
                    onTap: () => controller.updateGender(
                      onboardingGenderOptions[index].code,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _BirthYearField(
            value: state.birthYear,
            onChanged: (year) => controller.updateBirthYear(year.toString()),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingChoicePickerField(
            label: 'Công việc / sinh hoạt *',
            hint: 'Chọn nhóm gần đúng',
            icon: Icons.work_outline_rounded,
            options: occupations,
            selectedCode: state.occupation,
            onSelected: controller.updateOccupation,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Thể trạng'),
          const SizedBox(height: AppSpacing.sm),
          _ResponsivePair(
            first: OnboardingTextField(
              label: 'Chiều cao (cm) *',
              hint: 'Nhập chiều cao',
              initialValue: state.heightCm > 0
                  ? state.heightCm.toStringAsFixed(0)
                  : '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(widthFactor: 1, child: Text('cm')),
              ),
              onChanged: controller.updateHeight,
            ),
            second: OnboardingTextField(
              label: 'Cân nặng (kg) *',
              hint: 'Nhập cân nặng',
              initialValue: state.weightKg > 0
                  ? state.weightKg.toStringAsFixed(1)
                  : '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(widthFactor: 1, child: Text('kg')),
              ),
              onChanged: controller.updateWeight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _BmiInsight(value: state.bmi),
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
        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2) {
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: nabiReducedMotion(context)
                ? Duration.zero
                : AppDuration.tap,
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? colors.primary : colors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option.code == 'male' ? Icons.male : Icons.female,
                  size: 19,
                  color: selected ? colors.onBrand : colors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: selected ? colors.onBrand : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          initialValue: years.contains(value) ? value : null,
          isExpanded: true,
          hint: const Text('Nhập năm sinh'),
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
