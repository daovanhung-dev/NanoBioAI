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

class LifestyleStep extends ConsumerStatefulWidget {
  const LifestyleStep({super.key});

  @override
  ConsumerState<LifestyleStep> createState() => _LifestyleStepState();
}

class _LifestyleStepState extends ConsumerState<LifestyleStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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

    return OnboardingStepShell(
      stepIndex: 4,
      title: 'Nhịp sống của bạn,\nđược tạo từ những điều nhỏ.',
      subtitle:
          'Chọn những điều gần nhất với hiện tại. Không có đáp án đúng hay sai.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Column(
            children: [
              _LifestyleHero(
                selectedHabitCount: state.habits.length,
                progress: _ambientController.value,
              ),
              const SizedBox(height: 14),

              _PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.restaurant_menu_rounded,
                      accent: NabiPalette.cyan,
                      title: 'Thói quen ăn uống & sinh hoạt',
                      subtitle:
                          'Chọn tất cả các điều đang diễn ra trong nhịp sống của bạn.',
                      trailing: _SelectedCountBadge(
                        count: state.habits.length,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const _MicroHint(
                      icon: Icons.touch_app_outlined,
                      text: 'Bạn có thể chọn nhiều thói quen cùng lúc.',
                    ),
                    const SizedBox(height: 14),
                    OnboardingChoiceGrid(
                      options: OnboardingCatalog.habits,
                      selectedCodes: state.habits,
                      multiSelect: true,
                      onSelected: controller.toggleHabit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              _PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.monitor_heart_outlined,
                      accent: NabiPalette.violet,
                      title: 'Ba tín hiệu hằng ngày',
                      subtitle:
                          'Một vài ước lượng đơn giản để lộ trình phù hợp hơn.',
                    ),
                    const SizedBox(height: 16),

                    _SignalPickerFrame(
                      index: '01',
                      accent: NabiPalette.violet,
                      child: OnboardingChoicePickerField(
                        label: 'Giấc ngủ gần đây',
                        hint: 'Chọn mô tả',
                        icon: Icons.bedtime_outlined,
                        options: OnboardingOptions.sleepQualityChoices,
                        selectedCode: OnboardingOptions.codeForLabel(
                          OnboardingOptions.sleepQualityChoices,
                          state.sleepQuality,
                        ),
                        onSelected: (code) => controller.updateSleepQuality(
                          OnboardingCatalog.labelOf(
                            OnboardingOptions.sleepQualityChoices,
                            code,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),

                    _SignalPickerFrame(
                      index: '02',
                      accent: NabiPalette.cyan,
                      child: OnboardingChoicePickerField(
                        label: 'Mức độ vận động',
                        hint: 'Chọn mức độ',
                        icon: Icons.directions_walk_rounded,
                        options: OnboardingOptions.activityChoices,
                        selectedCode: OnboardingOptions.codeForLabel(
                          OnboardingOptions.activityChoices,
                          state.activityLevel,
                        ),
                        onSelected: (code) => controller.updateActivityLevel(
                          OnboardingCatalog.labelOf(
                            OnboardingOptions.activityChoices,
                            code,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),

                    _SignalPickerFrame(
                      index: '03',
                      accent: NabiPalette.rose,
                      child: OnboardingChoicePickerField(
                        label: 'Nước uống mỗi ngày',
                        hint: 'Chọn ước lượng',
                        icon: Icons.water_drop_outlined,
                        options: OnboardingOptions.waterChoices,
                        selectedCode: OnboardingOptions.codeForLabel(
                          OnboardingOptions.waterChoices,
                          state.waterPerDay,
                        ),
                        onSelected: (code) => controller.updateWaterPerDay(
                          OnboardingCatalog.labelOf(
                            OnboardingOptions.waterChoices,
                            code,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const _PrivacyHint(),
            ],
          );
        },
      ),
    );
  }
}

class _LifestyleHero extends StatelessWidget {
  final int selectedHabitCount;
  final double progress;

  const _LifestyleHero({
    required this.selectedHabitCount,
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
        height: 188,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NabiPalette.violet,
              Color.lerp(NabiPalette.violet, NabiPalette.cyan, 0.45)!,
              NabiPalette.cyan,
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
              right: -38 + wave * 8,
              top: -45,
              child: _AmbientBubble(
                size: 145,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: -57,
              bottom: -70 + waveSecondary * 7,
              child: _AmbientBubble(
                size: 175,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 19 + wave * 3,
              child: _LifestyleOrbit(
                progress: progress,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 19, 112, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroLabel(
                    label: 'NHỊP SỐNG CỦA BẠN',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mỗi lựa chọn nhỏ,\ntạo nên thay đổi lớn.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.65,
                    ),
                  ),
                  const Spacer(),
                  _HeroSelectionStatus(
                    selectedHabitCount: selectedHabitCount,
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

class _AmbientBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientBubble({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
      ],
    );
  }
}

class _HeroSelectionStatus extends StatelessWidget {
  final int selectedHabitCount;

  const _HeroSelectionStatus({
    required this.selectedHabitCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedHabitCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: hasSelection ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSelection
                ? Icons.check_circle_outline_rounded
                : Icons.add_circle_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            hasSelection
                ? '$selectedHabitCount thói quen đã chọn'
                : 'Bắt đầu chọn thói quen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifestyleOrbit extends StatelessWidget {
  final double progress;

  const _LifestyleOrbit({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final motion = math.sin(progress * math.pi * 2) * 4;

    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.23),
              ),
            ),
          ),
          Container(
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          Positioned(
            top: 2 + motion,
            right: 15,
            child: const _OrbitIcon(
              icon: Icons.restaurant_rounded,
              color: NabiPalette.amber,
            ),
          ),
          Positioned(
            bottom: 9 - motion,
            left: 5,
            child: const _OrbitIcon(
              icon: Icons.nightlight_round,
              color: NabiPalette.rose,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 27 + motion,
            child: const _OrbitIcon(
              icon: Icons.directions_run_rounded,
              color: NabiPalette.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OrbitIcon({
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
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
                    fontSize: 15.2,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.35,
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

class _SelectedCountBadge extends StatelessWidget {
  final int count;

  const _SelectedCountBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? NabiPalette.violet.withValues(alpha: 0.11)
            : NabiPalette.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count chọn',
        style: AppTextStyles.bodySmall.copyWith(
          color: active ? NabiPalette.violet : NabiPalette.mutedInk,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MicroHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MicroHint({
    required this.icon,
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
        color: NabiPalette.cyan.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: NabiPalette.cyan.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: NabiPalette.cyan,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalPickerFrame extends StatelessWidget {
  final String index;
  final Color accent;
  final Widget child;

  const _SignalPickerFrame({
    required this.index,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accent.withValues(alpha: 0.11),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                index,
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

class _PrivacyHint extends StatelessWidget {
  const _PrivacyHint();

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
              Icons.lock_outline_rounded,
              color: NabiPalette.rose,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Thông tin của bạn chỉ được dùng để tạo gợi ý phù hợp hơn.',
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