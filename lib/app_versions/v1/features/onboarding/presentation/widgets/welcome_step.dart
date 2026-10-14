import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingProvider.notifier);
    final colors = context.semanticColors;

    return OnboardingStepShell(
      stepIndex: 0,
      title: 'Chào bạn, mình là Nabi',
      subtitle: 'Mình cùng tạo lộ trình phù hợp nhé.',
      mood: NabiOnboardingMood.welcome,
      showBack: true,
      onBack: () {
        if (GoRouter.of(context).canPop()) GoRouter.of(context).pop();
      },
      onNext: controller.nextStep,
      nextLabel: 'Bắt đầu',
      child: OnboardingRevealColumn(
        children: [
          AppViewMotion(
            key: const Key('onboarding_welcome_hero_motion'),
            duration: AppDuration.emphasized,
            offset: Offset.zero,
            child: Center(
              child: SizedBox(
                width: 212,
                height: 202,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 16,
                      right: 12,
                      top: 14,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colors.secondarySoft, colors.infoSoft],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(74),
                            topRight: Radius.circular(58),
                            bottomLeft: Radius.circular(62),
                            bottomRight: Radius.circular(82),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 24,
                      child: _FloatingBadge(
                        icon: Icons.favorite_rounded,
                        color: colors.secondary,
                      ),
                    ),
                    Positioned(
                      left: 5,
                      bottom: 30,
                      child: _FloatingBadge(
                        icon: Icons.water_drop_rounded,
                        color: colors.primary,
                        small: true,
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: 18,
                      child: Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: colors.textPrimary.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.asset(
                            'assets/logo.jpg',
                            fit: BoxFit.cover,
                            cacheWidth: 120,
                            semanticLabel: 'Logo NanoBioAI',
                          ),
                        ),
                      ),
                    ),
                    Image.asset(
                      NabiOnboardingMood.welcome.assetPath,
                      width: 164,
                      height: 164,
                      fit: BoxFit.contain,
                      cacheWidth: 360,
                      semanticLabel: 'Nabi chào bạn',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.secondarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 15,
                    color: colors.secondaryDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ĐỒNG HÀNH CÙNG NABI',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.secondaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chào bạn, mình là Nabi',
            textAlign: TextAlign.center,
            style: AppTextStyles.displaySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mình cùng tạo lộ trình phù hợp với nhịp sống của bạn nhé.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _WelcomeBenefit(
            icon: Icons.quiz_outlined,
            title: 'Tìm hiểu thể trạng',
            label: 'Khảo sát',
            description: 'Vài câu hỏi về thể trạng và thói quen sinh hoạt.',
            tint: NabiPalette.calmBlue,
          ),
          const SizedBox(height: AppSpacing.xs),
          const _WelcomeBenefit(
            icon: Icons.lock_outline_rounded,
            title: 'Minh bạch thông tin',
            label: 'Riêng tư',
            description: 'Bạn luôn kiểm soát thông tin mình chia sẻ.',
            tint: NabiPalette.greenPrimary,
          ),
          const SizedBox(height: AppSpacing.xs),
          const _WelcomeBenefit(
            icon: Icons.tune_rounded,
            title: 'Dễ dàng tùy chỉnh',
            label: 'Linh hoạt',
            description: 'Có thể điều chỉnh lộ trình bất cứ lúc nào.',
            tint: NabiPalette.personalPurple,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: colors.secondary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Lắng nghe cơ thể là bước đầu tiên để chăm sóc mình tốt hơn.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
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

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.color,
    this.small = false,
  });

  final IconData icon;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.semanticColors.card,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.semanticColors.textPrimary.withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: small ? 17 : 20),
    );
  }
}

class _WelcomeBenefit extends StatelessWidget {
  const _WelcomeBenefit({
    required this.icon,
    required this.title,
    required this.label,
    required this.description,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String label;
  final String description;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: tint, size: 23),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.38,
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
