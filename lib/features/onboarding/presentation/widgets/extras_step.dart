import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ExtrasStep extends ConsumerStatefulWidget {
  const ExtrasStep({super.key});

  @override
  ConsumerState<ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends ConsumerState<ExtrasStep>
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

    final completedFields = _calculateCompletedFields(state);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ExtrasBackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -100,
          right: -70,
          child: _FloatingOrb(
            controller: _floatingController,
            size: 260,
            color: AppColors.secondary.withOpacity(0.08),
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
              stepIndex: 5,
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
                      child: _HeaderSection(completedFields: completedFields),
                    ),

                    const SizedBox(height: 28),

                    _AnimatedAppear(
                      delay: 100,
                      child: _HealthSummaryCard(
                        completedFields: completedFields,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: 'Thông tin dị ứng',
                      subtitle:
                          'Những thông tin này giúp BioAI tránh các thực phẩm không phù hợp.',
                    ),

                    const SizedBox(height: 18),

                    _AnimatedAppear(
                      delay: 200,
                      child: _GlassCard(
                        child: Column(
                          children: [
                            _InputWrapper(
                              icon: Icons.no_food_rounded,
                              child: OnboardingTextField(
                                label: 'Dị ứng hoặc kiêng thực phẩm',
                                hint: 'Ví dụ: hải sản, sữa, đậu phộng...',
                                initialValue: state.allergyName,
                                onChanged: controller.updateAllergyName,
                              ),
                            ),

                            const SizedBox(height: 20),

                            _InputWrapper(
                              icon: Icons.description_rounded,
                              child: OnboardingTextField(
                                label: 'Ghi chú dị ứng',
                                hint: 'Nếu có thêm mô tả...',
                                initialValue: state.allergyNote,
                                maxLines: 3,
                                onChanged: controller.updateAllergyNote,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: 'Thông tin điều trị',
                      subtitle:
                          'BioAI sẽ dựa vào dữ liệu này để đưa ra gợi ý phù hợp hơn.',
                    ),

                    const SizedBox(height: 18),

                    _AnimatedAppear(
                      delay: 300,
                      child: _GlassCard(
                        child: Column(
                          children: [
                            _InputWrapper(
                              icon: Icons.medication_rounded,
                              child: OnboardingTextField(
                                label: 'Đang điều trị / thuốc đang dùng',
                                hint: 'Nếu không có, để trống',
                                initialValue: state.treatmentName,
                                onChanged: controller.updateTreatmentName,
                              ),
                            ),

                            const SizedBox(height: 20),

                            _InputWrapper(
                              icon: Icons.local_hospital_rounded,
                              child: OnboardingTextField(
                                label: 'Tên thuốc',
                                hint: 'Nếu có',
                                initialValue: state.medicationName,
                                onChanged: controller.updateMedicationName,
                              ),
                            ),

                            const SizedBox(height: 20),

                            _InputWrapper(
                              icon: Icons.edit_note_rounded,
                              child: OnboardingTextField(
                                label: 'Ghi chú điều trị',
                                hint: 'Ví dụ: đang theo dõi bác sĩ...',
                                initialValue: state.treatmentNote,
                                maxLines: 4,
                                onChanged: controller.updateTreatmentNote,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: 'Mối quan tâm sức khỏe',
                      subtitle:
                          'Hãy chia sẻ điều bạn lo lắng nhất để BioAI đồng hành cùng bạn.',
                    ),

                    const SizedBox(height: 18),

                    _AnimatedAppear(
                      delay: 400,
                      child: _GlassCard(
                        child: OnboardingTextField(
                          label: 'Điều bạn lo lắng nhất về sức khỏe',
                          hint: 'Chia sẻ ngắn gọn...',
                          initialValue: state.concernText,
                          maxLines: 5,
                          onChanged: controller.updateConcernText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _AnimatedAppear(
                      delay: 500,
                      child: _AgreementSection(
                        agreed: state.agreed,
                        onChanged: controller.setAgreed,
                      ),
                    ),

                    const SizedBox(height: 28),

                    _AnimatedAppear(
                      delay: 600,
                      child: _AIInsightCard(
                        completedFields: completedFields,
                        agreed: state.agreed,
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

  int _calculateCompletedFields(dynamic state) {
    int count = 0;

    if (state.allergyName.toString().isNotEmpty) {
      count++;
    }

    if (state.allergyNote.toString().isNotEmpty) {
      count++;
    }

    if (state.treatmentName.toString().isNotEmpty) {
      count++;
    }

    if (state.medicationName.toString().isNotEmpty) {
      count++;
    }

    if (state.treatmentNote.toString().isNotEmpty) {
      count++;
    }

    if (state.concernText.toString().isNotEmpty) {
      count++;
    }

    return count;
  }
}

class _HeaderSection extends StatelessWidget {
  final int completedFields;

  const _HeaderSection({required this.completedFields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: AppGradients.primary,
        boxShadow: AppShadows.primary,
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
                  Icons.health_and_safety_rounded,
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

          const SizedBox(height: 28),

          Text(
            'Thông tin bổ sung',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Những thông tin này giúp BioAI tạo hồ sơ sức khỏe đầy đủ và chính xác hơn.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: 'Hoàn thành',
                  value: '$completedFields mục',
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: _MiniStat(title: 'AI Status', value: 'Đang tối ưu'),
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

class _HealthSummaryCard extends StatelessWidget {
  final int completedFields;

  const _HealthSummaryCard({required this.completedFields});

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
              gradient: AppGradients.primary,
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
                  'AI Health Summary',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  completedFields == 0
                      ? 'Hãy bổ sung thêm thông tin để AI phân tích chính xác hơn.'
                      : 'BioAI đang xây dựng hồ sơ sức khỏe nâng cao cho bạn.',
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

class _InputWrapper extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _InputWrapper({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: Colors.white),
        ),

        const SizedBox(width: 16),

        Expanded(child: child),
      ],
    );
  }
}

class _AgreementSection extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;

  const _AgreementSection({required this.agreed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: agreed ? AppGradients.primary : null,
        color: agreed ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: agreed ? Colors.transparent : AppColors.border,
        ),
        boxShadow: agreed ? AppShadows.primary : AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Switch(value: agreed, onChanged: onChanged),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cam kết đồng hành',
                  style: AppTextStyles.heading4.copyWith(
                    color: agreed ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Sức khỏe được cải thiện nhờ thay đổi thói quen và sự kiên trì mỗi ngày.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: agreed
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.textSecondary,
                    height: 1.6,
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

class _AIInsightCard extends StatelessWidget {
  final int completedFields;
  final bool agreed;

  const _AIInsightCard({required this.completedFields, required this.agreed});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      'Đánh giá nâng cao',
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
            icon: Icons.health_and_safety_rounded,
            title: 'Thông tin đã nhập',
            value: '$completedFields',
          ),

          const SizedBox(height: 16),

          _InsightRow(
            icon: Icons.handshake_rounded,
            title: 'Cam kết',
            value: agreed ? 'Đã đồng ý' : 'Chưa đồng ý',
          ),

          const SizedBox(height: 16),

          const _InsightRow(
            icon: Icons.auto_graph_rounded,
            title: 'AI Status',
            value: 'Đang tối ưu',
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

class _ExtrasBackgroundPainter extends CustomPainter {
  final double animation;

  const _ExtrasBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.45),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExtrasBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
