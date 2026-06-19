import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/theme/theme.dart';
import '../../providers/splash_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.title = 'Nami',
    this.subtitle =
        'Mình ở đây rồi. Hãy để Nami chuẩn bị một không gian thật dịu dàng để chăm sóc bạn hôm nay.',
  });

  final String title;
  final String subtitle;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: AppDuration.xSlow,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: AppDuration.pulse,
    )..repeat(reverse: true);

    Future.microtask(() async {
      await ref.read(splashProvider.notifier).initialize();
      await _handleRouting();
    });
  }

  Future<void> _handleRouting() async {
    final completed = await AppPrefs.isOnboardingCompleted();

    if (!mounted) return;

    await Future.delayed(AppDuration.loading);

    if (!mounted) return;

    if (completed) {
      V1AppNavigator.goMenu(context);
    } else {
      V1AppNavigator.goOnboarding(context);
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _SplashBackground(),

          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * math.pi * 2,
                    child: child,
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.2,
                      center: Alignment.center,
                      colors: [Color(0x1606B6D4), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: -120,
            left: -80,
            child: _AnimatedOrb(
              controller: _floatingController,
              size: 280,
              gradient: AppGradients.ai,
              opacity: 0.18,
              xFactor: 28,
              yFactor: 18,
            ),
          ),

          Positioned(
            bottom: -140,
            right: -100,
            child: _AnimatedOrb(
              controller: _floatingController,
              size: 340,
              gradient: AppGradients.hero,
              opacity: 0.14,
              xFactor: -24,
              yFactor: -16,
            ),
          ),

          Positioned(
            top: MediaQuery.paddingOf(context).top + 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: AppDecoration.glass(
                    opacity: 0.18,
                    radius: AppRadius.circular,
                    borderColor: Colors.white.withOpacity(0.18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'NAMI ĐANG Ở ĐÂY',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePaddingLarge,
                    92,
                    AppSpacing.pagePaddingLarge,
                    126,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight - 218),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final value = 0.96 + (_pulseController.value * 0.04);

                          return Transform.scale(scale: value, child: child);
                        },
                        child: _MainSplashCard(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          pulseController: _pulseController,
                          floatingController: _floatingController,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: 42,
            left: 24,
            right: 24,
            child: Column(
              children: [
                const _ProgressLoader(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nami đang sắp xếp mọi thứ thật gọn gàng cho bạn. Chỉ một chút nữa thôi nhé.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                    height: 1.45,
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

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.primarySoft,
            AppColors.secondarySoft,
            AppColors.scaffold,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainSplashCard extends StatelessWidget {
  const _MainSplashCard({
    required this.title,
    required this.subtitle,
    required this.pulseController,
    required this.floatingController,
  });

  final String title;
  final String subtitle;
  final AnimationController pulseController;
  final AnimationController floatingController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPaddingXl),
      decoration: AppDecoration.glass(
        opacity: 0.22,
        radius: AppRadius.xxl,
        borderColor: Colors.white.withOpacity(0.25),
        shadows: AppShadows.xl,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedLogo(
                pulseController: pulseController,
                floatingController: floatingController,
              ),
              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: AppDecoration.gradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.secondary.withOpacity(0.10),
                  ],
                  radius: AppRadius.circular,
                ),
                child: Text(
                  'NAMI · NGƯỜI ĐỒNG HÀNH CỦA BẠN',
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.primaryDark,
                    letterSpacing: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              ShaderMask(
                shaderCallback: (bounds) {
                  return AppGradients.hero.createShader(bounds);
                },
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const _CareMessage(),

              const SizedBox(height: AppSpacing.xl),

              Row(
                children: const [
                  Expanded(
                    child: _FeatureCard(
                      icon: AppIcons.health,
                      title: 'Nhịp khỏe',
                      subtitle: 'Nami lắng nghe thật nhẹ',
                      gradient: AppGradients.health,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _FeatureCard(
                      icon: AppIcons.ai,
                      title: 'Gợi ý riêng',
                      subtitle: 'Vừa với cơ thể bạn',
                      gradient: AppGradients.ai,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                children: const [
                  Expanded(
                    child: _FeatureCard(
                      icon: AppIcons.sleep,
                      title: 'Giấc ngủ',
                      subtitle: 'Cùng bạn nghỉ sâu hơn',
                      gradient: AppGradients.sleep,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _FeatureCard(
                      icon: AppIcons.nutrition,
                      title: 'Bữa ăn',
                      subtitle: 'Ấm bụng, hợp cơ thể',
                      gradient: AppGradients.energy,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              const _LoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareMessage extends StatelessWidget {
  const _CareMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(
        opacity: 0.12,
        radius: AppRadius.xl,
        borderColor: Colors.white.withOpacity(0.14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: AppDecoration.circle(
              gradient: AppGradients.primary,
              shadows: AppShadows.sm,
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Hôm nay mình sẽ đi chậm cùng bạn: từng bữa ăn, từng giấc ngủ, từng thói quen nhỏ đều sẽ được chăm chút.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({
    required this.pulseController,
    required this.floatingController,
  });

  final AnimationController pulseController;
  final AnimationController floatingController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseController, floatingController]),
      builder: (context, _) {
        final pulse =
            1 + (math.sin(pulseController.value * math.pi * 2) * 0.04);

        final dy = math.sin(floatingController.value * math.pi * 2) * 8;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: pulse,
            child: Container(
              width: 132,
              height: 132,
              decoration: AppDecoration.circle(
                gradient: AppGradients.futuristic,
                shadows: AppShadows.primary,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: AppDecoration.glass(
                      opacity: 0.18,
                      radius: AppRadius.circular,
                      borderColor: Colors.white.withOpacity(0.25),
                    ),
                    child: const Icon(
                      AppIcons.health,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.glass(
        opacity: 0.12,
        radius: AppRadius.xl,
        borderColor: Colors.white.withOpacity(0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppDecoration.circle(
              gradient: gradient,
              shadows: AppShadows.sm,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SplashPageState>();

    final controller = state?._pulseController;

    if (controller == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final phase = (controller.value + (index * 0.15)) % 1;

            final scale = 0.7 + (math.sin(phase * math.pi * 2) * 0.3);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.primary,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ProgressLoader extends StatelessWidget {
  const _ProgressLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: const BoxDecoration(gradient: AppGradients.hero),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  const _AnimatedOrb({
    required this.controller,
    required this.size,
    required this.gradient,
    required this.opacity,
    required this.xFactor,
    required this.yFactor,
  });

  final AnimationController controller;
  final double size;
  final Gradient gradient;
  final double opacity;
  final double xFactor;
  final double yFactor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = math.sin(controller.value * math.pi * 2);

        return Transform.translate(
          offset: Offset(value * xFactor, value * yFactor),
          child: child,
        );
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..strokeWidth = 1;

    const gap = 36.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
