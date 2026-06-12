import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ConditionsStep extends ConsumerStatefulWidget {
  const ConditionsStep({super.key});

  @override
  ConsumerState<ConditionsStep> createState() => _ConditionsStepState();
}

class _ConditionsStepState extends ConsumerState<ConditionsStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: AppDuration.onboarding,
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final selectedCount = state.conditions.length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - 56) / 2;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _AnimatedHealthBackground(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -120,
          right: -80,
          child: _FloatingGlow(
            controller: _floatingController,
            size: 260,
            gradient: AppGradients.ai,
          ),
        ),

        Positioned(
          bottom: -160,
          left: -100,
          child: _FloatingGlow(
            controller: _floatingController,
            size: 320,
            gradient: AppGradients.health,
          ),
        ),

        SafeArea(
          child: OnboardingStepShell(
            stepIndex: 3,
            title: '',
            subtitle: '',
            onBack: controller.previousStep,
            onNext: controller.nextStep,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppearAnimation(
                    delay: 0,
                    child: _HeroCard(selectedCount: selectedCount),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _AppearAnimation(
                    delay: 100,
                    child: _SmartAnalysisCard(selectedCount: selectedCount),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Cơ thể bạn đang cảm thấy thế nào?',
                    subtitle:
                        'Bạn chọn những điều đang gặp phải để mình quan tâm và gợi ý cẩn thận hơn nhé.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _AppearAnimation(
                    delay: 200,
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: OnboardingCatalog.conditions.map((item) {
                        final selected = state.conditions.contains(item.code);

                        return _ConditionCard(
                          width: cardWidth,
                          emoji: item.emoji,
                          label: item.label,
                          selected: selected,
                          onTap: () {
                            controller.toggleCondition(item.code);
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Có điều gì khác bạn muốn kể với mình không?',
                    subtitle:
                        'Không cần dùng từ chuyên môn đâu, bạn cứ chia sẻ theo cách tự nhiên nhất.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _AppearAnimation(
                    delay: 300,
                    child: Container(
                      decoration: AppDecoration.card(
                        radius: AppRadius.xl,
                        shadows: AppShadows.soft,
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(
                        AppSpacing.cardPaddingLarge,
                      ),
                      child: OnboardingTextField(
                        label: 'Tình trạng khác',
                        hint:
                            'Ví dụ: đau đầu thường xuyên, dị ứng thực phẩm...',
                        initialValue: state.otherCondition,
                        onChanged: controller.updateOtherCondition,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _AppearAnimation(
                    delay: 400,
                    child: _HealthSummaryCard(selectedCount: selectedCount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int selectedCount;

  const _HeroCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: AppDecoration.glass(radius: AppRadius.circular),
                child: const Icon(
                  AppIcons.health,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecoration.glass(radius: AppRadius.circular),
                child: Row(
                  children: [
                    const Icon(AppIcons.ai, color: Colors.white, size: 18),

                    const SizedBox(width: AppSpacing.xs),

                    Text(
                      'AI Health',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Hồ sơ sức khỏe cá nhân',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'BioAI phân tích tình trạng sức khỏe hiện tại để xây dựng hệ thống chăm sóc phù hợp với cơ thể và mục tiêu của bạn.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.7,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  title: 'Đã chọn',
                  value: '$selectedCount mục',
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              const Expanded(
                child: _HeroMetric(title: 'Mình đang', value: 'Lắng nghe bạn'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String title;
  final String value;

  const _HeroMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.glass(radius: AppRadius.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartAnalysisCard extends StatelessWidget {
  final int selectedCount;

  const _SmartAnalysisCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.cardRaised,
        gradient: AppGradients.surface,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: AppDecoration.gradient(
              colors: const [AppColors.primary, AppColors.tertiary],
              radius: AppRadius.xl,
              shadows: AppShadows.primary,
            ),
            child: const Icon(
              AppIcons.heartRate,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phân tích thông minh',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  selectedCount == 0
                      ? 'Hãy chọn các tình trạng bạn đang gặp để BioAI bắt đầu xây dựng hồ sơ sức khỏe.'
                      : 'Dữ liệu sức khỏe đang được AI xử lý để tối ưu đề xuất dinh dưỡng và theo dõi sức khỏe.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.7)),
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final double width;
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionCard({
    required this.width,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.normal,
        curve: AppAnimations.emphasizedCurve,
        width: width,
        padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
        decoration: selected
            ? AppDecoration.gradient(
                colors: const [AppColors.primary, AppColors.tertiary],
                radius: AppRadius.xl,
                shadows: AppShadows.primary,
              )
            : AppDecoration.card(
                radius: AppRadius.xl,
                shadows: AppShadows.card,
                border: Border.all(color: AppColors.border),
              ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: AppDuration.normal,
              curve: AppAnimations.bounceCurve,
              child: Text(emoji, style: const TextStyle(fontSize: 38)),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            AnimatedContainer(
              duration: AppDuration.fast,
              width: 26,
              height: 26,
              decoration: AppDecoration.circle(
                color: selected ? Colors.white : AppColors.primarySoft,
              ),
              child: Icon(
                selected ? AppIcons.success : AppIcons.add,
                color: selected ? AppColors.primary : AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final int selectedCount;

  const _HealthSummaryCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.gradient(
        colors: const [AppColors.textPrimary, Color(0xFF1E293B)],
        radius: AppRadius.xxl,
        shadows: AppShadows.floating,
      ),
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: AppDecoration.glass(radius: AppRadius.xl),
                child: const Icon(AppIcons.ai, color: Colors.white, size: 28),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Health Insight',
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Đánh giá sơ bộ hồ sơ sức khỏe',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          _SummaryRow(
            icon: AppIcons.health,
            title: 'Tình trạng đã chọn',
            value: '$selectedCount',
          ),

          const SizedBox(height: AppSpacing.md),

          const _SummaryRow(
            icon: AppIcons.autoGraph,
            title: 'Mức độ thấu hiểu',
            value: 'Đang cập nhật',
          ),

          const SizedBox(height: AppSpacing.md),

          const _SummaryRow(
            icon: AppIcons.success,
            title: 'Đồng hành sức khỏe',
            value: 'Đang bật',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
          ),
        ),

        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AppearAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AppearAnimation({required this.child, required this.delay});

  @override
  State<_AppearAnimation> createState() => _AppearAnimationState();
}

class _AppearAnimationState extends State<_AppearAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: AppDuration.slow);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.smoothCurve,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAnimations.fadeSlide(child: widget.child, animation: _animation);
  }
}

class _FloatingGlow extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Gradient gradient;

  const _FloatingGlow({
    required this.controller,
    required this.size,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(controller.value * math.pi * 2) * 18,
            math.cos(controller.value * math.pi * 2) * 18,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      ),
    );
  }
}

class _AnimatedHealthBackground extends CustomPainter {
  final double animation;

  const _AnimatedHealthBackground({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = AppGradients.onboarding.createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final orbPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [AppColors.primary.withOpacity(0.10), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.8,
                size.height * (0.2 + animation * 0.1),
              ),
              radius: 180,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * (0.2 + animation * 0.1)),
      180,
      orbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimatedHealthBackground oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
