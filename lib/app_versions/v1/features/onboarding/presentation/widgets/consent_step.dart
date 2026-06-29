import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class ConsentStep extends ConsumerStatefulWidget {
  const ConsentStep({super.key});

  @override
  ConsumerState<ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends ConsumerState<ConsentStep>
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

    return OnboardingStepShell(
      stepIndex: 6,
      title: 'Một xác nhận nhỏ,\nđể chăm sóc đúng cách.',
      subtitle:
          'NaBi đưa ra gợi ý chăm sóc hằng ngày, không thay thế chẩn đoán hoặc điều trị y tế.',
      onBack: controller.previousStep,
      nextLabel: state.agreed
          ? 'Tiếp tục tạo lộ trình'
          : 'Tôi hiểu và đồng ý',
      onNext: () {
        if (!state.agreed) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Bạn hãy xác nhận đã hiểu trước khi tiếp tục nhé.',
                ),
              ),
            );
          return;
        }

        controller.nextStep();
      },
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Column(
            children: [
              _ConsentHero(
                agreed: state.agreed,
                progress: _ambientController.value,
              ),
              const SizedBox(height: 14),

              _ConsentStatusNotice(
                agreed: state.agreed,
              ),
              const SizedBox(height: 14),

              const _ConsentPremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConsentSectionHeader(
                      icon: Icons.verified_user_outlined,
                      accent: NabiPalette.violet,
                      title: 'NaBi cam kết với bạn',
                      subtitle:
                          'Mọi gợi ý đều được xây dựng để hỗ trợ bạn chăm sóc bản thân chủ động hơn.',
                    ),
                    SizedBox(height: 16),
                    _ConsentCommitmentRow(
                      icon: Icons.lock_outline_rounded,
                      accent: NabiPalette.cyan,
                      title: 'Tôn trọng dữ liệu của bạn',
                      description:
                          'Thông tin hồ sơ chỉ được dùng để cá nhân hóa trải nghiệm chăm sóc.',
                    ),
                    _ConsentSoftDivider(),
                    _ConsentCommitmentRow(
                      icon: Icons.auto_awesome_outlined,
                      accent: NabiPalette.violet,
                      title: 'Gợi ý theo nhịp sống riêng',
                      description:
                          'Thực đơn, vận động và lời nhắc được điều chỉnh theo những gì bạn đã chia sẻ.',
                    ),
                    _ConsentSoftDivider(),
                    _ConsentCommitmentRow(
                      icon: Icons.health_and_safety_outlined,
                      accent: NabiPalette.amber,
                      title: 'Ưu tiên an toàn',
                      description:
                          'NaBi khuyến khích bạn gặp chuyên gia khi có dấu hiệu cần được theo dõi.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              const _MedicalBoundaryCard(),
              const SizedBox(height: 13),

              _ConsentAgreementCard(
                agreed: state.agreed,
                onChanged: controller.setAgreed,
              ),
              const SizedBox(height: 12),

              const _AfterOnboardingHint(),
            ],
          );
        },
      ),
    );
  }
}

class _ConsentHero extends StatelessWidget {
  final bool agreed;
  final double progress;

  const _ConsentHero({
    required this.agreed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi * 2);
    final secondaryWave = math.cos(progress * math.pi * 2);

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
              Color.lerp(NabiPalette.violet, NabiPalette.cyan, 0.48)!,
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
              top: -54,
              right: -45 + wave * 8,
              child: _ConsentHeroBubble(
                size: 152,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: -76 + secondaryWave * 7,
              left: -62,
              child: _ConsentHeroBubble(
                size: 180,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18 + wave * 3,
              child: _ConsentTrustOrbit(
                agreed: agreed,
                progress: progress,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 19, 115, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ConsentHeroLabel(
                    label: 'NIỀM TIN & SỰ AN TÂM',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hiểu rõ trước khi\nbắt đầu hành trình.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.65,
                    ),
                  ),
                  const Spacer(),
                  _ConsentHeroStatus(
                    agreed: agreed,
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

class _ConsentHeroBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _ConsentHeroBubble({
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

class _ConsentHeroLabel extends StatelessWidget {
  final String label;

  const _ConsentHeroLabel({
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
              letterSpacing: 0.96,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentHeroStatus extends StatelessWidget {
  final bool agreed;

  const _ConsentHeroStatus({
    required this.agreed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: agreed ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            agreed
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            agreed ? 'Bạn đã xác nhận' : 'Cần xác nhận trước khi tiếp tục',
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

class _ConsentTrustOrbit extends StatelessWidget {
  final bool agreed;
  final double progress;

  const _ConsentTrustOrbit({
    required this.agreed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final movement = math.sin(progress * math.pi * 2) * 4;

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
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: agreed ? 0.25 : 0.17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ),
            child: Icon(
              agreed
                  ? Icons.verified_user_rounded
                  : Icons.shield_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          Positioned(
            top: 3 + movement,
            right: 14,
            child: const _ConsentOrbitBadge(
              icon: Icons.lock_outline_rounded,
              color: NabiPalette.cyan,
            ),
          ),
          Positioned(
            left: 4,
            bottom: 11 - movement,
            child: const _ConsentOrbitBadge(
              icon: Icons.favorite_outline_rounded,
              color: NabiPalette.rose,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 28 + movement,
            child: const _ConsentOrbitBadge(
              icon: Icons.health_and_safety_outlined,
              color: NabiPalette.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentOrbitBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ConsentOrbitBadge({
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

class _ConsentStatusNotice extends StatelessWidget {
  final bool agreed;

  const _ConsentStatusNotice({
    required this.agreed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = agreed ? NabiPalette.cyan : NabiPalette.violet;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.13),
        ),
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
            child: Icon(
              agreed
                  ? Icons.check_circle_outline_rounded
                  : Icons.privacy_tip_outlined,
              color: accent,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              agreed
                  ? 'Bạn đã xác nhận. Lộ trình sẽ được tạo ở bước tiếp theo.'
                  : 'Bạn luôn kiểm soát thông tin của mình và có thể thay đổi hồ sơ sau này.',
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

class _ConsentPremiumSurface extends StatelessWidget {
  final Widget child;

  const _ConsentPremiumSurface({
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

class _ConsentSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  const _ConsentSectionHeader({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
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
                    height: 1.34,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentCommitmentRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  const _ConsentCommitmentRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: accent,
            size: 19,
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
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentSoftDivider extends StatelessWidget {
  const _ConsentSoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Divider(
        height: 1,
        thickness: 1,
        color: NabiPalette.ink.withValues(alpha: 0.06),
      ),
    );
  }
}

class _MedicalBoundaryCard extends StatelessWidget {
  const _MedicalBoundaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: NabiPalette.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: NabiPalette.amber.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.amber.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 17,
              color: NabiPalette.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khi nào nên gặp chuyên gia?',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Khi có triệu chứng kéo dài, diễn biến bất thường hoặc bạn đang cần chẩn đoán và điều trị.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.35,
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

class _ConsentAgreementCard extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;

  const _ConsentAgreementCard({
    required this.agreed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = agreed ? NabiPalette.violet : NabiPalette.ink;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      decoration: BoxDecoration(
        color: agreed
            ? NabiPalette.violet.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: agreed
              ? NabiPalette.violet.withValues(alpha: 0.28)
              : NabiPalette.ink.withValues(alpha: 0.09),
          width: agreed ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => onChanged(!agreed),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 15, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: agreed,
                  activeColor: NabiPalette.violet,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: agreed
                        ? NabiPalette.violet
                        : NabiPalette.mutedInk.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (value) => onChanged(value ?? false),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agreed
                              ? 'Bạn đã xác nhận đầy đủ'
                              : 'Xác nhận trước khi tiếp tục',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tôi hiểu NaBi là công cụ gợi ý hỗ trợ chăm sóc hằng ngày và không thay thế tư vấn, chẩn đoán hoặc điều trị từ bác sĩ.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: NabiPalette.mutedInk,
                            height: 1.38,
                          ),
                        ),
                      ],
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

class _AfterOnboardingHint extends StatelessWidget {
  const _AfterOnboardingHint();

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
              Icons.edit_outlined,
              color: NabiPalette.rose,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Bạn có thể thay đổi hồ sơ, sở thích và thông tin chăm sóc sau khi hoàn tất.',
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