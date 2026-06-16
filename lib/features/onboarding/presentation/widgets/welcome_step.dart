import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingProvider.notifier);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _SoftBackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -100,
          right: -80,
          child: _FloatingCircle(
            controller: _floatingController,
            size: 220,
            color: AppColors.primary.withOpacity(0.05),
          ),
        ),

        Positioned(
          bottom: -140,
          left: -100,
          child: _FloatingCircle(
            controller: _floatingController,
            size: 280,
            color: AppColors.success.withOpacity(0.05),
          ),
        ),

        OnboardingStepShell(
          stepIndex: 0,
          totalSteps: 7,
          showBack: false,
          title: '',
          subtitle: '',
          nextLabel: 'Mình sẵn sàng rồi',
          onNext: controller.nextStep,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                const _WelcomeHeader(),

                const SizedBox(height: 28),

                const _InfoCard(),

                const SizedBox(height: 28),

                const _TitleSection(
                  title: 'Mình có thể giúp bạn những gì?',
                  subtitle:
                      'Mình sẽ cùng bạn chăm sóc sức khỏe mỗi ngày, nhẹ nhàng và dễ hiểu.',
                ),

                const SizedBox(height: 18),

                const _FeatureItem(
                  icon: Icons.monitor_heart_rounded,
                  title: 'Cùng nhìn lại sức khỏe mỗi ngày',
                  description:
                      'Mình giúp bạn ghi nhớ cân nặng, giấc ngủ và những thay đổi nhỏ của cơ thể.',
                ),

                const SizedBox(height: 14),

                const _FeatureItem(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Nghĩ món ăn phù hợp cùng bạn',
                  description:
                      'Thực đơn sẽ gần gũi, dễ áp dụng và tôn trọng tình trạng sức khỏe của bạn.',
                ),

                const SizedBox(height: 14),

                const _FeatureItem(
                  icon: Icons.notifications_active_rounded,
                  title: 'Nhắc bạn chăm mình đúng lúc',
                  description:
                      'Khi bận rộn, mình sẽ nhắc bạn uống nước, nghỉ ngơi và ngủ đủ.',
                ),

                const SizedBox(height: 28),

                const _HealthJourneyCard(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.16),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Text(
                  'BioAI',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Text(
            'Xin chào,\nchào mừng bạn đến với BioAI',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Ứng dụng sẽ đồng hành cùng bạn để theo dõi sức khỏe, ăn uống điều độ và sống khỏe hơn mỗi ngày.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.95),
              height: 1.8,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: const [
              Expanded(
                child: _MiniBox(title: 'Theo dõi', value: 'Dễ hiểu'),
              ),

              SizedBox(width: 12),

              Expanded(
                child: _MiniBox(title: 'Sử dụng', value: 'Đơn giản'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBox extends StatelessWidget {
  final String title;
  final String value;

  const _MiniBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin sức khỏe của bạn',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Các thông tin bạn cung cấp sẽ giúp hệ thống đưa ra hướng dẫn ăn uống và chăm sóc sức khỏe phù hợp hơn.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.8,
                    fontSize: 18,
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

class _TitleSection extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TitleSection({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontSize: 18,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    height: 1.8,
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

class _HealthJourneyCard extends StatelessWidget {
  const _HealthJourneyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Bắt đầu chăm sóc sức khỏe từ hôm nay',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Chỉ cần vài phút để hoàn thành khảo sát sức khỏe. BioAI sẽ hỗ trợ bạn theo dõi và cải thiện sức khỏe mỗi ngày.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontSize: 18,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _FloatingCircle({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(controller.value * math.pi * 2) * 14,
            math.cos(controller.value * math.pi * 2) * 14,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _SoftBackgroundPainter extends CustomPainter {
  final double animation;

  const _SoftBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.08),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }

    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
