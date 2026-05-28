import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/onboarding_controller.dart';
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
      duration: const Duration(seconds: 12),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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

    final selectedCount = state.goals.length;
    final totalGoals = OnboardingCatalog.goals.length;
    final progress = totalGoals == 0 ? 0.0 : selectedCount / totalGoals;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _GoalsBackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),
        Positioned(
          top: -100,
          right: -80,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 260,
            color: AppColors.success.withOpacity(0.08),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -80,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 320,
            color: AppColors.primary.withOpacity(0.08),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: OnboardingStepShell(
              stepIndex: 2,
              title: '',
              subtitle: '',
              onBack: controller.previousStep,
              onNext: controller.nextStep,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedAppear(
                      delay: 0,
                      child: _HeaderSection(
                        selectedCount: selectedCount,
                        progress: progress,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedAppear(
                      delay: 100,
                      child: _GoalSummaryCard(
                        selectedCount: selectedCount,
                        progress: progress,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Mục tiêu sức khỏe',
                      subtitle:
                          'Chọn một hoặc nhiều mục tiêu để BioAI cá nhân hóa lộ trình phù hợp.',
                    ),
                    const SizedBox(height: 16),
                    _AnimatedAppear(
                      delay: 180,
                      child: _GoalsGrid(state: state, controller: controller),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Mục tiêu bổ sung',
                      subtitle: 'Nếu bạn có thêm mục tiêu cá nhân khác.',
                    ),
                    const SizedBox(height: 16),
                    _AnimatedAppear(
                      delay: 300,
                      child: _GlassCard(
                        child: OnboardingTextField(
                          label: 'Mục tiêu khác',
                          hint: 'Nếu có thêm mục tiêu...',
                          initialValue: state.otherGoal,
                          onChanged: controller.updateOtherGoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _AnimatedAppear(
                      delay: 420,
                      child: _GoalInsightCard(
                        selectedCount: selectedCount,
                        progress: progress,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int selectedCount;
  final double progress;

  const _HeaderSection({required this.selectedCount, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D8CFF), Color(0xFF18A8E4)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D8CFF).withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -18,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -26,
            left: -14,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BioAI',
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
              const SizedBox(height: 24),
              Text(
                'Mục tiêu sức khỏe',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'BioAI sẽ xây dựng lộ trình cá nhân hóa dựa trên các mục tiêu sức khỏe của bạn.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.94),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      title: 'Đã chọn',
                      value: '$selectedCount mục',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(title: 'Hoàn thiện', value: '$percent%'),
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

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.84),
            ),
          ),
          const SizedBox(height: 8),
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

class _GoalSummaryCard extends StatelessWidget {
  final int selectedCount;
  final double progress;

  const _GoalSummaryCard({required this.selectedCount, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.glass(
        opacity: 0.74,
        blurRadius: 20,
        radius: AppRadius.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Goal Tracking',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedCount == 0
                      ? 'Hãy chọn mục tiêu để AI xây dựng lộ trình phù hợp.'
                      : 'BioAI đang tối ưu lộ trình theo $selectedCount mục tiêu bạn đã chọn.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.primarySoft.withOpacity(0.35),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$percent% mục tiêu đã được định hướng',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
      ],
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
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 700 ? 3 : 2;
        final mainAxisExtent = width >= 700 ? 146.0 : 138.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: OnboardingCatalog.goals.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final goal = OnboardingCatalog.goals[index];
            final selected = state.goals.contains(goal.code);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.toggleGoal(goal.code),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: AnimatedContainer(
                  duration: AppDuration.normal,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.success, AppColors.primary],
                          )
                        : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.border.withOpacity(0.72),
                    ),
                    boxShadow: selected ? AppShadows.primary : AppShadows.xs,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: AnimatedScale(
                          scale: selected ? 1 : 0.95,
                          duration: AppDuration.normal,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.18)
                                  : AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.08 : 1,
                              duration: AppDuration.normal,
                              child: Text(
                                goal.emoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              goal.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
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
          },
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _GoalInsightCard extends StatelessWidget {
  final int selectedCount;
  final double progress;

  const _GoalInsightCard({required this.selectedCount, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Goal Insight',
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đánh giá mục tiêu của bạn',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
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
          const SizedBox(height: 24),
          _InsightRow(
            icon: Icons.flag_rounded,
            title: 'Mục tiêu đã chọn',
            value: '$selectedCount',
          ),
          const SizedBox(height: 16),
          const _InsightRow(
            icon: Icons.auto_graph_rounded,
            title: 'AI Status',
            value: 'Đang tối ưu',
          ),
          const SizedBox(height: 16),
          const _InsightRow(
            icon: Icons.health_and_safety_rounded,
            title: 'Tracking',
            value: 'Đã kích hoạt',
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
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

class _AnimatedAppear extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedAppear({required this.child, required this.delay});

  @override
  State<_AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<_AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _FloatingOrb({
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

class _GoalsBackgroundPainter extends CustomPainter {
  final double animation;

  const _GoalsBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.success.withOpacity(0.08),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final gridPaint = Paint()
      ..color = AppColors.success.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalsBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
