import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
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
    final state = ref.watch(onboardingProvider);

    final controller = ref.read(onboardingProvider.notifier);

    final completedFields = _calculateCompletedFields(state);

    final progress = completedFields / 6;

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
          top: -120,
          right: -80,
          child: _FloatingGlow(
            size: 280,
            color: AppColors.primary.withOpacity(0.12),
            controller: _floatingController,
          ),
        ),

        Positioned(
          bottom: -140,
          left: -90,
          child: _FloatingGlow(
            size: 340,
            color: AppColors.secondary.withOpacity(0.12),
            controller: _floatingController,
          ),
        ),

        Positioned.fill(
          child: OnboardingStepShell(
            stepIndex: 5,
            title: '',
            subtitle: '',
            isScrollable: false,
            onBack: controller.previousStep,
            onNext: () {
              if (!state.agreed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bạn cần đồng ý với điều khoản sử dụng trước khi chúng ta tiếp tục nhé.',
                    ),
                  ),
                );
                return;
              }
              controller.nextStep();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppSpacing.pagePadding,
                right: AppSpacing.pagePadding,
                bottom: AppSpacing.xxxl,
                top: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Appear(
                    delay: 0,
                    child: _HeroSection(
                      progress: progress,
                      completedFields: completedFields,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _Appear(
                    delay: 80,
                    child: _AiStatusCard(completedFields: completedFields),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Có món nào bạn cần tránh không?',
                    subtitle:
                        'Bạn cứ chia sẻ thật kỹ, mình sẽ ghi nhớ để gợi ý món ăn an toàn hơn.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _Appear(
                    delay: 140,
                    child: _SurfaceCard(
                      child: Column(
                        children: [
                          _FieldTile(
                            icon: AppIcons.warning,
                            title: 'Dị ứng / thực phẩm cần tránh',
                            child: OnboardingTextField(
                              label: 'Thông tin dị ứng',
                              hint: 'Ví dụ: Hải sản, sữa, đậu phộng, gluten...',
                              initialValue: state.allergyName,
                              onChanged: controller.updateAllergyName,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          _FieldTile(
                            icon: AppIcons.document,
                            title: 'Ghi chú thêm',
                            child: OnboardingTextField(
                              label: 'Mô tả thêm',
                              hint: 'Mức độ dị ứng, thực phẩm cần hạn chế...',
                              maxLines: 3,
                              initialValue: state.allergyNote,
                              onChanged: controller.updateAllergyNote,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Bạn đang điều trị hoặc dùng thuốc gì không?',
                    subtitle:
                        'Thông tin này giúp mình thận trọng hơn khi đồng hành cùng bạn.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _Appear(
                    delay: 220,
                    child: _SurfaceCard(
                      child: Column(
                        children: [
                          _FieldTile(
                            icon: AppIcons.health,
                            title: 'Điều trị hiện tại',
                            child: OnboardingTextField(
                              label: 'Điều trị / theo dõi',
                              hint: 'Ví dụ: Theo dõi huyết áp, tiểu đường...',
                              initialValue: state.treatmentName,
                              onChanged: controller.updateTreatmentName,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          _FieldTile(
                            icon: AppIcons.nutrition,
                            title: 'Thuốc đang sử dụng',
                            child: OnboardingTextField(
                              label: 'Tên thuốc',
                              hint: 'Có thể bỏ trống nếu không có',
                              initialValue: state.medicationName,
                              onChanged: controller.updateMedicationName,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          _FieldTile(
                            icon: AppIcons.edit,
                            title: 'Ghi chú điều trị',
                            child: OnboardingTextField(
                              label: 'Thông tin bổ sung',
                              hint:
                                  'Ví dụ: Theo dõi định kỳ, bác sĩ khuyến nghị...',
                              maxLines: 4,
                              initialValue: state.treatmentNote,
                              onChanged: controller.updateTreatmentNote,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    title: 'Gần đây bạn lo lắng điều gì nhất?',
                    subtitle:
                        'Bạn cứ nói như đang trò chuyện với mình, mình đang lắng nghe.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _Appear(
                    delay: 320,
                    child: _SurfaceCard(
                      child: OnboardingTextField(
                        label: 'Mối quan tâm sức khỏe',
                        hint:
                            'Ví dụ: Stress, mất ngủ, thiếu năng lượng, giảm cân...',
                        maxLines: 5,
                        initialValue: state.concernText,
                        onChanged: controller.updateConcernText,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _Appear(
                    delay: 420,
                    child: _CommitmentCard(
                      agreed: state.agreed,
                      onChanged: controller.setAgreed,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _Appear(
                    delay: 520,
                    child: _InsightCard(
                      completedFields: completedFields,
                      agreed: state.agreed,
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

  int _calculateCompletedFields(dynamic state) {
    int count = 0;

    if (state.allergyName.toString().trim().isNotEmpty) count++;

    if (state.allergyNote.toString().trim().isNotEmpty) count++;

    if (state.treatmentName.toString().trim().isNotEmpty) count++;

    if (state.medicationName.toString().trim().isNotEmpty) count++;

    if (state.treatmentNote.toString().trim().isNotEmpty) count++;

    if (state.concernText.toString().trim().isNotEmpty) count++;

    return count;
  }
}

class _HeroSection extends StatelessWidget {
  final double progress;
  final int completedFields;

  const _HeroSection({required this.progress, required this.completedFields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: AppDecoration.glass(
                  radius: AppRadius.circular,
                  opacity: 0.16,
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
                  radius: AppRadius.circular,
                  opacity: 0.12,
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.star, color: Colors.white, size: 18),

                    const SizedBox(width: AppSpacing.xs),

                    Text(
                      'BioAI Core',
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
            'Hoàn thiện\nhồ sơ sức khỏe',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Những dữ liệu này giúp hệ thống AI xây dựng phân tích chính xác và cá nhân hóa hơn cho bạn.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.92),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _HeroInfo(
                  title: 'Đã hoàn thành',
                  value: '$completedFields/6',
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              const Expanded(
                child: _HeroInfo(title: 'Mình đã hiểu', value: 'Sẵn sàng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfo extends StatelessWidget {
  final String title;
  final String value;

  const _HeroInfo({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(radius: AppRadius.lg, opacity: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusCard extends StatelessWidget {
  final int completedFields;

  const _AiStatusCard({required this.completedFields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.glass(radius: AppRadius.xl, opacity: 0.7),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
            child: const Icon(AppIcons.health, color: Colors.white, size: 30),
          ),

          const SizedBox(width: AppSpacing.md),

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

                const SizedBox(height: AppSpacing.xs),

                Text(
                  completedFields == 0
                      ? 'Bắt đầu bổ sung dữ liệu để BioAI tạo hồ sơ sức khỏe cho bạn.'
                      : 'BioAI đang xây dựng phân tích dinh dưỡng & sức khỏe nâng cao.',
                  style: AppTextStyles.bodyMedium,
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

        const SizedBox(height: AppSpacing.xs),

        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        shadows: AppShadows.soft,
        gradient: AppGradients.surface,
      ),
      child: child,
    );
  }
}

class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FieldTile({
    required this.icon,
    required this.title,
    required this.child,
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
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;

  const _CommitmentCard({required this.agreed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.normal,
      curve: AppAnimations.smoothCurve,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: agreed
          ? AppDecoration.primaryGradient(radius: AppRadius.xxl)
          : AppDecoration.card(
              radius: AppRadius.xxl,
              border: Border.all(color: AppColors.border),
              shadows: AppShadows.soft,
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final switchControl = Transform.scale(
            scale: 1.05,
            child: Switch(value: agreed, onChanged: onChanged),
          );

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đồng ý với điều khoản sử dụng',
                style: AppTextStyles.heading4.copyWith(
                  color: agreed ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Tôi đã đọc, hiểu và đồng ý để BioAI sử dụng những thông tin tôi chia sẻ nhằm cá nhân hóa trải nghiệm chăm sóc sức khỏe.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: agreed
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 320) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                switchControl,
                const SizedBox(height: AppSpacing.md),
                textContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              switchControl,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: textContent),
            ],
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final int completedFields;
  final bool agreed;

  const _InsightCard({required this.completedFields, required this.agreed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: AppDecoration.glass(
                  radius: AppRadius.lg,
                  opacity: 0.12,
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
                      'AI Insight',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxs),

                    Text(
                      'Tổng quan hồ sơ BioAI',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.84),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          _InsightRow(
            icon: AppIcons.checkIn,
            title: 'Thông tin đã nhập',
            value: '$completedFields mục',
          ),

          const SizedBox(height: AppSpacing.md),

          _InsightRow(
            icon: AppIcons.success,
            title: 'Cam kết sức khỏe',
            value: agreed ? 'Đã đồng ý' : 'Chưa đồng ý',
          ),

          const SizedBox(height: AppSpacing.md),

          const _InsightRow(
            icon: AppIcons.dashboard,
            title: 'Trợ lý của bạn',
            value: 'Đã sẵn sàng',
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: AppDecoration.glass(radius: AppRadius.lg, opacity: 0.08),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
          ),

          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Appear extends StatefulWidget {
  final Widget child;
  final int delay;

  const _Appear({required this.child, required this.delay});

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.onboarding,
    );

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
    return AppAnimations.fadeSlide(animation: _animation, child: widget.child);
  }
}

class _FloatingGlow extends StatelessWidget {
  final double size;
  final Color color;
  final AnimationController controller;

  const _FloatingGlow({
    required this.size,
    required this.color,
    required this.controller,
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
        decoration: AppDecoration.circle(color: color),
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
          AppColors.secondarySoft.withOpacity(0.45),
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
