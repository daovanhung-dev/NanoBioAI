import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class GoalsStep extends ConsumerStatefulWidget {
  const GoalsStep({super.key});

  @override
  ConsumerState<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends ConsumerState<GoalsStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: AppDuration.loading,
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
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final goals = OnboardingCatalog.goals;
    final selectedGoals = state.goals;
    final selectedCount = selectedGoals.length;

    final progress = goals.isEmpty ? 0.0 : selectedCount / goals.length;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (_, __) {
              return CustomPaint(
                painter: _BackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -80,
          right: -50,
          child: _FloatingBlur(
            controller: _floatingController,
            size: 240,
            gradient: AppGradients.ai,
          ),
        ),

        Positioned(
          bottom: -120,
          left: -60,
          child: _FloatingBlur(
            controller: _floatingController,
            size: 300,
            gradient: AppGradients.health,
          ),
        ),

        Positioned.fill(
          child: OnboardingStepShell(
            stepIndex: 2,
            title: '',
            subtitle: '',
            isScrollable: false,
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
                    child: _HeroSection(
                      selectedCount: selectedCount,
                      progress: progress,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _AppearAnimation(
                    delay: 100,
                    child: _OverviewCard(
                      selectedCount: selectedCount,
                      progress: progress,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Bạn muốn mình giúp điều gì trước?',
                    subtitle:
                        'Chọn những điều quan trọng với bạn, chúng ta sẽ đi từng bước cùng nhau.',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _AppearAnimation(
                    delay: 180,
                    child: _GoalsGrid(state: state, controller: controller),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Còn mong muốn nào bạn chưa thấy ở trên?',
                    subtitle:
                        'Bạn cứ kể thêm bằng lời của mình, mình sẽ ghi nhớ.',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _AppearAnimation(
                    delay: 280,
                    child: Container(
                      padding: const EdgeInsets.all(
                        AppSpacing.cardPaddingLarge,
                      ),
                      decoration: AppDecoration.glass(
                        opacity: 0.92,
                        radius: AppRadius.cardLarge,
                      ),
                      child: OnboardingTextField(
                        label: 'Mục tiêu bổ sung',
                        hint:
                            'Ví dụ: Mình muốn tập trung tốt hơn và bớt mệt...',
                        initialValue: state.otherGoal,
                        onChanged: controller.updateOtherGoal,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _AppearAnimation(
                    delay: 420,
                    child: _InsightCard(
                      progress: progress,
                      selectedCount: selectedCount,
                    ),
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

class _HeroSection extends StatelessWidget {
  final int selectedCount;
  final double progress;

  const _HeroSection({required this.selectedCount, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.primaryGradient(radius: AppRadius.xxxl),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: AppDecoration.circle(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: AppDecoration.circle(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: AppDecoration.glass(
                      opacity: 0.18,
                      radius: AppRadius.circular,
                    ),
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
                    decoration: AppDecoration.glass(
                      opacity: 0.12,
                      radius: AppRadius.circular,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'AI Personalized',
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
                'Thiết lập mục tiêu\nsức khỏe',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'BioAI sẽ sử dụng AI để xây dựng lộ trình dinh dưỡng, luyện tập và theo dõi sức khỏe dựa trên các mục tiêu bạn chọn.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Đã chọn',
                      value: '$selectedCount mục tiêu',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(title: 'Hoàn thành', value: '$percent%'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(opacity: 0.14, radius: AppRadius.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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

class _OverviewCard extends StatelessWidget {
  final int selectedCount;
  final double progress;

  const _OverviewCard({required this.selectedCount, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.premiumCard(),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: AppDecoration.gradient(
              colors: const [AppColors.primary, AppColors.secondary],
              radius: AppRadius.xl,
              shadows: AppShadows.primary,
            ),
            child: const Icon(
              AppIcons.auto_awesome_rounded,
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
                  'AI Goal Analysis',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  selectedCount == 0
                      ? 'Hãy chọn mục tiêu để BioAI bắt đầu cá nhân hóa trải nghiệm.'
                      : 'BioAI đang tối ưu hệ thống dựa trên $selectedCount mục tiêu bạn đã chọn.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                ),

                const SizedBox(height: AppSpacing.md),

                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Mục tiêu đã chọn',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}

class _GoalsGrid extends StatelessWidget {
  final dynamic state;
  final dynamic controller;

  const _GoalsGrid({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;

        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 800) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          itemCount: OnboardingCatalog.goals.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 158,
          ),
          itemBuilder: (_, index) {
            final goal = OnboardingCatalog.goals[index];

            final selected = state.goals.contains(goal.code);

            return _GoalItem(
              selected: selected,
              emoji: goal.emoji,
              label: goal.label,
              onTap: () {
                controller.toggleGoal(goal.code);
              },
            );
          },
        );
      },
    );
  }
}

class _GoalItem extends StatelessWidget {
  final bool selected;
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _GoalItem({
    required this.selected,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDuration.card,
          curve: AppAnimations.emphasizedCurve,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: selected
              ? AppDecoration.gradient(
                  colors: const [AppColors.primary, AppColors.secondary],
                  radius: AppRadius.cardLarge,
                  shadows: AppShadows.primary,
                )
              : AppDecoration.card(
                  radius: AppRadius.cardLarge,
                  border: Border.all(color: AppColors.border),
                  shadows: AppShadows.soft,
                ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: AnimatedScale(
                  scale: selected ? 1 : 0.92,
                  duration: AppDuration.normal,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: AppDecoration.circle(
                      color: selected
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.primarySoft,
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      color: selected ? Colors.white : AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      duration: AppDuration.normal,
                      scale: selected ? 1.12 : 1,
                      child: Text(emoji, style: const TextStyle(fontSize: 40)),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final double progress;
  final int selectedCount;

  const _InsightCard({required this.progress, required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.gradient(
        colors: const [AppColors.success, AppColors.secondary],
        radius: AppRadius.xxxl,
        shadows: AppShadows.success,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: AppDecoration.glass(
                  opacity: 0.14,
                  radius: AppRadius.xl,
                ),
                child: const Icon(
                  AppIcons.stress,
                  color: Colors.white,
                  size: 28,
                ),
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

                    const SizedBox(height: AppSpacing.xxs),

                    Text(
                      'Đánh giá định hướng sức khỏe',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.84),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecoration.glass(
                  opacity: 0.12,
                  radius: AppRadius.circular,
                ),
                child: Text(
                  '$percent%',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          _InsightTile(
            icon: AppIcons.flag,
            title: 'Mục tiêu đã chọn',
            value: '$selectedCount',
          ),

          const SizedBox(height: AppSpacing.md),

          const _InsightTile(
            icon: AppIcons.health,
            title: 'Mình đang',
            value: 'Tìm hiểu mục tiêu',
          ),

          const SizedBox(height: AppSpacing.md),

          const _InsightTile(
            icon: AppIcons.success,
            title: 'Theo dõi cùng bạn',
            value: 'Đang bật',
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white),

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

  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.onboarding,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.smoothCurve,
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.decelerateCurve,
          ),
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _FloatingBlur extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Gradient gradient;

  const _FloatingBlur({
    required this.controller,
    required this.size,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
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

class _BackgroundPainter extends CustomPainter {
  final double animation;

  const _BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.7),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += 42) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    for (double i = 0; i <= size.height; i += 42) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
