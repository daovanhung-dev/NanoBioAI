import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import '../../providers/onboarding_voice_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_voice_step.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

class ConsentStep extends ConsumerStatefulWidget {
  const ConsentStep({super.key});

  @override
  ConsumerState<ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends ConsumerState<ConsentStep> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final state = ref.watch(onboardingProvider);
    final isVoiceMode = ref.watch(
      onboardingVoiceProvider.select((voice) => voice.isVoiceMode),
    );
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 7,
      title: 'Quyền riêng tư',
      subtitle: 'Xem nhanh trước khi đồng ý.',
      mood: NabiOnboardingMood.consent,
      onBack: controller.previousStep,
      onNext: state.agreed ? controller.nextStep : null,
      child: OnboardingRevealColumn(
        children: [
          if (isVoiceMode) const OnboardingConsentVoiceReader(),
          const _ConsentInfoCard(
            icon: Icons.lock_person_rounded,
            title: 'Thông tin của bạn',
            description:
                'Hồ sơ lưu trong ứng dụng. Khi dùng AI qua máy chủ, dữ liệu cần thiết được gửi tới NanoBio.',
            accent: NabiPalette.greenPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ConsentInfoCard(
            icon: Icons.medical_information_rounded,
            title: 'Lưu ý sức khỏe',
            description: 'Nabi gợi ý lối sống, không thay thế chẩn đoán y tế.',
            accent: NabiPalette.calmBlue,
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingAccordionCard(
            key: const Key('onboarding_consent_details'),
            title: 'Xem chi tiết',
            subtitle: 'Cách thông tin và AI được sử dụng.',
            icon: Icons.info_outline_rounded,
            expanded: _detailsExpanded,
            onToggle: () =>
                setState(() => _detailsExpanded = !_detailsExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Thông tin được lưu trong ứng dụng. Khi dùng AI văn bản hoặc phân tích ảnh, dữ liệu tối thiểu cần cho tác vụ được gửi qua HTTPS tới máy chủ NanoBio. Ứng dụng không dùng model văn bản hoặc ảnh cục bộ thay thế. Trợ lý ESP32 có thể tải Whisper để nhận dạng lời nói trên điện thoại. Cần đăng nhập để dùng AI của máy chủ.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
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
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 21),
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
                    height: 1.4,
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
