import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/loading_gen_ai.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_step_shell.dart';

class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key});

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep>
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

    final basicReady =
        state.fullName.trim().isNotEmpty &&
        state.gender.trim().isNotEmpty &&
        state.occupation.trim().isNotEmpty;

    final goalsReady =
        state.goals.isNotEmpty || state.otherGoal.trim().isNotEmpty;

    final conditionsReady =
        state.conditions.isNotEmpty || state.otherCondition.trim().isNotEmpty;

    final lifestyleReady =
        state.habits.isNotEmpty ||
        state.sleepQuality.trim().isNotEmpty ||
        state.activityLevel.trim().isNotEmpty ||
        state.waterPerDay.trim().isNotEmpty;

    final extrasReady =
        state.allergyName.trim().isNotEmpty ||
        state.allergyNote.trim().isNotEmpty ||
        state.treatmentName.trim().isNotEmpty ||
        state.medicationName.trim().isNotEmpty ||
        state.treatmentNote.trim().isNotEmpty ||
        state.concernText.trim().isNotEmpty;

    final recordedSections = [
      basicReady,
      goalsReady,
      conditionsReady,
      lifestyleReady,
      extrasReady,
      state.agreed,
    ].where((value) => value).length;

    final isReadyToGenerate = state.canSave && state.agreed;

    return OnboardingStepShell(
      stepIndex: 8,
      title: 'Mọi thứ đã sẵn sàng,\nđể bắt đầu hành trình.',
      subtitle:
          'Kiểm tra nhanh lần cuối. Bạn có thể quay lại chỉnh sửa bất kỳ phần nào trước khi tạo lịch trình.',
      onBack: controller.previousStep,
      footer: NabiPrimaryButton(
        onPressed: state.isSaving
            ? null
            : () => _submit(context, state, controller),
        label: state.isSaving
            ? 'NaBi đang chuẩn bị lịch trình...'
            : 'Tạo lộ trình của tôi',
        icon: Icons.auto_awesome_rounded,
        isLoading: state.isSaving,
      ),
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Column(
            children: [
              _ReviewHero(
                progress: _ambientController.value,
                recordedSections: recordedSections,
                isReady: isReadyToGenerate,
              ),
              const SizedBox(height: 14),

              _ReadinessNotice(
                isReady: isReadyToGenerate,
                agreed: state.agreed,
                canSave: state.canSave,
              ),
              const SizedBox(height: 14),

              _PremiumReviewSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewSectionHeader(
                      icon: Icons.person_outline_rounded,
                      accent: NabiPalette.violet,
                      title: 'Thông tin cơ bản',
                      subtitle:
                          'Các chỉ số nền tảng để ước lượng nhu cầu hằng ngày.',
                      onEdit: () => controller.goToStep(1),
                    ),
                    const SizedBox(height: 16),
                    _ReviewMetricGrid(
                      children: [
                        _ReviewMetric(
                          icon: Icons.person_outline_rounded,
                          accent: NabiPalette.violet,
                          label: 'Họ và tên',
                          value: _value(state.fullName),
                        ),
                        _ReviewMetric(
                          icon: Icons.wc_rounded,
                          accent: NabiPalette.rose,
                          label: 'Giới tính',
                          value: OnboardingCatalog.labelOf(
                            OnboardingCatalog.genders,
                            state.gender,
                            fallback: 'Chưa cập nhật',
                          ),
                        ),
                        _ReviewMetric(
                          icon: Icons.cake_outlined,
                          accent: NabiPalette.amber,
                          label: 'Năm sinh',
                          value: state.birthYear > 0
                              ? state.birthYear.toString()
                              : 'Chưa cập nhật',
                        ),
                        _ReviewMetric(
                          icon: Icons.work_outline_rounded,
                          accent: NabiPalette.cyan,
                          label: 'Nhịp sống',
                          value: OnboardingCatalog.labelOf(
                            OnboardingCatalog.occupations,
                            state.occupation,
                            fallback: 'Chưa cập nhật',
                          ),
                        ),
                        _ReviewMetric(
                          icon: Icons.height_rounded,
                          accent: NabiPalette.violet,
                          label: 'Chiều cao',
                          value: state.heightCm > 0
                              ? '${state.heightCm.toStringAsFixed(0)} cm'
                              : 'Chưa cập nhật',
                        ),
                        _ReviewMetric(
                          icon: Icons.monitor_weight_outlined,
                          accent: NabiPalette.cyan,
                          label: 'Cân nặng',
                          value: state.weightKg > 0
                              ? '${state.weightKg.toStringAsFixed(1)} kg'
                              : 'Chưa cập nhật',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              _ReviewTagsCard(
                icon: Icons.flag_outlined,
                accent: NabiPalette.violet,
                title: 'Mục tiêu của bạn',
                subtitle:
                    'NaBi sẽ ưu tiên các gợi ý phù hợp với những điều bạn muốn đạt được.',
                values: _labels(OnboardingCatalog.goals, state.goals),
                fallback: _value(
                  state.otherGoal,
                  fallback: 'Chưa chọn mục tiêu',
                ),
                onEdit: () => controller.goToStep(2),
              ),
              const SizedBox(height: 13),

              _ReviewTagsCard(
                icon: Icons.health_and_safety_outlined,
                accent: NabiPalette.amber,
                title: 'Điều cần lưu ý',
                subtitle:
                    'Các thông tin này giúp lộ trình thận trọng và phù hợp hơn.',
                values: _labels(OnboardingCatalog.conditions, state.conditions),
                fallback: _value(
                  state.otherCondition,
                  fallback: 'Chưa có ghi chú',
                ),
                onEdit: () => controller.goToStep(3),
              ),
              const SizedBox(height: 13),

              _PremiumReviewSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewSectionHeader(
                      icon: Icons.self_improvement_rounded,
                      accent: NabiPalette.cyan,
                      title: 'Thói quen & nhịp sinh hoạt',
                      subtitle:
                          'Những tín hiệu quan trọng để lịch trình gần hơn với đời sống thực tế.',
                      onEdit: () => controller.goToStep(4),
                    ),
                    const SizedBox(height: 15),
                    _ReviewTagGroup(
                      values: _labels(OnboardingCatalog.habits, state.habits),
                      fallback: 'Chưa chọn thói quen cụ thể',
                      accent: NabiPalette.cyan,
                      icon: Icons.restaurant_menu_rounded,
                    ),
                    const SizedBox(height: 14),
                    _LifestyleSignals(
                      sleep: _value(state.sleepQuality),
                      activity: _value(state.activityLevel),
                      water: _value(state.waterPerDay),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              _PremiumReviewSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewSectionHeader(
                      icon: Icons.privacy_tip_outlined,
                      accent: NabiPalette.rose,
                      title: 'Thông tin chăm sóc thêm',
                      subtitle:
                          'Các dữ liệu tùy chọn giúp NaBi tránh những gợi ý không phù hợp.',
                      onEdit: () => controller.goToStep(5),
                    ),
                    const SizedBox(height: 16),
                    _ReviewMetricGrid(
                      children: [
                        _ReviewMetric(
                          icon: Icons.no_food_outlined,
                          accent: NabiPalette.cyan,
                          label: 'Dị ứng / hạn chế',
                          value: _value(state.allergyName),
                        ),
                        _ReviewMetric(
                          icon: Icons.medical_information_outlined,
                          accent: NabiPalette.violet,
                          label: 'Theo dõi sức khỏe',
                          value: _value(state.treatmentName),
                        ),
                        _ReviewMetric(
                          icon: Icons.medication_outlined,
                          accent: NabiPalette.amber,
                          label: 'Thuốc / sản phẩm',
                          value: _value(state.medicationName),
                        ),
                        _ReviewMetric(
                          icon: Icons.favorite_outline_rounded,
                          accent: NabiPalette.rose,
                          label: 'Mối quan tâm',
                          value: _value(state.concernText),
                        ),
                      ],
                    ),
                    if (state.allergyNote.trim().isNotEmpty ||
                        state.treatmentNote.trim().isNotEmpty) ...[
                      const SizedBox(height: 13),
                      _ReviewNotesPreview(
                        allergyNote: state.allergyNote,
                        treatmentNote: state.treatmentNote,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 13),

              _ConsentReviewCard(
                agreed: state.agreed,
                onEdit: () => controller.goToStep(6),
              ),
              const SizedBox(height: 12),

              const _ReviewFootnote(),
            ],
          );
        },
      ),
    );
  }

  static String _value(String value, {String fallback = 'Chưa cập nhật'}) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static List<String> _labels(
    Iterable<OnboardingChoiceOption> options,
    Iterable<String> codes,
  ) {
    return codes
        .map((code) => OnboardingCatalog.labelOf(options, code, fallback: ''))
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _submit(
    BuildContext context,
    dynamic state,
    dynamic controller,
  ) async {
    if (!state.agreed) {
      controller.goToStep(6);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Bạn hãy xác nhận trước khi tiếp tục nhé.'),
          ),
        );

      return;
    }

    if (!state.canSave) {
      controller.goToStep(1);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn hãy hoàn tất họ tên, giới tính và nhịp sống trước nhé.',
            ),
          ),
        );

      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AIGeneratingPage()));

    try {
      await controller.saveOnboarding();

      final generationSource = ref
          .read(onboardingProvider)
          .initialPlanGenerationSource;
      if (generationSource.isBasicSuggestion && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Nabi đã tạo lịch gợi ý cơ bản đầu tiên. Khi AI sẵn sàng, bạn có thể tạo lại để nhận gợi ý cá nhân hơn nhé.',
              ),
            ),
          );
      }
      if (context.mounted) {
        V1AppNavigator.goMenu(context);
      }
    } catch (error) {
      if (!context.mounted) return;

      Navigator.of(context).pop();

      final message = error is AIOverloadedException
          ? AIOverloadedException.userMessage
          : error is StateError
          ? error.message.toString()
          : 'Mình chưa thể hoàn tất lúc này. Bạn thử lại giúp mình nhé.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ReviewHero extends StatelessWidget {
  final double progress;
  final int recordedSections;
  final bool isReady;

  const _ReviewHero({
    required this.progress,
    required this.recordedSections,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi * 2);
    final secondaryWave = math.cos(progress * math.pi * 2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: Container(
        width: double.infinity,
        height: 194,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NabiPalette.violet,
              Color.lerp(NabiPalette.violet, NabiPalette.cyan, 0.48)!,
              NabiPalette.cyan,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: NabiPalette.violet.withValues(alpha: 0.23),
              blurRadius: 28,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -55,
              right: -48 + wave * 8,
              child: _HeroBubble(
                size: 154,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: -78 + secondaryWave * 7,
              left: -61,
              child: _HeroBubble(
                size: 182,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 17 + wave * 3,
              child: _ReviewOrbit(isReady: isReady, progress: progress),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 19, 118, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroEyebrow(label: 'KIỂM TRA LẦN CUỐI'),
                  const SizedBox(height: 12),
                  const Text(
                    'Lộ trình riêng của bạn\nsắp được tạo.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.65,
                    ),
                  ),
                  const Spacer(),
                  _HeroProgressChip(
                    recordedSections: recordedSections,
                    isReady: isReady,
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

  const _HeroBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroEyebrow extends StatelessWidget {
  final String label;

  const _HeroEyebrow({required this.label});

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
              letterSpacing: 0.96,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroProgressChip extends StatelessWidget {
  final int recordedSections;
  final bool isReady;

  const _HeroProgressChip({
    required this.recordedSections,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isReady ? 0.20 : 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            isReady
                ? 'Sẵn sàng tạo lịch trình'
                : '$recordedSections/6 phần đã có dữ liệu',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewOrbit extends StatelessWidget {
  final bool isReady;
  final double progress;

  const _ReviewOrbit({required this.isReady, required this.progress});

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
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isReady ? 0.25 : 0.17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
            ),
            child: Icon(
              isReady
                  ? Icons.auto_awesome_rounded
                  : Icons.assignment_turned_in_outlined,
              size: 30,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 3 + movement,
            right: 14,
            child: const _OrbitBadge(
              icon: Icons.person_outline_rounded,
              color: NabiPalette.violet,
            ),
          ),
          Positioned(
            left: 4,
            bottom: 11 - movement,
            child: const _OrbitBadge(
              icon: Icons.favorite_outline_rounded,
              color: NabiPalette.rose,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 28 + movement,
            child: const _OrbitBadge(
              icon: Icons.check_circle_outline_rounded,
              color: NabiPalette.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OrbitBadge({required this.icon, required this.color});

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
      child: Icon(icon, color: color, size: 15),
    );
  }
}

class _ReadinessNotice extends StatelessWidget {
  final bool isReady;
  final bool agreed;
  final bool canSave;

  const _ReadinessNotice({
    required this.isReady,
    required this.agreed,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isReady
        ? NabiPalette.cyan
        : !agreed
        ? NabiPalette.amber
        : NabiPalette.violet;

    final icon = isReady
        ? Icons.verified_rounded
        : !agreed
        ? Icons.warning_amber_rounded
        : Icons.edit_note_rounded;

    final message = isReady
        ? 'Hồ sơ đã sẵn sàng. NaBi sẽ dùng những thông tin này để tạo lịch trình phù hợp với bạn.'
        : !agreed
        ? 'Bạn cần xác nhận phần lưu ý an toàn trước khi tạo lịch trình.'
        : !canSave
        ? 'Một vài thông tin cơ bản vẫn cần được hoàn thiện trước khi tiếp tục.'
        : 'Bạn có thể rà soát lại hồ sơ trước khi tạo lịch trình.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.13),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
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

class _PremiumReviewSurface extends StatelessWidget {
  final Widget child;

  const _PremiumReviewSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
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

class _ReviewSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  const _ReviewSectionHeader({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onEdit,
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
          child: Icon(icon, color: accent, size: 20),
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
                    fontSize: 15.2,
                    fontWeight: FontWeight.w900,
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
        const SizedBox(width: 5),
        _EditButton(accent: accent, onPressed: onEdit),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;

  const _EditButton({required this.accent, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.edit_outlined, size: 14, color: accent),
      label: Text(
        'Sửa',
        style: AppTextStyles.labelSmall.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ReviewMetricGrid extends StatelessWidget {
  final List<Widget> children;

  const _ReviewMetricGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 530;

        if (!isWide) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 9),
              ],
            ],
          );
        }

        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  const _ReviewMetric({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 'Chưa cập nhật';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: NabiPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isEmpty ? NabiPalette.mutedInk : NabiPalette.ink,
                    height: 1.25,
                    fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTagsCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final List<String> values;
  final String fallback;
  final VoidCallback onEdit;

  const _ReviewTagsCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.fallback,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumReviewSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewSectionHeader(
            icon: icon,
            accent: accent,
            title: title,
            subtitle: subtitle,
            onEdit: onEdit,
          ),
          const SizedBox(height: 15),
          _ReviewTagGroup(
            values: values,
            fallback: fallback,
            accent: accent,
            icon: icon,
          ),
        ],
      ),
    );
  }
}

class _ReviewTagGroup extends StatelessWidget {
  final List<String> values;
  final String fallback;
  final Color accent;
  final IconData icon;

  const _ReviewTagGroup({
    required this.values,
    required this.fallback,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tags = values.isEmpty ? [fallback] : values;
    final isFallback = values.isEmpty;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isFallback ? 0.05 : 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: isFallback ? 0.08 : 0.16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFallback ? Icons.info_outline_rounded : icon,
                    size: 14,
                    color: accent.withValues(alpha: isFallback ? 0.68 : 1),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 235),
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isFallback
                            ? NabiPalette.mutedInk
                            : NabiPalette.ink,
                        height: 1.2,
                        fontWeight: isFallback
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _LifestyleSignals extends StatelessWidget {
  final String sleep;
  final String activity;
  final String water;

  const _LifestyleSignals({
    required this.sleep,
    required this.activity,
    required this.water,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;

        final items = [
          _LifestyleSignalCard(
            icon: Icons.bedtime_outlined,
            accent: NabiPalette.violet,
            label: 'Giấc ngủ',
            value: sleep,
          ),
          _LifestyleSignalCard(
            icon: Icons.directions_walk_rounded,
            accent: NabiPalette.cyan,
            label: 'Vận động',
            value: activity,
          ),
          _LifestyleSignalCard(
            icon: Icons.water_drop_outlined,
            accent: NabiPalette.rose,
            label: 'Nước uống',
            value: water,
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                items[index],
                if (index != items.length - 1) const SizedBox(height: 9),
              ],
            ],
          );
        }

        final width = (constraints.maxWidth - 16) / 3;

        return Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              SizedBox(width: width, child: items[index]),
              if (index != items.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _LifestyleSignalCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  const _LifestyleSignalCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 'Chưa cập nhật';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: NabiPalette.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: isEmpty ? NabiPalette.mutedInk : NabiPalette.ink,
              height: 1.25,
              fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewNotesPreview extends StatelessWidget {
  final String allergyNote;
  final String treatmentNote;

  const _ReviewNotesPreview({
    required this.allergyNote,
    required this.treatmentNote,
  });

  @override
  Widget build(BuildContext context) {
    final notes = <String>[
      if (allergyNote.trim().isNotEmpty) 'Dị ứng: ${allergyNote.trim()}',
      if (treatmentNote.trim().isNotEmpty) 'Theo dõi: ${treatmentNote.trim()}',
    ];

    if (notes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NabiPalette.rose.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: NabiPalette.rose.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded, size: 17, color: NabiPalette.rose),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes.join('\n'),
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentReviewCard extends StatelessWidget {
  final bool agreed;
  final VoidCallback onEdit;

  const _ConsentReviewCard({required this.agreed, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final accent = agreed ? NabiPalette.cyan : NabiPalette.amber;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(
              agreed
                  ? Icons.verified_user_outlined
                  : Icons.warning_amber_rounded,
              color: accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agreed
                      ? 'Bạn đã xác nhận lưu ý an toàn'
                      : 'Bạn chưa xác nhận lưu ý an toàn',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  agreed
                      ? 'NaBi là công cụ hỗ trợ chăm sóc hằng ngày, không thay thế chẩn đoán hoặc điều trị y tế.'
                      : 'Bạn cần xác nhận ở bước trước trước khi tạo lịch trình.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          _EditButton(accent: accent, onPressed: onEdit),
        ],
      ),
    );
  }
}

class _ReviewFootnote extends StatelessWidget {
  const _ReviewFootnote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: NabiPalette.rose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NabiPalette.rose.withValues(alpha: 0.11)),
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
              Icons.edit_outlined,
              color: NabiPalette.rose,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Sau khi tạo lịch trình, bạn vẫn có thể cập nhật hồ sơ để NaBi điều chỉnh gợi ý phù hợp hơn.',
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
