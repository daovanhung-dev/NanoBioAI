import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart' show NabiPalette;
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ExtrasStep extends ConsumerStatefulWidget {
  const ExtrasStep({super.key});

  @override
  ConsumerState<ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends ConsumerState<ExtrasStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final hasAllergy =
        state.allergyName.trim().isNotEmpty || state.allergyNote.trim().isNotEmpty;

    final hasTreatment = state.treatmentName.trim().isNotEmpty ||
        state.medicationName.trim().isNotEmpty ||
        state.treatmentNote.trim().isNotEmpty;

    final hasConcern = state.concernText.trim().isNotEmpty;

    final completedSections = [
      hasAllergy,
      hasTreatment,
      hasConcern,
    ].where((item) => item).length;

    return OnboardingStepShell(
      stepIndex: 5,
      title: 'Chăm sóc kỹ hơn,\ntheo cách bạn muốn.',
      subtitle:
          'Mọi thông tin ở đây đều không bắt buộc. Bạn chỉ cần chia sẻ điều khiến bạn cảm thấy thoải mái.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Column(
            children: [
              _ExtrasHero(
                completedSections: completedSections,
                progress: _ambientController.value,
              ),
              const SizedBox(height: 14),

              _PrivacyNotice(
                completedSections: completedSections,
              ),
              const SizedBox(height: 14),

              _PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExtrasSectionHeader(
                      icon: Icons.no_food_outlined,
                      accent: NabiPalette.cyan,
                      title: 'Dị ứng hoặc thực phẩm cần tránh',
                      subtitle:
                          'Giúp NaBi hạn chế những gợi ý không phù hợp với bạn.',
                      trailing: _CareStatusTag(
                        active: hasAllergy,
                        activeText: 'Đã thêm',
                        idleText: 'Tùy chọn',
                        accent: NabiPalette.cyan,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const _SmallInformationBanner(
                      icon: Icons.info_outline_rounded,
                      accent: NabiPalette.cyan,
                      text:
                          'Bạn có thể để trống nếu chưa chắc chắn hoặc chưa từng gặp phản ứng.',
                    ),
                    const SizedBox(height: 13),
                    _OptionalFieldFrame(
                      index: '01',
                      accent: NabiPalette.cyan,
                      active: state.allergyName.trim().isNotEmpty,
                      child: _ExtrasPicker(
                        label: 'Dị ứng / hạn chế thực phẩm',
                        hint: 'Không / chưa rõ',
                        icon: Icons.no_food_outlined,
                        options: OnboardingOptions.allergyChoices,
                        value: state.allergyName,
                        onChanged: controller.updateAllergyName,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OptionalFieldFrame(
                      index: '02',
                      accent: NabiPalette.cyan,
                      active: state.allergyNote.trim().isNotEmpty,
                      child: OnboardingTextField(
                        label: 'Ghi chú dị ứng',
                        hint: 'Ví dụ: phản ứng khi ăn nhiều hải sản',
                        initialValue: state.allergyNote,
                        maxLines: 2,
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        onChanged: controller.updateAllergyNote,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              _PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExtrasSectionHeader(
                      icon: Icons.monitor_heart_outlined,
                      accent: NabiPalette.violet,
                      title: 'Theo dõi sức khỏe & thuốc',
                      subtitle:
                          'Dùng để điều chỉnh gợi ý phù hợp hơn, không thay thế tư vấn y tế.',
                      trailing: _CareStatusTag(
                        active: hasTreatment,
                        activeText: 'Đã thêm',
                        idleText: 'Tùy chọn',
                        accent: NabiPalette.violet,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const _SmallInformationBanner(
                      icon: Icons.health_and_safety_outlined,
                      accent: NabiPalette.violet,
                      text:
                          'NaBi không chẩn đoán bệnh hoặc đưa ra chỉ định điều trị.',
                    ),
                    const SizedBox(height: 13),
                    _OptionalFieldFrame(
                      index: '01',
                      accent: NabiPalette.violet,
                      active: state.treatmentName.trim().isNotEmpty,
                      child: _ExtrasPicker(
                        label: 'Bạn đang theo dõi / điều trị gì?',
                        hint: 'Không điều trị hiện tại',
                        icon: Icons.medical_information_outlined,
                        options: OnboardingOptions.treatmentChoices,
                        value: state.treatmentName,
                        onChanged: controller.updateTreatmentName,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OptionalFieldFrame(
                      index: '02',
                      accent: NabiPalette.amber,
                      active: state.medicationName.trim().isNotEmpty,
                      child: _ExtrasPicker(
                        label: 'Thuốc hoặc sản phẩm đang dùng',
                        hint: 'Không dùng thường xuyên',
                        icon: Icons.medication_outlined,
                        options: OnboardingOptions.medicationChoices,
                        value: state.medicationName,
                        onChanged: controller.updateMedicationName,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OptionalFieldFrame(
                      index: '03',
                      accent: NabiPalette.rose,
                      active: state.treatmentNote.trim().isNotEmpty,
                      child: OnboardingTextField(
                        label: 'Ghi chú điều trị',
                        hint: 'Ví dụ: dùng theo chỉ định vào buổi tối',
                        initialValue: state.treatmentNote,
                        maxLines: 2,
                        prefixIcon: const Icon(Icons.notes_rounded),
                        onChanged: controller.updateTreatmentNote,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              _PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExtrasSectionHeader(
                      icon: Icons.favorite_outline_rounded,
                      accent: NabiPalette.rose,
                      title: 'Điều bạn đang quan tâm',
                      subtitle:
                          'NaBi sẽ ưu tiên điều này trong những gợi ý đầu tiên.',
                      trailing: _CareStatusTag(
                        active: hasConcern,
                        activeText: 'Đã chọn',
                        idleText: 'Tùy chọn',
                        accent: NabiPalette.rose,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _OptionalFieldFrame(
                      index: '01',
                      accent: NabiPalette.rose,
                      active: hasConcern,
                      child: _ExtrasPicker(
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
              ),
              const SizedBox(height: 12),

              const _FinalPrivacyCard(),
            ],
          );
        },
      ),
    );
  }
}

class _ExtrasHero extends StatelessWidget {
  final int completedSections;
  final double progress;

  const _ExtrasHero({
    required this.completedSections,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi * 2);
    final waveSecondary = math.cos(progress * math.pi * 2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NabiPalette.violet,
              Color.lerp(NabiPalette.violet, NabiPalette.rose, 0.48)!,
              NabiPalette.rose,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: NabiPalette.violet.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -48 + wave * 8,
              top: -56,
              child: _HeroBubble(
                size: 155,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: -62,
              bottom: -78 + waveSecondary * 7,
              child: _HeroBubble(
                size: 182,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 17 + wave * 3,
              child: _CareOrbit(
                progress: progress,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 19, 116, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroLabel(
                    label: 'HỒ SƠ CHĂM SÓC TÙY CHỌN',
                  ),
                  const SizedBox(height: 12),
                  const Expanded(
                    child: Text(
                      'Chia sẻ vừa đủ,\nđể được hiểu hơn.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.65,
                      ),
                    ),
                  ),
                  _HeroProgressChip(
                    completedSections: completedSections,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroBubble({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _HeroLabel extends StatelessWidget {
  final String label;

  const _HeroLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.95,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroProgressChip extends StatelessWidget {
  final int completedSections;

  const _HeroProgressChip({
    required this.completedSections,
  });

  @override
  Widget build(BuildContext context) {
    final isStarted = completedSections > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isStarted ? 0.19 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStarted
                ? Icons.check_circle_outline_rounded
                : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              isStarted
                  ? '$completedSections/3 mục đã bổ sung'
                  : 'Hoàn toàn tùy chọn',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareOrbit extends StatelessWidget {
  final double progress;

  const _CareOrbit({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final movement = math.sin(progress * math.pi * 2) * 4;

    return SizedBox(
      width: 119,
      height: 119,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 91,
            height: 91,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
          ),
          Container(
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          Positioned(
            top: 3 + movement,
            right: 14,
            child: const _OrbitItem(
              icon: Icons.favorite_outline_rounded,
              color: NabiPalette.rose,
            ),
          ),
          Positioned(
            left: 4,
            bottom: 11 - movement,
            child: const _OrbitItem(
              icon: Icons.medical_services_outlined,
              color: NabiPalette.cyan,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 28 + movement,
            child: const _OrbitItem(
              icon: Icons.lock_outline_rounded,
              color: NabiPalette.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitItem extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OrbitItem({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 15,
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  final int completedSections;

  const _PrivacyNotice({
    required this.completedSections,
  });

  @override
  Widget build(BuildContext context) {
    final started = completedSections > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: NabiPalette.cyan.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NabiPalette.cyan.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.cyan.withValues(alpha: 0.13),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: NabiPalette.cyan,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              started
                  ? 'Bạn có thể thay đổi hoặc xóa các thông tin này bất cứ lúc nào.'
                  : 'Bạn có thể bỏ qua toàn bộ phần này và cập nhật sau.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSurface extends StatelessWidget {
  final Widget child;

  const _PremiumSurface({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.96),
        ),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.055),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ExtrasSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _ExtrasSectionHeader({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 41,
          height: 41,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.1,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.34,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: trailing!,
          ),
        ],
      ],
    );
  }
}

class _CareStatusTag extends StatelessWidget {
  final bool active;
  final String activeText;
  final String idleText;
  final Color accent;

  const _CareStatusTag({
    required this.active,
    required this.activeText,
    required this.idleText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: 0.12)
            : NabiPalette.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? activeText : idleText,
        style: AppTextStyles.bodySmall.copyWith(
          color: active ? accent : NabiPalette.mutedInk,
          fontSize: 10.2,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _SmallInformationBanner extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String text;

  const _SmallInformationBanner({
    required this.icon,
    required this.accent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: accent.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: accent,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionalFieldFrame extends StatelessWidget {
  final String index;
  final Color accent;
  final bool active;
  final Widget child;

  const _OptionalFieldFrame({
    required this.index,
    required this.accent,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: active ? 0.065 : 0.032),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accent.withValues(alpha: active ? 0.22 : 0.10),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: active ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                active ? '✓' : index,
                style: TextStyle(
                  color: accent,
                  fontSize: 8.5,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FinalPrivacyCard extends StatelessWidget {
  const _FinalPrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: NabiPalette.rose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NabiPalette.rose.withValues(alpha: 0.11),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.rose.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: NabiPalette.rose,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Bạn kiểm soát những gì mình chia sẻ. Hãy chỉ thêm thông tin thật sự cần thiết.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtrasPicker extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<OnboardingChoiceOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _ExtrasPicker({
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCode = OnboardingOptions.codeForLabel(options, value);

    return OnboardingChoicePickerField(
      label: label,
      hint: hint,
      icon: icon,
      options: options,
      selectedCode: selectedCode,
      onSelected: (code) {
        if (code == 'none') {
          onChanged('');
          return;
        }

        onChanged(OnboardingOptions.labelFor(options, code));
      },
    );
  }
}
