import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/onboarding_controller.dart';
import 'health_chip.dart';
import 'onboarding_step_shell.dart';

class LifestyleStep extends ConsumerStatefulWidget {
  const LifestyleStep({super.key});

  @override
  ConsumerState<LifestyleStep> createState() => _LifestyleStepState();
}

class _LifestyleStepState extends ConsumerState<LifestyleStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
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

    final selectedHabits = state.habits.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _LifestyleBackgroundPainter(
                    animation: _backgroundController.value,
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: -120,
            right: -80,
            child: _FloatingOrb(
              controller: _floatingController,
              size: 300,
              gradient: AppGradients.ai,
            ),
          ),

          Positioned(
            bottom: -140,
            left: -90,
            child: _FloatingOrb(
              controller: _floatingController,
              size: 340,
              gradient: AppGradients.health,
              reverse: true,
            ),
          ),

          SafeArea(
            child: OnboardingStepShell(
              stepIndex: 4,
              title: '',
              subtitle: '',
              onBack: controller.previousStep,
              onNext: controller.nextStep,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AppearAnimation(
                      delay: 0,
                      child: _HeroSection(selectedHabits: selectedHabits),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacingLarge),

                    _AppearAnimation(
                      delay: 120,
                      child: _LifestyleOverviewCard(
                        selectedHabits: selectedHabits,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacingLarge),

                    _AppearAnimation(
                      delay: 200,
                      child: _ModernSectionHeader(
                        icon: AppIcons.nutrition,
                        title: 'Lifestyle Habits',
                        subtitle:
                            'BioAI sẽ học từ hành vi sinh hoạt hằng ngày để cá nhân hóa kế hoạch sức khỏe.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    _AppearAnimation(
                      delay: 260,
                      child: _HabitsGrid(state: state, controller: controller),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacingLarge),

                    _AppearAnimation(
                      delay: 340,
                      child: _ModernSectionHeader(
                        icon: AppIcons.sleep,
                        title: 'Sleep & Activity',
                        subtitle:
                            'Giấc ngủ, vận động và lượng nước sẽ ảnh hưởng trực tiếp tới AI Health Score.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    _AppearAnimation(
                      delay: 420,
                      child: _GlassContainer(
                        child: Column(
                          children: [
                            _ModernDropdown(
                              label: 'Giấc ngủ hiện tại',
                              icon: AppIcons.sleep,
                              gradient: AppGradients.sleep,
                              value: state.sleepQuality,
                              items: OnboardingCatalog.sleepQualities,
                              onChanged: (value) {
                                if (value != null) {
                                  controller.updateSleepQuality(value);
                                }
                              },
                            ),

                            const SizedBox(height: AppSpacing.formFieldSpacing),

                            _ModernDropdown(
                              label: 'Mức độ vận động',
                              icon: AppIcons.fitness,
                              gradient: AppGradients.health,
                              value: state.activityLevel,
                              items: OnboardingCatalog.activityLevels,
                              onChanged: (value) {
                                if (value != null) {
                                  controller.updateActivityLevel(value);
                                }
                              },
                            ),

                            const SizedBox(height: AppSpacing.formFieldSpacing),

                            _ModernDropdown(
                              label: 'Lượng nước mỗi ngày',
                              icon: AppIcons.water,
                              gradient: AppGradients.info,
                              value: state.waterPerDay,
                              items: OnboardingCatalog.waterIntakeOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  controller.updateWaterPerDay(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacingLarge),

                    _AppearAnimation(
                      delay: 520,
                      child: _AIInsightCard(
                        selectedHabits: selectedHabits,
                        sleepQuality: state.sleepQuality,
                        activityLevel: state.activityLevel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final int selectedHabits;

  const _HeroSection({required this.selectedHabits});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: AppDecoration.glass(
                  radius: AppRadius.circular,
                  opacity: 0.14,
                ),
                child: const Icon(
                  AppIcons.meditation,
                  color: Colors.white,
                  size: 38,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecoration.glass(
                  radius: AppRadius.circular,
                  opacity: 0.12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),

                    const SizedBox(width: AppSpacing.iconTextSpacing),

                    Text(
                      'AI Lifestyle',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Lifestyle &\nHealthy Routine',
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'BioAI phân tích toàn bộ thói quen sinh hoạt để xây dựng hệ thống chăm sóc sức khỏe AI-first cá nhân hóa.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.88),
              height: 1.7,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  title: 'Habits',
                  value: '$selectedHabits Selected',
                  icon: AppIcons.health,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              const Expanded(
                child: _HeroMetric(
                  title: 'AI Sync',
                  value: 'Realtime',
                  icon: AppIcons.chat,
                ),
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
  final IconData icon;

  const _HeroMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.glass(opacity: 0.12, radius: AppRadius.xl),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: AppDecoration.circle(
              color: Colors.white.withOpacity(0.14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _LifestyleOverviewCard extends StatelessWidget {
  final int selectedHabits;

  const _LifestyleOverviewCard({required this.selectedHabits});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.premiumCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: AppDecoration.gradient(
              colors: const [AppColors.primary, AppColors.tertiary],
              radius: AppRadius.xl,
              shadows: AppShadows.primary,
            ),
            child: const Icon(AppIcons.health, color: Colors.white, size: 32),
          ),

          const SizedBox(width: AppSpacing.lg),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Lifestyle Summary',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  selectedHabits == 0
                      ? 'Hãy chọn các thói quen để AI xây dựng hồ sơ sinh hoạt thông minh.'
                      : 'BioAI đang đồng bộ dữ liệu lifestyle để tối ưu nutrition, sleep và health tracking.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ModernSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
          child: Icon(icon, color: Colors.white, size: 24),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.65),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitsGrid extends StatelessWidget {
  final dynamic state;
  final dynamic controller;

  const _HabitsGrid({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: OnboardingCatalog.habits.map((item) {
        final selected = state.habits.contains(item.code);

        return AnimatedScale(
          duration: AppDuration.fast,
          scale: selected ? 1 : 0.96,
          child: HealthChip(
            label: item.label,
            emoji: item.emoji,
            selected: selected,
            onTap: () => controller.toggleHabit(item.code),
          ),
        );
      }).toList(),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ModernDropdown({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: AppDecoration.base(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                shadows: AppShadows.md,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        DropdownButtonFormField<String>(
          value: value != null && value!.isNotEmpty ? value : null,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: AppTextStyles.bodyMedium),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(AppIcons.expand, color: AppColors.textSecondary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: 'Select option',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.inputLarge),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.inputLarge),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.inputLarge),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.glass(
        opacity: 0.82,
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _AIInsightCard extends StatelessWidget {
  final int selectedHabits;
  final String sleepQuality;
  final String activityLevel;

  const _AIInsightCard({
    required this.selectedHabits,
    required this.sleepQuality,
    required this.activityLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.base(
        gradient: AppGradients.futuristic,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        shadows: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: AppDecoration.glass(
                  opacity: 0.12,
                  radius: AppRadius.xl,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Lifestyle Insight',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Health behavior analytics',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          _InsightTile(
            icon: AppIcons.health,
            title: 'Selected Habits',
            value: '$selectedHabits',
          ),

          const SizedBox(height: AppSpacing.md),

          _InsightTile(
            icon: AppIcons.sleep,
            title: 'Sleep Quality',
            value: sleepQuality.isEmpty ? '--' : sleepQuality,
          ),

          const SizedBox(height: AppSpacing.md),

          _InsightTile(
            icon: AppIcons.fitness,
            title: 'Activity Level',
            value: activityLevel.isEmpty ? '--' : activityLevel,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(opacity: 0.1, radius: AppRadius.xl),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: AppDecoration.circle(
              color: Colors.white.withOpacity(0.12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),

          const SizedBox(width: AppSpacing.md),

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
      ),
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
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

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

    _offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.decelerateCurve,
          ),
        );

    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smoothCurve),
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
      child: SlideTransition(
        position: _offset,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Gradient gradient;
  final bool reverse;

  const _FloatingOrb({
    required this.controller,
    required this.size,
    required this.gradient,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final value = reverse ? 1 - controller.value : controller.value;

        return Transform.translate(
          offset: Offset(
            math.sin(value * math.pi * 2) * 18,
            math.cos(value * math.pi * 2) * 18,
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

class _LifestyleBackgroundPainter extends CustomPainter {
  final double animation;

  const _LifestyleBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.65),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 36) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    for (double i = 0; i < size.height; i += 36) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LifestyleBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
