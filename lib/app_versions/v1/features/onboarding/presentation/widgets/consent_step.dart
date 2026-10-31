import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

class ConsentStep extends ConsumerWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 7,
      title: 'Bạn luôn có quyền chọn',
      subtitle: 'Xem thông tin trước khi đồng ý.',
      mood: NabiOnboardingMood.consent,
      onBack: controller.previousStep,
      onNext: state.agreed ? controller.nextStep : null,
      child: OnboardingRevealColumn(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primarySubtle, colors.infoSoft],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.card.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: colors.secondaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'QUYỀN RIÊNG TƯ & MINH BẠCH',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.secondaryDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bạn luôn có quyền chọn',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Thông tin của bạn được sử dụng minh bạch và tôn trọng quyền riêng tư trong quá trình đồng hành cùng Nabi.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ConsentInfoCard(
            icon: Icons.lock_person_rounded,
            title: 'Dữ liệu của bạn',
            description:
                'Thông tin được lưu trữ trong ứng dụng. Khi bạn dùng AI văn bản hoặc phân tích ảnh, dữ liệu tối thiểu cần cho tác vụ sẽ được gửi qua HTTPS tới máy chủ NanoBio; ứng dụng không dùng model văn bản/ảnh cục bộ thay thế. Riêng trợ lý ESP32 có thể tải Whisper để nhận dạng lời nói trên điện thoại. Cần đăng nhập để dùng AI của máy chủ.',
            accent: NabiPalette.greenPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ConsentInfoCard(
            icon: Icons.medical_information_rounded,
            title: 'Lưu ý sức khỏe',
            description:
                'Nabi hỗ trợ gợi ý lối sống, không thay thế chẩn đoán y khoa từ bác sĩ hoặc chuyên gia y tế.',
            accent: NabiPalette.calmBlue,
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingStitchCard(
            color: colors.primarySubtle,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_2_rounded, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Những người đồng hành cùng Nabi',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Một nhóm sáng chế và huấn luyện cùng mong muốn giúp người Việt chủ động chăm sóc sức khỏe mỗi ngày.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            checked: state.agreed,
            label: 'Đồng ý sử dụng thông tin để tạo lộ trình',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('onboarding_consent_toggle'),
                onTap: () {
                  AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  controller.setAgreed(!state.agreed);
                },
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: AnimatedContainer(
                  duration: nabiReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: state.agreed ? colors.primarySubtle : colors.card,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: state.agreed ? colors.primary : colors.border,
                      width: state.agreed ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: nabiReducedMotion(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: state.agreed ? colors.primary : colors.card,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: state.agreed
                                ? colors.primary
                                : colors.outline,
                            width: 1.3,
                          ),
                        ),
                        child: state.agreed
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: colors.onBrand,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tôi đồng ý dùng thông tin đã nhập để tạo lộ trình.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!state.agreed) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bạn cần xác nhận để tiếp tục.',
              style: AppTextStyles.bodySmall.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsentInfoCard extends StatelessWidget {
  const _ConsentInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
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
