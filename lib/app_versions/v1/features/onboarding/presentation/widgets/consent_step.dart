import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_step_shell.dart';

class ConsentStep extends ConsumerWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 7,
      title: 'Bạn luôn có quyền chọn',
      subtitle: 'Xác nhận trước khi tạo lộ trình.',
      mood: NabiOnboardingMood.consent,
      onBack: controller.previousStep,
      nextLabel: 'Tiếp tục',
      onNext: state.agreed ? controller.nextStep : null,
      child: Column(
        children: [
          const _ConsentCard(
            icon: Icons.lock_rounded,
            title: 'Dữ liệu của bạn',
            text: 'Chỉ dùng để cá nhân hóa trải nghiệm.',
            color: NabiPalette.greenPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ConsentCard(
            icon: Icons.medical_information_rounded,
            title: 'Lưu ý sức khỏe',
            text: 'NaBi không thay thế bác sĩ hoặc chuyên gia.',
            color: NabiPalette.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            checked: state.agreed,
            label: 'Đồng ý sử dụng thông tin để tạo lộ trình',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setAgreed(!state.agreed);
                },
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: AnimatedContainer(
                  duration: nabiReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 230),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    gradient: state.agreed
                        ? NabiPalette.selection
                        : NabiPalette.card,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: state.agreed
                          ? NabiPalette.greenPrimary
                          : NabiPalette.line,
                      width: state.agreed ? 1.8 : 1,
                    ),
                    boxShadow: state.agreed
                        ? [
                            BoxShadow(
                              color: NabiPalette.greenPrimary
                                  .withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: AppDuration.fast,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: state.agreed
                              ? AppColors.surface.withValues(alpha: 0.16)
                              : NabiPalette.greenSoft,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: AppDuration.button,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            state.agreed
                                ? Icons.check_rounded
                                : Icons.touch_app_rounded,
                            key: ValueKey(state.agreed),
                            color: state.agreed
                                ? AppColors.surface
                                : NabiPalette.greenPrimary,
                            size: 25,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tôi đồng ý dùng thông tin đã nhập để tạo lộ trình.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color:
                                state.agreed ? AppColors.surface : NabiPalette.ink,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NabiAssistantMessage(
            message: state.agreed ? 'Cảm ơn bạn đã xác nhận' : 'Chạm để xác nhận',
            icon: state.agreed
                ? Icons.favorite_rounded
                : Icons.touch_app_rounded,
            accent: state.agreed
                ? NabiPalette.greenPrimary
                : NabiPalette.calmBlue,
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _ConsentCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NabiGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      elevated: false,
      borderColor: color.withValues(alpha: 0.16),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.10), AppColors.surface],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  text,
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
