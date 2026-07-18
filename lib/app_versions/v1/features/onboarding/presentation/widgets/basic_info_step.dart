import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart'
    as onboarding_catalog;
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';

import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class BasicInfoStep extends ConsumerWidget {
  const BasicInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final bmi = _BmiReading.from(
      heightCm: state.heightCm,
      weightKg: state.weightKg,
    );

    return OnboardingStepShell(
      stepIndex: 1,
      title: 'Một vài thông tin cơ bản',
      subtitle: 'Chọn gần đúng để NaBi gợi ý phù hợp hơn.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _BasicInfoLayout.fromWidth(constraints.maxWidth);

          final bodyMetricsCard = _SectionCard(
            accentColor: NabiPalette.cyan,
            icon: Icons.monitor_heart_outlined,
            eyebrow: 'THỂ TRẠNG HIỆN TẠI',
            title: 'Cơ thể bạn đang ở đâu?',
            subtitle:
                'Bạn có thể nhập gần đúng. BMI chỉ là chỉ số tham khảo ban đầu.',
            compact: layout.isCompact,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(layout.isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: NabiPalette.cyan.withValues(alpha: 0.045),
                    borderRadius: BorderRadius.circular(
                      layout.isCompact ? 16 : 18,
                    ),
                    border: Border.all(
                      color: NabiPalette.cyan.withValues(alpha: 0.11),
                    ),
                  ),
                  child: _AdaptivePair(
                    minimumItemWidth: 170,
                    gap: layout.fieldGap,
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
                ),
                SizedBox(height: layout.innerGap),
                _BmiInsightCard(reading: bmi),
              ],
            ),
          );

          final lifestyleCard = _SectionCard(
            accentColor: NabiPalette.amber,
            icon: Icons.schedule_outlined,
            eyebrow: 'NHỊP SỐNG HẰNG NGÀY',
            title: 'Một ngày của bạn thường diễn ra thế nào?',
            subtitle:
                'NaBi sẽ dùng thông tin này để sắp xếp gợi ý vào những thời điểm phù hợp.',
            required: true,
            compact: layout.isCompact,
            child: Column(
              children: [
                OnboardingChoicePickerField(
                  label: 'Nhóm công việc / sinh hoạt *',
                  hint: 'Chọn nhóm gần đúng nhất',
                  icon: Icons.work_outline_rounded,
                  options: onboarding_catalog.occupations,
                  selectedCode: state.occupation,
                  onSelected: controller.updateOccupation,
                ),
                SizedBox(height: layout.innerGap),
                const _LifestyleHint(),
              ],
            ),
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: layout.sectionGap),

                  _SectionCard(
                    accentColor: NabiPalette.violet,
                    icon: Icons.person_outline_rounded,
                    eyebrow: 'HỒ SƠ CƠ BẢN',
                    title: 'Cho NaBi biết một chút về bạn',
                    subtitle:
                        'Các thông tin này giúp lộ trình được điều chỉnh sát hơn với thể trạng của bạn.',
                    required: true,
                    compact: layout.isCompact,
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
                        SizedBox(height: layout.innerGap),
                        _AdaptivePair(
                          minimumItemWidth: 170,
                          gap: layout.fieldGap,
                          first: _BirthYearField(
                            value: state.birthYear,
                            onChanged: (year) =>
                                controller.updateBirthYear(year.toString()),
                          ),
                          second: OnboardingChoicePickerField(
                            label: 'Giới tính *',
                            hint: 'Chọn giới tính',
                            icon: Icons.person_outline_rounded,
                            options: onboarding_catalog.genders,
                            selectedCode: state.gender,
                            onSelected: controller.updateGender,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: layout.sectionGap),

                  if (layout.showSideBySideCards)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 11, child: bodyMetricsCard),
                        SizedBox(width: layout.desktopCardGap),
                        Expanded(flex: 10, child: lifestyleCard),
                      ],
                    )
                  else ...[
                    bodyMetricsCard,
                    SizedBox(height: layout.sectionGap),
                    lifestyleCard,
                  ],

                  SizedBox(height: layout.sectionGap),

                  const _PrivacyInfoCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BasicInfoLayout {
  final bool isCompact;
  final bool showSideBySideCards;
  final double sectionGap;
  final double innerGap;
  final double fieldGap;
  final double desktopCardGap;

  const _BasicInfoLayout({
    required this.isCompact,
    required this.showSideBySideCards,
    required this.sectionGap,
    required this.innerGap,
    required this.fieldGap,
    required this.desktopCardGap,
  });

  factory _BasicInfoLayout.fromWidth(double width) {
    final isCompact = width < 380;

    return _BasicInfoLayout(
      isCompact: isCompact,
      showSideBySideCards: width >= 760,
      sectionGap: isCompact ? 12 : 16,
      innerGap: isCompact ? 12 : 14,
      fieldGap: isCompact ? 10 : 12,
      desktopCardGap: 16,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool required;
  final bool compact;
  final Widget child;

  const _SectionCard({
    required this.accentColor,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.compact,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 14.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, accentColor.withValues(alpha: 0.028)],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.11)),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        child: Stack(
          children: [
            Positioned(
              top: -54,
              right: -48,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: compact ? 40 : 44,
                        height: compact ? 40 : 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            compact ? 13 : 15,
                          ),
                          color: accentColor.withValues(alpha: 0.11),
                        ),
                        child: Icon(
                          icon,
                          color: accentColor,
                          size: compact ? 20 : 22,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 7,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  eyebrow,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: compact ? 8.5 : 9.5,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.05,
                                  ),
                                ),
                                if (required) const _RequiredBadge(),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: NabiPalette.ink,
                                fontSize: compact ? 14.5 : 15.5,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 9 : 11),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NabiPalette.mutedInk,
                      fontSize: compact ? 11.5 : null,
                      height: 1.42,
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 17),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: NabiPalette.rose.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'CẦN THIẾT',
        style: TextStyle(
          color: NabiPalette.rose,
          fontSize: 7.5,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}

class _AdaptivePair extends StatelessWidget {
  final Widget first;
  final Widget second;
  final double gap;
  final double minimumItemWidth;

  const _AdaptivePair({
    required this.first,
    required this.second,
    required this.gap,
    required this.minimumItemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final requiredWidth = minimumItemWidth * 2 + gap;
        final useRow = constraints.maxWidth >= requiredWidth;

        if (!useRow) {
          return Column(
            children: [
              first,
              SizedBox(height: gap),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            SizedBox(width: gap),
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
    final effectiveValue = years.contains(value) ? value : years.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: 'Năm sinh', required: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: effectiveValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: NabiPalette.mutedInk,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(
              Icons.cake_outlined,
              size: 20,
              color: NabiPalette.mutedInk,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.92),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: _border(NabiPalette.line),
            enabledBorder: _border(NabiPalette.line),
            focusedBorder: _border(NabiPalette.royalBlue, width: 1.6),
          ),
          items: years
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: NabiPalette.ink,
                      fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.labelMedium.copyWith(
          color: NabiPalette.mutedInk,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: NabiPalette.rose,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _BmiInsightCard extends StatelessWidget {
  final _BmiReading reading;

  const _BmiInsightCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(reading.displayValue),
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: reading.color.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: reading.color.withValues(alpha: 0.14)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 285;

            final icon = Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reading.color.withValues(alpha: 0.13),
              ),
              child: Icon(reading.icon, color: reading.color, size: 20),
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.hasValue
                      ? 'BMI tham khảo: ${reading.displayValue}'
                      : 'BMI tham khảo',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reading.message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.34,
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [icon, const SizedBox(height: 10), content],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 11),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LifestyleHint extends StatelessWidget {
  const _LifestyleHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: NabiPalette.amber.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: NabiPalette.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Không cần chọn hoàn toàn chính xác. Hãy chọn nhóm gần nhất với lịch sinh hoạt của bạn.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyInfoCard extends StatelessWidget {
  const _PrivacyInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NabiPalette.cyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NabiPalette.cyan.withValues(alpha: 0.13)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 300;

          final icon = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.cyan.withValues(alpha: 0.13),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: NabiPalette.cyan,
              size: 18,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin của bạn luôn thuộc về bạn',
                style: AppTextStyles.labelLarge.copyWith(
                  color: NabiPalette.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Dữ liệu chỉ dùng để cá nhân hóa. Bạn có thể đổi sau.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: NabiPalette.mutedInk,
                  height: 1.35,
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 10), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _BmiReading {
  final double? value;

  const _BmiReading._(this.value);

  factory _BmiReading.from({
    required double heightCm,
    required double weightKg,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      return const _BmiReading._(null);
    }

    final heightMeters = heightCm / 100;

    if (heightMeters <= 0) {
      return const _BmiReading._(null);
    }

    return _BmiReading._(weightKg / (heightMeters * heightMeters));
  }

  bool get hasValue => value != null;

  String get displayValue {
    if (value == null) return '--';
    return value!.toStringAsFixed(1);
  }

  Color get color {
    if (value == null) return NabiPalette.mutedInk;
    if (value! < 18.5) return NabiPalette.amber;
    if (value! <= 24.9) return NabiPalette.cyan;
    return NabiPalette.rose;
  }

  IconData get icon {
    if (value == null) return Icons.analytics_outlined;
    if (value! >= 18.5 && value! <= 24.9) {
      return Icons.check_circle_outline_rounded;
    }
    return Icons.insights_outlined;
  }

  String get message {
    if (value == null) {
      return 'Điền chiều cao và cân nặng để xem chỉ số tham khảo.';
    }

    if (value! < 18.5) {
      return 'Chỉ số hiện thấp hơn khoảng tham chiếu thông thường.';
    }

    if (value! <= 24.9) {
      return 'Chỉ số hiện nằm trong khoảng tham chiếu thông thường.';
    }

    return 'Chỉ số hiện cao hơn khoảng tham chiếu thông thường.';
  }
}
