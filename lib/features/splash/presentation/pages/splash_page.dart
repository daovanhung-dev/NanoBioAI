import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/router/router.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/features/splash/providers/splash_provider.dart';
import 'package:nano_app/features/splash/providers/splash_state.dart';
import '../../../../core/constants/constant.dart';
import '../../../../core/theme/theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.title = 'BioAI',
    this.subtitle = 'AI Health & Nutrition Assistant',
  });

  final String title;
  final String subtitle;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _checkApp();

    _pulseController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    )..repeat(reverse: true);

    Future.microtask(() {
      ref.read(splashProvider.notifier).initialize();
    });
  }

  Future<void> _checkApp() async {
    final completed = await AppPrefs.isOnboardingCompleted();

    debugPrint('ONBOARDING COMPLETED: $completed');

    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 1));

    if (completed) {
      AppNavigator.goMenu(context);
    } else {
      AppNavigator.goOnboarding(context);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SplashStatus>(splashProvider, (previous, next) {
      switch (next) {
        case SplashStatus.onboarded:
          AppNavigator.goDashboard(context);
          break;

        case SplashStatus.onboardingRequired:
          AppNavigator.goOnboarding(context);
          break;

        default:
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.primarySoft,
              AppColors.scaffold,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: -30,
              child: _Orb(
                size: 180,
                colors: [
                  AppColors.primary.withOpacity(0.30),
                  AppColors.primaryLight.withOpacity(0.08),
                ],
                controller: _pulseController,
                dxFactor: 18,
                dyFactor: 10,
              ),
            ),

            Positioned(
              bottom: -30,
              right: -20,
              child: _Orb(
                size: 220,
                colors: [
                  AppColors.secondary.withOpacity(0.24),
                  AppColors.info.withOpacity(0.06),
                ],
                controller: _pulseController,
                dxFactor: -14,
                dyFactor: -8,
              ),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: const SizedBox.expand(),
              ),
            ),

            SafeArea(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppDuration.slow,
                  curve: Curves.easeOutCubic,

                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: child,
                      ),
                    );
                  },

                  child: _SplashCard(
                    controller: _pulseController,
                    title: widget.title,
                    subtitle: widget.subtitle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashCard extends StatelessWidget {
  const _SplashCard({
    required this.controller,
    required this.title,
    required this.subtitle,
  });

  final AnimationController controller;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pulse = 0.5 + (0.5 * math.sin(controller.value * 2 * math.pi));
        final logoScale = 1.0 + (0.03 * pulse);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          decoration: AppDecoration.glass(
            opacity: 0.18,
            blurRadius: 16,
            radius: AppRadius.xl,
            borderColor: Colors.white.withOpacity(0.35),
          ).copyWith(boxShadow: AppShadows.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: logoScale,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: AppDecoration.circle(
                      gradient: AppGradients.primary,
                      shadows: AppShadows.primary,
                    ),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          AppIcons.health,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.50),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.65),
                    ),
                  ),
                  child: const _LoadingDots(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Personalized health companion',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    final controller = context
        .findAncestorStateOfType<_SplashPageState>()
        ?._pulseController;

    if (controller == null) {
      return const SizedBox(height: 20);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (controller.value + (index * 0.20)) % 1.0;
            final wave =
                0.35 + (0.65 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)));

            return Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(wave),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.colors,
    required this.controller,
    required this.dxFactor,
    required this.dyFactor,
  });

  final double size;
  final List<Color> colors;
  final AnimationController controller;
  final double dxFactor;
  final double dyFactor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulse = math.sin(controller.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(dxFactor * pulse, dyFactor * pulse),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors, stops: const [0.0, 1.0]),
        ),
      ),
    );
  }
}
