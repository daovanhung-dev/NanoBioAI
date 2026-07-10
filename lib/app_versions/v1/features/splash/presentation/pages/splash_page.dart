import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';

import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../../domain/services/splash_route_decision.dart';
import '../../providers/splash_provider.dart';

enum _BootStage { preparing, checkingProfile, ready }

extension _BootStagePresentation on _BootStage {
  String get statusLabel {
    switch (this) {
      case _BootStage.preparing:
        return 'ĐANG KHỞI TẠO';
      case _BootStage.checkingProfile:
        return 'ĐANG KIỂM TRA';
      case _BootStage.ready:
        return 'SẴN SÀNG';
    }
  }

  String get title {
    switch (this) {
      case _BootStage.preparing:
        return 'Đang chuẩn bị không gian của bạn';
      case _BootStage.checkingProfile:
        return 'Đang xác định điểm bắt đầu phù hợp';
      case _BootStage.ready:
        return 'Mọi thứ đã sẵn sàng';
    }
  }

  String get description {
    switch (this) {
      case _BootStage.preparing:
        return 'NaBi đang khởi tạo những thành phần cần thiết để trải nghiệm diễn ra mượt mà.';
      case _BootStage.checkingProfile:
        return 'NaBi đang kiểm tra để đưa bạn đến đúng bước tiếp theo trong hành trình.';
      case _BootStage.ready:
        return 'Không gian chăm sóc cá nhân của bạn đã sẵn sàng để bắt đầu.';
    }
  }

  IconData get icon {
    switch (this) {
      case _BootStage.preparing:
        return Icons.auto_awesome_rounded;
      case _BootStage.checkingProfile:
        return Icons.account_tree_outlined;
      case _BootStage.ready:
        return Icons.verified_rounded;
    }
  }

  Color get accent {
    switch (this) {
      case _BootStage.preparing:
        return NabiPalette.violet;
      case _BootStage.checkingProfile:
        return NabiPalette.cyan;
      case _BootStage.ready:
        return NabiPalette.rose;
    }
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.title = 'NaBi',
    this.subtitle =
        'Một không gian nhỏ để lắng nghe cơ thể, chăm sóc thói quen và bắt đầu ngày mới theo cách vừa vặn với bạn.',
  });

  final String title;
  final String subtitle;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  bool _hasNavigated = false;
  bool _reduceMotion = false;
  _BootStage _bootStage = _BootStage.preparing;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    Future.microtask(_bootstrap);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final shouldReduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (_reduceMotion == shouldReduceMotion &&
        (_ambientController.isAnimating || shouldReduceMotion)) {
      return;
    }

    _reduceMotion = shouldReduceMotion;

    if (_reduceMotion) {
      _ambientController
        ..stop()
        ..value = 0.5;

      _pulseController
        ..stop()
        ..value = 0.5;

      _entryController.value = 1;
      return;
    }

    if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }

    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    if (!_entryController.isCompleted) {
      _entryController.forward();
    }
  }

  Future<void> _bootstrap() async {
    _setStage(_BootStage.preparing);

    final onboardingCompletedFuture = _readOnboardingCompletedSafely();

    await Future.wait([
      _initializeSafely(),
      Future<void>.delayed(AppDuration.loading),
      _advanceToProfileCheckStage(),
    ]);

    final onboardingCompleted = await onboardingCompletedFuture;

    if (!mounted || _hasNavigated) return;

    _setStage(_BootStage.ready);

    final target = const SplashRouteDecision().resolve(
      hasAuthenticatedSession: currentSupabaseUserIdOrNull() != null,
      onboardingCompleted: onboardingCompleted,
    );

    _navigate(target);
  }

  Future<void> _advanceToProfileCheckStage() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));

    if (!mounted || _hasNavigated) return;
    _setStage(_BootStage.checkingProfile);
  }

  void _setStage(_BootStage stage) {
    if (!mounted || _bootStage == stage) return;

    setState(() {
      _bootStage = stage;
    });
  }

  Future<void> _initializeSafely() async {
    try {
      await ref.read(splashProvider.notifier).initialize();
    } catch (error, stackTrace) {
      debugPrint('Splash initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> _readOnboardingCompletedSafely() async {
    try {
      return await AppPrefs.isOnboardingCompleted();
    } catch (error, stackTrace) {
      debugPrint('Unable to read onboarding state: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  void _navigate(SplashRouteTarget target) {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    switch (target) {
      case SplashRouteTarget.authGate:
        V1AppNavigator.goAuthGate(context);
        break;
      case SplashRouteTarget.onboardingEntry:
        V1AppNavigator.goOnboardingEntry(context);
        break;
      case SplashRouteTarget.menu:
        V1AppNavigator.goMenu(context);
        break;
      case SplashRouteTarget.onboarding:
        V1AppNavigator.goOnboarding(context);
        break;
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _SplashAtmosphere(
                controller: _ambientController,
                reduceMotion: _reduceMotion,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _SplashLayout.fromConstraints(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                    vertical: layout.verticalPadding,
                  ),
                  child: Column(
                    children: [
                      _SplashTopBar(
                        stage: _bootStage,
                        pulseController: _pulseController,
                        compact: layout.isCompact,
                      ),
                      SizedBox(height: layout.headerGap),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _entryController,
                                curve: Curves.easeOutCubic,
                              ),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 0.035),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _entryController,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: _SplashExperience(
                                  title: widget.title,
                                  subtitle: widget.subtitle,
                                  stage: _bootStage,
                                  layout: layout,
                                  ambientController: _ambientController,
                                  pulseController: _pulseController,
                                  reduceMotion: _reduceMotion,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: layout.footerGap),
                      _LoadingFooter(
                        stage: _bootStage,
                        controller: _ambientController,
                        compact: layout.isCompact,
                        showDescription: layout.showFooterDescription,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLayout {
  final bool isCompact;
  final bool showWellnessTags;
  final bool showFooterDescription;
  final bool showPrivacyCaption;
  final double horizontalPadding;
  final double verticalPadding;
  final double headerGap;
  final double footerGap;
  final double brandMarkSize;

  const _SplashLayout({
    required this.isCompact,
    required this.showWellnessTags,
    required this.showFooterDescription,
    required this.showPrivacyCaption,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.headerGap,
    required this.footerGap,
    required this.brandMarkSize,
  });

  factory _SplashLayout.fromConstraints({
    required double width,
    required double height,
  }) {
    final isCompact = width < 365 || height < 630;

    return _SplashLayout(
      isCompact: isCompact,
      showWellnessTags: width >= 355 && height >= 660,
      showFooterDescription: height >= 590,
      showPrivacyCaption: width >= 340 && height >= 620,
      horizontalPadding: width < 360
          ? 20
          : width < 700
          ? 27
          : 48,
      verticalPadding: isCompact ? 14 : 22,
      headerGap: isCompact ? 14 : 21,
      footerGap: isCompact ? 13 : 21,
      brandMarkSize: isCompact
          ? 86
          : width >= 700
          ? 118
          : 106,
    );
  }
}

class _SplashAtmosphere extends StatelessWidget {
  const _SplashAtmosphere({
    required this.controller,
    required this.reduceMotion,
  });

  final AnimationController controller;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            Color.lerp(AppColors.background, NabiPalette.violet, 0.08)!,
            Color.lerp(AppColors.background, NabiPalette.cyan, 0.09)!,
            AppColors.background,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SplashAtmospherePainter(
              phase: reduceMotion ? 0.5 : controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _SplashAtmospherePainter extends CustomPainter {
  const _SplashAtmospherePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(phase * math.pi * 2);
    final inverseWave = math.cos(phase * math.pi * 2);

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 64);

    glowPaint.color = NabiPalette.violet.withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.12 + (wave * 22), size.height * 0.15),
      size.width * 0.22,
      glowPaint,
    );

    glowPaint.color = NabiPalette.cyan.withValues(alpha: 0.14);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.76 + (inverseWave * 24)),
      size.width * 0.29,
      glowPaint,
    );

    glowPaint.color = NabiPalette.rose.withValues(alpha: 0.09);
    canvas.drawCircle(
      Offset(size.width * 0.48 + (inverseWave * 18), size.height * 0.49),
      size.width * 0.18,
      glowPaint,
    );

    final linePaint = Paint()
      ..color = NabiPalette.violet.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final upperWave = Path()
      ..moveTo(-20, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * (0.14 + (wave * 0.025)),
        size.width + 20,
        size.height * 0.28,
      );

    final lowerWave = Path()
      ..moveTo(-20, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * (0.64 + (inverseWave * 0.03)),
        size.width + 20,
        size.height * 0.79,
      );

    canvas.drawPath(upperWave, linePaint);
    canvas.drawPath(lowerWave, linePaint);

    final particlePaint = Paint()..color = Colors.white.withValues(alpha: 0.50);

    for (var index = 0; index < 8; index++) {
      final fraction = index / 8;
      final x = size.width * (0.06 + fraction * 0.9);
      final y =
          size.height *
          (0.12 + ((math.sin((phase * math.pi * 2) + index) + 1) * 0.32));

      canvas.drawCircle(Offset(x, y), index.isEven ? 1.75 : 1.2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAtmospherePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _SplashTopBar extends StatelessWidget {
  const _SplashTopBar({
    required this.stage,
    required this.pulseController,
    required this.compact,
  });

  final _BootStage stage;
  final AnimationController pulseController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _LaunchStatusPill(
              stage: stage,
              pulseController: pulseController,
              compact: compact,
            ),
          ),
        ),
        if (!compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
            ),
            child: Text(
              'CHĂM SÓC CÁ NHÂN',
              style: AppTextStyles.overline.copyWith(
                color: NabiPalette.mutedInk,
                fontSize: 8.4,
                height: 1,
                letterSpacing: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _LaunchStatusPill extends StatelessWidget {
  const _LaunchStatusPill({
    required this.stage,
    required this.pulseController,
    required this.compact,
  });

  final _BootStage stage;
  final AnimationController pulseController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: stage.statusLabel,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, _) {
          final pulse = 0.78 + (pulseController.value * 0.22);

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
              boxShadow: [
                BoxShadow(
                  color: stage.accent.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stage.accent,
                      boxShadow: [
                        BoxShadow(
                          color: stage.accent.withValues(alpha: 0.42),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  stage.statusLabel,
                  style: AppTextStyles.overline.copyWith(
                    color: NabiPalette.mutedInk,
                    fontSize: compact ? 8.4 : 9,
                    height: 1,
                    letterSpacing: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SplashExperience extends StatelessWidget {
  const _SplashExperience({
    required this.title,
    required this.subtitle,
    required this.stage,
    required this.layout,
    required this.ambientController,
    required this.pulseController,
    required this.reduceMotion,
  });

  final String title;
  final String subtitle;
  final _BootStage stage;
  final _SplashLayout layout;
  final AnimationController ambientController;
  final AnimationController pulseController;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NaBi đang chuẩn bị trải nghiệm chăm sóc sức khỏe cá nhân',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: _BrandMark(
              size: layout.brandMarkSize,
              ambientController: ambientController,
              pulseController: pulseController,
              reduceMotion: reduceMotion,
            ),
          ),
          SizedBox(height: layout.isCompact ? 16 : 21),
          _EyebrowLabel(compact: layout.isCompact),
          SizedBox(height: layout.isCompact ? 10 : 13),
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [NabiPalette.violet, NabiPalette.cyan],
              ).createShader(bounds);
            },
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displayMedium.copyWith(
                color: Colors.white,
                fontSize: layout.isCompact ? 34 : 42,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ),
          SizedBox(height: layout.isCompact ? 11 : 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              subtitle,
              maxLines: layout.isCompact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: NabiPalette.mutedInk,
                fontSize: layout.isCompact ? 13 : 15,
                height: 1.52,
              ),
            ),
          ),
          if (layout.showWellnessTags) ...[
            const SizedBox(height: 20),
            const _WellnessTags(),
          ],
          SizedBox(height: layout.isCompact ? 20 : 25),
          _ReadinessPanel(
            stage: stage,
            compact: layout.isCompact,
            showPrivacyCaption: layout.showPrivacyCaption,
            pulseController: pulseController,
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.size,
    required this.ambientController,
    required this.pulseController,
    required this.reduceMotion,
  });

  final double size;
  final AnimationController ambientController;
  final AnimationController pulseController;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ambientController, pulseController]),
      builder: (context, _) {
        final phase = reduceMotion ? 0.5 : ambientController.value;
        final floatingOffset = reduceMotion
            ? 0.0
            : math.sin(phase * math.pi * 2) * 5;
        final scale = reduceMotion
            ? 1.0
            : 0.985 + (pulseController.value * 0.025);

        return Transform.translate(
          offset: Offset(0, floatingOffset),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(size),
                    painter: _BrandOrbitPainter(phase: phase),
                  ),
                  Container(
                    width: size * 0.66,
                    height: size * 0.66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [NabiPalette.violet, NabiPalette.cyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NabiPalette.violet.withValues(alpha: 0.25),
                          blurRadius: 27,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: EdgeInsets.all(size * 0.08),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: size * 0.28,
                      ),
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

class _BrandOrbitPainter extends CustomPainter {
  const _BrandOrbitPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = NabiPalette.violet.withValues(alpha: 0.22);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = NabiPalette.cyan.withValues(alpha: 0.21);

    canvas.drawCircle(center, size.width * 0.46, outerPaint);
    canvas.drawCircle(center, size.width * 0.37, innerPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = NabiPalette.violet.withValues(alpha: 0.86);

    final arcRect = Rect.fromCircle(center: center, radius: size.width * 0.46);

    canvas.drawArc(
      arcRect,
      phase * math.pi * 2,
      math.pi * 0.42,
      false,
      arcPaint,
    );

    final angle = (phase * math.pi * 2) - (math.pi / 3);
    final dotRadius = size.width * 0.46;

    final dotCenter = Offset(
      center.dx + math.cos(angle) * dotRadius,
      center.dy + math.sin(angle) * dotRadius,
    );

    canvas.drawCircle(
      dotCenter,
      size.width * 0.035,
      Paint()..color = NabiPalette.cyan,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandOrbitPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: NabiPalette.violet.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: NabiPalette.violet.withValues(alpha: 0.14)),
      ),
      child: Text(
        'SỨC KHỎE THEO CÁCH CỦA BẠN',
        style: AppTextStyles.overline.copyWith(
          color: NabiPalette.violet,
          fontSize: compact ? 8 : 8.8,
          height: 1,
          letterSpacing: 1.08,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WellnessTags extends StatelessWidget {
  const _WellnessTags();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _WellnessTag(
          icon: Icons.restaurant_outlined,
          label: 'Ăn uống cân bằng',
          color: NabiPalette.cyan,
        ),
        _WellnessTag(
          icon: Icons.directions_walk_rounded,
          label: 'Vận động phù hợp',
          color: NabiPalette.violet,
        ),
        _WellnessTag(
          icon: Icons.notifications_active_outlined,
          label: 'Nhắc đúng lúc',
          color: NabiPalette.rose,
        ),
      ],
    );
  }
}

class _WellnessTag extends StatelessWidget {
  const _WellnessTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: NabiPalette.ink,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({
    required this.stage,
    required this.compact,
    required this.showPrivacyCaption,
    required this.pulseController,
  });

  final _BootStage stage;
  final bool compact;
  final bool showPrivacyCaption;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final glowOpacity = 0.12 + (pulseController.value * 0.08);

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 510),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 13 : 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.53),
            borderRadius: BorderRadius.circular(compact ? 18 : 21),
            border: Border.all(
              color: stage.accent.withValues(alpha: glowOpacity),
            ),
            boxShadow: [
              BoxShadow(
                color: stage.accent.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: compact ? 36 : 41,
                    height: compact ? 36 : 41,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stage.accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      stage.icon,
                      color: stage.accent,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: NabiPalette.ink,
                            fontSize: compact ? 13 : 14,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stage.description,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: NabiPalette.mutedInk,
                            fontSize: compact ? 10.8 : 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 11 : 13),
              _BootTimeline(stage: stage, compact: compact),
              if (showPrivacyCaption) ...[
                SizedBox(height: compact ? 10 : 12),
                const _PrivacyCaption(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BootTimeline extends StatelessWidget {
  const _BootTimeline({required this.stage, required this.compact});

  final _BootStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineItem(
        label: 'Khởi tạo',
        icon: Icons.auto_awesome_rounded,
        color: NabiPalette.violet,
      ),
      _TimelineItem(
        label: 'Kiểm tra',
        icon: Icons.account_tree_outlined,
        color: NabiPalette.cyan,
      ),
      _TimelineItem(
        label: 'Bắt đầu',
        icon: Icons.play_arrow_rounded,
        color: NabiPalette.rose,
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: _TimelineStep(
              item: steps[index],
              active: index <= stage.index,
              current: index == stage.index,
              compact: compact,
            ),
          ),
          if (index != steps.length - 1)
            Expanded(child: _TimelineConnector(active: index < stage.index)),
        ],
      ],
    );
  }
}

class _TimelineItem {
  final String label;
  final IconData icon;
  final Color color;

  const _TimelineItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.item,
    required this.active,
    required this.current,
    required this.compact,
  });

  final _TimelineItem item;
  final bool active;
  final bool current;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: compact ? 25 : 29,
          height: compact ? 25 : 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? item.color.withValues(alpha: current ? 0.18 : 0.12)
                : NabiPalette.ink.withValues(alpha: 0.05),
            border: Border.all(
              color: active
                  ? item.color.withValues(alpha: current ? 0.56 : 0.22)
                  : NabiPalette.ink.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            active ? item.icon : Icons.circle_outlined,
            color: active ? item.color : NabiPalette.mutedInk,
            size: compact ? 13 : 15,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 5),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: active ? NabiPalette.ink : NabiPalette.mutedInk,
              fontSize: 9.5,
              height: 1,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: active
            ? NabiPalette.cyan.withValues(alpha: 0.62)
            : NabiPalette.ink.withValues(alpha: 0.09),
      ),
    );
  }
}

class _PrivacyCaption extends StatelessWidget {
  const _PrivacyCaption();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: NabiPalette.mutedInk),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Bạn luôn kiểm soát những thông tin mình chia sẻ.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: NabiPalette.mutedInk,
              fontSize: 10.5,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter({
    required this.stage,
    required this.controller,
    required this.compact,
    required this.showDescription,
  });

  final _BootStage stage;
  final AnimationController controller;
  final bool compact;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: stage.title,
      child: Column(
        children: [
          _ShimmerLoadingTrack(
            accent: stage.accent,
            controller: controller,
            compact: compact,
          ),
          if (showDescription) ...[
            SizedBox(height: compact ? 8 : 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BreathingDots(accent: stage.accent, controller: controller),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    stage == _BootStage.checkingProfile
                        ? 'Đang chuẩn bị điểm bắt đầu phù hợp cho bạn'
                        : 'Đang chuẩn bị trải nghiệm của bạn',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NabiPalette.mutedInk,
                      fontSize: compact ? 10.5 : 11.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ShimmerLoadingTrack extends StatelessWidget {
  const _ShimmerLoadingTrack({
    required this.accent,
    required this.controller,
    required this.compact,
  });

  final Color accent;
  final AnimationController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: compact ? 4 : 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shimmerWidth = constraints.maxWidth * 0.42;
                  final left =
                      ((constraints.maxWidth + shimmerWidth) *
                          controller.value) -
                      shimmerWidth;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: accent.withValues(alpha: 0.10),
                        ),
                      ),
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: shimmerWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                NabiPalette.violet.withValues(alpha: 0.68),
                                NabiPalette.cyan.withValues(alpha: 0.78),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BreathingDots extends StatelessWidget {
  const _BreathingDots({required this.accent, required this.controller});

  final Color accent;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (controller.value + (index * 0.16)) % 1;
            final size = 4.2 + (math.sin(phase * math.pi * 2).abs() * 2.1);

            return Container(
              width: size,
              height: size,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: index == 1 ? accent : NabiPalette.violet,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
