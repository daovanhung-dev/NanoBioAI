import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class ResultStep extends StatefulWidget {
  final double healthScore;
  final String userName;
  final String message;
  final VoidCallback? onContinue;
  final VoidCallback? onRestart;

  const ResultStep({
    super.key,
    this.healthScore = 82,
    this.userName = 'Bạn',
    this.message = 'BioAI đã sẵn sàng đồng hành cùng bạn',
    this.onContinue,
    this.onRestart,
  });

  @override
  State<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<ResultStep> with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;
  late final AnimationController _scoreController;

  late final Animation<double> _scoreAnimation;

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

    _scoreController = AnimationController(
      vsync: this,
      duration: AppDuration.onboarding,
    );

    _scoreAnimation = Tween<double>(begin: 0, end: widget.healthScore).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: AppAnimations.decelerateCurve,
      ),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _scoreController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  bool get _excellent => widget.healthScore >= 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(
                    animation: _backgroundController.value,
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: -140,
            right: -80,
            child: _FloatingGlow(
              controller: _floatingController,
              size: 320,
              gradient: AppGradients.health,
            ),
          ),

          Positioned(
            bottom: -180,
            left: -120,
            child: _FloatingGlow(
              controller: _floatingController,
              size: 380,
              gradient: AppGradients.ai,
              reverse: true,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePaddingLarge,
                vertical: AppSpacing.pagePadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.large),

                  _AppearAnimation(
                    delay: 0,
                    child: _HeroSection(userName: widget.userName),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacingLarge),

                  _AppearAnimation(
                    delay: 120,
                    child: _ScoreCard(animation: _scoreAnimation),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  _AppearAnimation(
                    delay: 220,
                    child: _InsightPanel(score: widget.healthScore),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  _AppearAnimation(
                    delay: 320,
                    child: _JourneyPanel(message: widget.message),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  _AppearAnimation(
                    delay: 420,
                    child: const _ActivatedFeatures(),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacingLarge),

                  _AppearAnimation(
                    delay: 520,
                    child: _BottomSection(
                      onContinue: widget.onContinue,
                      onRestart: widget.onRestart,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String userName;

  const _HeroSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: AppDecoration.base(
            gradient: AppGradients.hero,
            shape: BoxShape.circle,
            shadows: AppShadows.floating,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: AppDecoration.glass(
                  radius: AppRadius.circular,
                  opacity: 0.12,
                ),
              ),
              const Icon(AppIcons.success, size: 58, color: Colors.white),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDecoration.base(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          child: Text(
            'AI HEALTH ANALYSIS COMPLETED',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        ShaderMask(
          shaderCallback: (bounds) {
            return AppGradients.hero.createShader(bounds);
          },
          child: Text(
            'Hoàn tất hồ sơ',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'Chúc mừng $userName! BioAI đã hoàn tất phân tích và cá nhân hóa hành trình chăm sóc sức khỏe cho bạn.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final Animation<double> animation;

  const _ScoreCard({required this.animation});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: AppDecoration.base(
            gradient: AppGradients.glass,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            shadows: AppShadows.soft,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: AppDecoration.primaryGradient(
                      radius: AppRadius.xl,
                    ),
                    child: const Icon(
                      AppIcons.heartRate,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Score',
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        Text(
                          'Chỉ số đánh giá sức khỏe toàn diện bởi AI',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxxl),

              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final value = animation.value.clamp(0, 100);

                  return SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: value / 100,
                            strokeWidth: 16,
                            strokeCap: StrokeCap.round,
                            backgroundColor: AppColors.border.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),

                        Container(
                          width: 188,
                          height: 188,
                          decoration: AppDecoration.base(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            shadows: AppShadows.sm,
                          ),
                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return AppGradients.primary.createShader(
                                  bounds,
                                );
                              },
                              child: Text(
                                value.toInt().toString(),
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xs),

                            Text(
                              '/100',
                              style: AppTextStyles.heading4.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: AppDecoration.gradient(
                  colors: const [AppColors.success, AppColors.secondary],
                  radius: AppRadius.circular,
                  shadows: AppShadows.success,
                ),
                child: Text(
                  'Realtime AI Monitoring Activated',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final double score;

  const _InsightPanel({required this.score});

  @override
  Widget build(BuildContext context) {
    final bool excellent = score >= 80;

    final String status = excellent ? 'Tình trạng rất tốt' : 'Sức khỏe ổn định';

    final String description = excellent
        ? 'AI nhận thấy bạn đang duy trì trạng thái sức khỏe rất tích cực và ổn định.'
        : 'BioAI đề xuất tiếp tục duy trì chế độ ăn uống và sinh hoạt lành mạnh hơn mỗi ngày.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: AppDecoration.glass(
                  radius: AppRadius.xl,
                  opacity: 0.14,
                ),
                child: const Icon(
                  AppIcons.stress,
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
                      'AI Insight',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Phân tích sức khỏe thông minh',
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
            title: 'Tình trạng của bạn',
            value: status,
          ),

          const SizedBox(height: AppSpacing.md),

          const _InsightTile(
            icon: AppIcons.notifications,
            title: 'Mình cùng theo dõi',
            value: 'Đã bật',
          ),

          const SizedBox(height: AppSpacing.md),

          const _InsightTile(
            icon: AppIcons.shield,
            title: 'Gợi ý thận trọng',
            value: 'Luôn lưu ý',
          ),

          const SizedBox(height: AppSpacing.xl),

          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecoration.glass(
              opacity: 0.12,
              radius: AppRadius.xl,
            ),
            child: Text(
              description,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPanel extends StatelessWidget {
  final String message;

  const _JourneyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumCard(),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: AppDecoration.base(
              gradient: AppGradients.health,
              shape: BoxShape.circle,
              shadows: AppShadows.success,
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 42)),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'BioAI sẽ theo dõi, phân tích và đưa ra các gợi ý dinh dưỡng, giấc ngủ và sức khỏe phù hợp với cơ thể của bạn.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivatedFeatures extends StatelessWidget {
  const _ActivatedFeatures();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.cardRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tính năng đã kích hoạt',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Các hệ thống AI và tracking đã sẵn sàng hoạt động.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          const _FeatureCard(
            icon: AppIcons.nutrition,
            title: 'Thực đơn mình chuẩn bị cho bạn',
            subtitle: 'Những món ăn phù hợp với mục tiêu của bạn',
            gradient: AppGradients.energy,
          ),

          const SizedBox(height: AppSpacing.md),

          const _FeatureCard(
            icon: AppIcons.sleep,
            title: 'Cùng chăm sóc giấc ngủ',
            subtitle: 'Mình giúp bạn nhìn lại và ngủ ngon hơn',
            gradient: AppGradients.sleep,
          ),

          const SizedBox(height: AppSpacing.md),

          const _FeatureCard(
            icon: AppIcons.health,
            title: 'Sức khỏe mỗi ngày',
            subtitle: 'Mình cùng bạn ghi nhận từng thay đổi nhỏ',
            gradient: AppGradients.health,
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
  final Gradient gradient;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.container(
        color: AppColors.cardAlt,
        radius: AppRadius.xl,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: AppDecoration.base(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              shadows: AppShadows.primary,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 36,
            height: 36,
            decoration: AppDecoration.base(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.success,
              color: AppColors.success,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onRestart;

  const _BottomSection({this.onContinue, this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onContinue,
          child: Container(
            width: double.infinity,
            height: 68,
            decoration: AppDecoration.primaryGradient(radius: AppRadius.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bắt đầu hành trình',
                  style: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                const Icon(AppIcons.forward, color: Colors.white),
              ],
            ),
          ),
        ),

        if (onRestart != null) ...[
          const SizedBox(height: AppSpacing.md),

          GestureDetector(
            onTap: onRestart,
            child: Container(
              width: double.infinity,
              height: 62,
              decoration: AppDecoration.outlined(
                radius: AppRadius.xl,
                borderColor: AppColors.border,
              ),
              child: Center(
                child: Text(
                  'Làm lại khảo sát',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
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
      curve: AppAnimations.emphasizedCurve,
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
  final bool reverse;

  const _FloatingGlow({
    required this.controller,
    required this.size,
    required this.gradient,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double x = math.sin(controller.value * math.pi * 2) * 24;

        final double y = math.cos(controller.value * math.pi * 2) * 24;

        return Transform.translate(
          offset: Offset(reverse ? -x : x, reverse ? -y : y),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              (gradient as LinearGradient).colors.first.withOpacity(0.16),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animation;

  const _BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        transform: GradientRotation(animation * math.pi * 2),
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.35),
          AppColors.secondarySoft.withOpacity(0.25),
          Colors.white,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, background);

    final Paint grid = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 36) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), grid);
    }

    for (double i = 0; i < size.height; i += 36) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
