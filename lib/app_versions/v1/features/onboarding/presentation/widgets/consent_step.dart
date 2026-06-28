import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

class ConsentStep extends ConsumerWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 6,
      title: 'Trước khi bắt đầu',
      subtitle:
          'NaBi đưa ra gợi ý chăm sóc hằng ngày, không thay thế chẩn đoán hay điều trị y tế.',
      onBack: controller.previousStep,
      nextLabel: 'Tôi hiểu và đồng ý',
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
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'NaBi cam kết',
            child: const Column(
              children: [
                _ConsentLine(
                  icon: Icons.lock_outline_rounded,
                  text:
                      'Bảo vệ dữ liệu hồ sơ và chỉ dùng để cá nhân hóa trải nghiệm.',
                ),
                SizedBox(height: 10),
                _ConsentLine(
                  icon: Icons.tips_and_updates_outlined,
                  text:
                      'Đưa ra lời nhắc, thực đơn và vận động phù hợp với thông tin bạn chọn.',
                ),
                SizedBox(height: 10),
                _ConsentLine(
                  icon: Icons.health_and_safety_outlined,
                  text:
                      'Khuyến khích bạn gặp chuyên gia khi có dấu hiệu cần theo dõi.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Bạn xác nhận',
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: state.agreed,
              onChanged: (value) => controller.setAgreed(value ?? false),
              title: Text(
                'Tôi hiểu đây là gợi ý hỗ trợ, không thay thế tư vấn bác sĩ.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: NabiPalette.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              activeColor: NabiPalette.royalBlue,
            ),
          ),
          const SizedBox(height: 12),
          const OnboardingInlineInfo(
            icon: Icons.edit_outlined,
            text:
                'Bạn có thể thay đổi hồ sơ và sở thích chăm sóc sau khi hoàn tất.',
          ),
        ],
      ),
    );
  }
}

class _ConsentLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConsentLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: NabiPalette.royalBlue),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: NabiPalette.mutedInk,
              height: 1.38,
            ),
          ),
        ),
      ],
    );
  }
}
