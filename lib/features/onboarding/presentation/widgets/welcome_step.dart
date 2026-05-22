import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/onboarding_controller.dart';
import 'onboarding_step_shell.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 0,
      totalSteps: 7,
      showBack: false,
      title: 'Chào mừng đến với BioAI',
      subtitle:
          'AI sẽ đồng hành cùng bạn để hiểu cơ thể, theo dõi thói quen và cá nhân hóa sức khỏe.',
      onNext: controller.nextStep,
      nextLabel: 'Bắt đầu hành trình',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 46,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Xây dựng hồ sơ sức khỏe cá nhân chỉ trong vài phút.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'BioAI sẽ dùng các dữ liệu này để tạo hồ sơ và lưu xuống SQLite nội bộ.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _FeatureCard(
            icon: Icons.analytics_outlined,
            title: 'Phân tích thông minh',
            subtitle:
                'Tự động tổng hợp BMI, thói quen, mục tiêu và tình trạng hiện tại.',
          ),
          const SizedBox(height: 12),
          const _FeatureCard(
            icon: Icons.storage_rounded,
            title: 'Lưu offline an toàn',
            subtitle:
                'Dữ liệu được lưu trong SQLite để dùng ngay cả khi không có mạng.',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
