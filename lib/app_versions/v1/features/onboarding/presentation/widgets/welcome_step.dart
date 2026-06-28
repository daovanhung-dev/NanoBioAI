import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingProvider.notifier);
    final enabled = ref.watch(onboardingAiDevCheckEnabledProvider);
    final check = enabled ? ref.watch(onboardingAiDevCheckProvider) : null;

    return OnboardingStepShell(
      stepIndex: 0,
      showBack: false,
      title: 'Chào bạn, mình là NaBi',
      subtitle:
          'Mình sẽ lắng nghe nhịp sống của bạn và cùng bạn tạo một hành trình chăm sóc cơ thể thật vừa vặn.',
      nextLabel: 'Bắt đầu cùng NaBi',
      onNext: controller.nextStep,
      child: Column(
        children: [
          const Center(child: NabiCompanionAvatar(size: 124)),
          const SizedBox(height: 8),
          const NabiAssistantMessage(
            message: 'Rất vui được gặp bạn.',
            subtitle:
                'Chỉ vài lựa chọn ngắn thôi, NaBi sẽ chuẩn bị những gợi ý phù hợp với riêng bạn.',
          ),
          const SizedBox(height: 10),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: [
              NabiMoodPill(
                icon: Icons.favorite_rounded,
                label: 'Luôn đồng hành',
                color: NabiPalette.rose,
              ),
              NabiMoodPill(
                icon: Icons.auto_awesome_rounded,
                label: 'Cá nhân hoá',
                color: NabiPalette.violet,
              ),
              NabiMoodPill(
                icon: Icons.lock_outline_rounded,
                label: 'Riêng tư',
                color: NabiPalette.cyan,
              ),
            ],
          ),
          const SizedBox(height: 13),
          OnboardingSectionCard(
            title: 'NaBi sẽ giúp bạn',
            subtitle:
                'Không phải những lời nhắc chung chung, mà là lịch trình theo nhịp sống của bạn.',
            child: const Column(
              children: [
                _Feature(
                  icon: Icons.restaurant_menu_rounded,
                  color: NabiPalette.cyan,
                  title: 'Ăn uống vừa sức',
                  text:
                      'Gợi ý bữa ăn và vận động phù hợp với mục tiêu của bạn.',
                ),
                SizedBox(height: 9),
                _Feature(
                  icon: Icons.notifications_active_outlined,
                  color: NabiPalette.violet,
                  title: 'Đồng hành đúng lúc',
                  text: 'Nhắc bạn chăm cơ thể theo thời gian biểu riêng.',
                ),
                SizedBox(height: 9),
                _Feature(
                  icon: Icons.psychology_alt_outlined,
                  color: NabiPalette.amber,
                  title: 'Biết lắng nghe',
                  text:
                      'Điều chỉnh gợi ý khi thói quen và mục tiêu của bạn thay đổi.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const OnboardingInlineInfo(
            icon: Icons.timer_outlined,
            text:
                'Mất khoảng 2–3 phút. Bạn luôn có thể quay lại chỉnh sửa hồ sơ sau này.',
          ),
          if (check != null) ...[
            const SizedBox(height: 10),
            _AiCheck(check: check),
          ],
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
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
              const SizedBox(height: 1),
              Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: NabiPalette.mutedInk,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiCheck extends StatelessWidget {
  final AsyncValue<AIConnectionCheckResult?> check;

  const _AiCheck({required this.check});

  @override
  Widget build(BuildContext context) {
    return check.when(
      loading: () => const OnboardingInlineInfo(
        icon: Icons.sync_rounded,
        text: 'NaBi đang kiểm tra kết nối trợ lý...',
      ),
      error: (_, __) => const OnboardingInlineInfo(
        icon: Icons.warning_amber_rounded,
        text: 'NaBi chưa thể kiểm tra kết nối lúc này.',
      ),
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return OnboardingInlineInfo(
          icon: result.success
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          text: result.success
              ? 'NaBi đã sẵn sàng: ${result.modelName ?? 'trợ lý đã kết nối'}.'
              : result.message,
        );
      },
    );
  }
}
