import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_step_shell.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 0,
      title: 'Chào bạn, mình là Nabi',
      subtitle: 'Mình cùng tạo lộ trình phù hợp nhé.',
      showBack: false,
      showCompanion: false,
      onNext: controller.nextStep,
      nextLabel: 'Bắt đầu',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  gradient: NabiPalette.hero,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: [
                    BoxShadow(
                      color: NabiPalette.greenDeep.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 13),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const NabiCompanionAvatar(
                      size: 136,
                      mood: NabiOnboardingMood.welcome,
                      statusLabel: 'Bắt đầu nhé?',
                      hero: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '2–3 phút để Nabi hiểu bạn',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading4.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Không cần thông tin hoàn hảo.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textInverse.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: _WelcomeBenefit(
                      icon: Icons.person_rounded,
                      label: 'Hiểu bạn',
                      color: NabiPalette.greenPrimary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _WelcomeBenefit(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Tạo lộ trình',
                      color: NabiPalette.personalPurple,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _WelcomeBenefit(
                      icon: Icons.favorite_rounded,
                      label: 'Đồng hành',
                      color: NabiPalette.careCoral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const NabiAssistantMessage(
                message: 'Bạn có thể chỉnh lại sau',
                icon: Icons.tune_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBenefit extends StatelessWidget {
  const _WelcomeBenefit({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return NabiGlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      elevated: false,
      borderColor: color.withValues(alpha: 0.16),
      child: Column(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
