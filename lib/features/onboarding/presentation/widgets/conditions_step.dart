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

    final selectedCount = state.conditions.length;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConditionsBackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -100,
          right: -60,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 260,
            color: AppColors.error.withOpacity(0.08),
          ),
        ),

        Positioned(
          bottom: -120,
          left: -70,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 300,
            color: AppColors.warning.withOpacity(0.08),
          ),
        ),

        Positioned.fill(
          child: SafeArea(
            child: OnboardingStepShell(
              stepIndex: 3,
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
                      child: _HeaderSection(selectedCount: selectedCount),
                    ),

                    const SizedBox(height: 28),

                    _AnimatedAppear(
                      delay: 100,
                      child: _AIHealthAlertCard(selectedCount: selectedCount),
                    ),

                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: 'Tình trạng sức khỏe',
                      subtitle:
                          'Chọn đúng các vấn đề bạn đang gặp để BioAI hiểu cơ thể bạn tốt hơn.',
                    ),

                    const SizedBox(height: 18),

                    _AnimatedAppear(
                      delay: 200,
                      child: _ConditionsGrid(
                        state: state,
                        controller: controller,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: 'Tình trạng khác',
                      subtitle:
                          'Nếu bạn có vấn đề sức khỏe khác chưa được liệt kê.',
                    ),

                    const SizedBox(height: 18),

                    _AnimatedAppear(
                      delay: 350,
                      child: _GlassCard(
                        child: OnboardingTextField(
                          label: 'Tình trạng khác',
                          hint: 'Nhập tình trạng sức khỏe khác...',
                          initialValue: state.otherCondition,
                          onChanged: controller.updateOtherCondition,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _AnimatedAppear(
                      delay: 450,
                      child: _HealthInsightCard(selectedCount: selectedCount),
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

  const _HeaderSection({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: LinearGradient(colors: [AppColors.error, AppColors.warning]),
        boxShadow: AppShadows.danger,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 34,
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology_alt_rounded,
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

          const SizedBox(height: 28),

          Text(
            'Tình trạng sức khỏe',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'BioAI sẽ dựa trên dữ liệu sức khỏe hiện tại để xây dựng hồ sơ AI cá nhân hóa.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _MiniStat(title: 'Đã chọn', value: '$selectedCount mục'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(title: 'AI Status', value: 'Đang phân tích'),
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
              color: Colors.white.withOpacity(0.82),
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

class _AIHealthAlertCard extends StatelessWidget {
  final int selectedCount;

  const _AIHealthAlertCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.glass(
        opacity: 0.72,
        blurRadius: 20,
        radius: AppRadius.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error, AppColors.warning],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
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
                  'AI Health Detection',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  selectedCount == 0
                      ? 'Hãy chọn các tình trạng bạn đang gặp.'
                      : 'BioAI đang tối ưu phân tích dựa trên dữ liệu sức khỏe của bạn.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
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

class _ConditionsGrid extends StatelessWidget {
  final dynamic state;
  final dynamic controller;

  const _ConditionsGrid({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: OnboardingCatalog.conditions.map((item) {
        final selected = state.conditions.contains(item.code);

        return GestureDetector(
          onTap: () => controller.toggleCondition(item.code),
          child: AnimatedContainer(
            duration: AppDuration.normal,
            curve: Curves.easeOutCubic,
            width: 160,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(colors: [AppColors.error, AppColors.warning])
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: selected ? Colors.transparent : AppColors.border,
              ),
              boxShadow: selected ? AppShadows.danger : AppShadows.xs,
            ),
            child: Column(
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: AppDuration.normal,
                  child: Text(item.emoji, style: const TextStyle(fontSize: 36)),
                ),

                const SizedBox(height: 16),

                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

class _HealthInsightCard extends StatelessWidget {
  final int selectedCount;

  const _HealthInsightCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.error, AppColors.warning]),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.danger,
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
                      'AI Insight',
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Đánh giá sơ bộ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _InsightRow(
            icon: Icons.favorite_rounded,
            title: 'Tình trạng đã chọn',
            value: '$selectedCount',
          ),

          const SizedBox(height: 16),

          const _InsightRow(
            icon: Icons.auto_graph_rounded,
            title: 'AI Status',
            value: 'Đang xử lý',
          ),

          const SizedBox(height: 16),

          const _InsightRow(
            icon: Icons.health_and_safety_rounded,
            title: 'Health Risk',
            value: 'Đang đánh giá',
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

class _ConditionsBackgroundPainter extends CustomPainter {
  final double animation;

  const _ConditionsBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.errorSoft.withOpacity(0.5),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final gridPaint = Paint()
      ..color = AppColors.error.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConditionsBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
