import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class ConsentStep extends ConsumerWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.onboarding),
          ),
        ),
        OnboardingStepShell(
          stepIndex: 6,
          title: '',
          subtitle: '',
          isScrollable: false,
          onBack: controller.previousStep,
          nextLabel: 'Tôi hiểu và đồng ý',
          onNext: () {
            if (!state.agreed) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bạn xác nhận đã hiểu trách nhiệm và giới hạn của Nami trước khi tiếp tục nhé.',
                    ),
                  ),
                );
              return;
            }
            controller.nextStep();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth >= 900
                  ? 820.0
                  : constraints.maxWidth;
              final horizontalPadding = constraints.maxWidth >= 720
                  ? AppSpacing.pagePaddingLarge
                  : AppSpacing.pagePadding;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.sm,
                  horizontalPadding,
                  AppSpacing.xxxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ConsentHeroCard(),
                        const SizedBox(height: AppSpacing.lg),
                        const _ResponsibilityCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _ConfirmCard(
                          agreed: state.agreed,
                          onChanged: controller.setAgreed,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConsentHeroCard extends StatelessWidget {
  const _ConsentHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: AppDecoration.glass(
              radius: AppRadius.lg,
              opacity: 0.16,
            ),
            child: const Icon(
              AppIcons.shield,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Trước khi Nami đồng hành cùng bạn',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mình muốn nói rõ vai trò của Nami để bạn sử dụng app nhẹ nhàng, chủ động và an toàn hơn.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.9),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsibilityCard extends StatelessWidget {
  const _ResponsibilityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        border: Border.all(color: AppColors.border),
        shadows: AppShadows.soft,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBullet(
            icon: AppIcons.info,
            title: 'Thông tin chỉ để tham khảo',
            message:
                'Các gợi ý về ăn uống, vận động, thói quen và nhắc nhở trong app không thay thế tư vấn, chẩn đoán hoặc điều trị y tế.',
          ),
          SizedBox(height: AppSpacing.md),
          _InfoBullet(
            icon: AppIcons.profile,
            title: 'Bạn chịu trách nhiệm với thông tin đã nhập',
            message:
                'Bạn cần nhập thông tin trung thực và tự cân nhắc trước khi áp dụng bất kỳ gợi ý nào vào sinh hoạt hằng ngày.',
          ),
          SizedBox(height: AppSpacing.md),
          _InfoBullet(
            icon: AppIcons.health,
            title: 'Hãy lắng nghe cơ thể',
            message:
                'Nếu có bệnh nền, đang dùng thuốc, đang điều trị, mang thai, hoặc có triệu chứng bất thường, bạn nên hỏi bác sĩ hoặc chuyên gia phù hợp.',
          ),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoBullet({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: AppDecoration.circle(color: AppColors.primarySoft),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;

  const _ConfirmCard({required this.agreed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      curve: AppAnimations.smoothCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: agreed
          ? AppDecoration.primaryGradient(radius: AppRadius.xxl)
          : AppDecoration.card(
              radius: AppRadius.xxl,
              border: Border.all(color: AppColors.border),
              shadows: AppShadows.card,
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Switch(value: agreed, onChanged: onChanged),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agreed ? 'Cảm ơn bạn đã xác nhận' : 'Mình đã hiểu và đồng ý',
                  style: AppTextStyles.heading5.copyWith(
                    color: agreed ? AppColors.textWhite : AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tôi hiểu rằng Nami chỉ cung cấp thông tin tham khảo và tôi sẽ chủ động tham khảo chuyên gia khi cần.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: agreed
                        ? AppColors.textWhite.withValues(alpha: 0.9)
                        : AppColors.textSecondary,
                    height: 1.5,
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
