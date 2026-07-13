import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class OnboardingEntryPage extends StatefulWidget {
  const OnboardingEntryPage({super.key});

  @override
  State<OnboardingEntryPage> createState() => _OnboardingEntryPageState();
}

class _OnboardingEntryPageState extends State<OnboardingEntryPage>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (_reduceMotion == disableAnimations &&
        (_ambientController.isAnimating || disableAnimations)) {
      return;
    }

    _reduceMotion = disableAnimations;

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

    _ambientController.repeat();
    _pulseController.repeat(reverse: true);

    if (!_entryController.isCompleted) {
      _entryController.forward();
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
    final mediaQuery = MediaQuery.of(context);
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.30).toDouble();

    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _EntryAtmosphere(
                controller: _ambientController,
                reduceMotion: _reduceMotion,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _EntryLayout.fromConstraints(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  textScale: textScale,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                    vertical: layout.verticalPadding,
                  ),
                  child: Column(
                    children: [
                      _EntryTopBar(
                        compact: layout.isCompact || layout.isVeryNarrow,
                        pulseController: _pulseController,
                      ),
                      SizedBox(height: layout.topGap),
                      Expanded(
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
                            child: Scrollbar(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.only(
                                  bottom:
                                      layout.bottomPadding +
                                      mediaQuery.viewInsets.bottom,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: layout.contentMaxWidth,
                                    ),
                                    child: _EntryContent(
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
                        ),
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

class _EntryContent extends StatelessWidget {
  const _EntryContent({
    required this.layout,
    required this.ambientController,
    required this.pulseController,
    required this.reduceMotion,
  });

  final _EntryLayout layout;
  final AnimationController ambientController;
  final AnimationController pulseController;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EntryHero(
          compact: layout.isCompact,
          height: layout.heroHeight,
          showOrbit: layout.showOrbit,
          ambientController: ambientController,
          pulseController: pulseController,
          reduceMotion: reduceMotion,
        ),
        SizedBox(height: layout.sectionGap),
        const _EntryPurposeNotice(),
        SizedBox(height: layout.sectionGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns =
                layout.isWide &&
                constraints.maxWidth >= 720 &&
                layout.textScale <= 1.15;

            final loginCard = _EntryPathCard(
              compact: layout.isCompact,
              accent: NabiPalette.violet,
              icon: Icons.cloud_sync_outlined,
              eyebrow: 'ĐỒNG BỘ & MỞ RỘNG',
              title: 'Đăng nhập để đồng hành dài lâu',
              description:
                  'Lưu hành trình an toàn, đồng bộ khi đổi thiết bị và mở thêm các tính năng chăm sóc nâng cao.',
              badge: 'Khuyên dùng',
              benefits: const [
                _PathBenefit(
                  icon: Icons.sync_rounded,
                  label: 'Đồng bộ hành trình',
                ),
                _PathBenefit(
                  icon: Icons.edit_calendar_outlined,
                  label: 'Tạo lại lộ trình',
                ),
                _PathBenefit(
                  icon: Icons.lock_outline_rounded,
                  label: 'Quản lý dữ liệu',
                ),
              ],
              action: NabiPrimaryButton(
                key: const Key('onboarding_entry_login_cta'),
                onPressed: () => context.go(AuthRoutePaths.login),
                label: 'Đăng nhập hoặc tạo tài khoản',
                icon: Icons.login_rounded,
              ),
            );

            final guestCard = _EntryPathCard(
              compact: layout.isCompact,
              accent: NabiPalette.cyan,
              icon: Icons.rocket_launch_outlined,
              eyebrow: 'BẮT ĐẦU NGAY',
              title: 'Khám phá NaBi không cần tài khoản',
              description:
                  'Trả lời vài câu hỏi ngắn để nhận lộ trình đầu tiên phù hợp với nhịp sống hiện tại của bạn.',
              badge: 'Nhanh chóng',
              benefits: const [
                _PathBenefit(
                  icon: Icons.timer_outlined,
                  label: 'Khoảng 2–3 phút',
                ),
                _PathBenefit(
                  icon: Icons.phone_android_outlined,
                  label: 'Lưu trên thiết bị',
                ),
                _PathBenefit(icon: Icons.edit_outlined, label: 'Chỉnh sửa sau'),
              ],
              action: NabiSecondaryButton(
                key: const Key('onboarding_entry_guest_cta'),
                onPressed: () => context.go(V1RoutePaths.onboarding),
                label: 'Bắt đầu trải nghiệm ngay',
                icon: Icons.arrow_forward_rounded,
              ),
            );

            if (!useTwoColumns) {
              return Column(
                children: [
                  loginCard,
                  SizedBox(height: layout.cardGap),
                  guestCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: loginCard),
                SizedBox(width: layout.cardGap),
                Expanded(child: guestCard),
              ],
            );
          },
        ),
        SizedBox(height: layout.cardGap),
        const _StartGuideCard(),
      ],
    );
  }
}

class _EntryLayout {
  final bool isVeryNarrow;
  final bool isCompact;
  final bool isWide;
  final bool showOrbit;
  final double textScale;
  final double horizontalPadding;
  final double verticalPadding;
  final double topGap;
  final double bottomPadding;
  final double contentMaxWidth;
  final double heroHeight;
  final double sectionGap;
  final double cardGap;

  const _EntryLayout({
    required this.isVeryNarrow,
    required this.isCompact,
    required this.isWide,
    required this.showOrbit,
    required this.textScale,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.topGap,
    required this.bottomPadding,
    required this.contentMaxWidth,
    required this.heroHeight,
    required this.sectionGap,
    required this.cardGap,
  });

  factory _EntryLayout.fromConstraints({
    required double width,
    required double height,
    required double textScale,
  }) {
    final normalizedTextScale = textScale.clamp(1.0, 1.30).toDouble();
    final isVeryNarrow = width < 360;
    final isShort = height < 650;
    final isLandscape = width > height;
    final isShortLandscape = isLandscape && height < 650;
    final isCompact = isVeryNarrow || isShort || (isLandscape && height < 560);
    final isWide = width >= 760;
    final heroBaseHeight = isVeryNarrow
        ? 188.0
        : isShortLandscape
        ? 148.0
        : isLandscape
        ? 204.0
        : isWide
        ? 252.0
        : 228.0;

    return _EntryLayout(
      isVeryNarrow: isVeryNarrow,
      isCompact: isCompact,
      isWide: isWide,
      showOrbit: width >= 360 && normalizedTextScale <= 1.14,
      textScale: normalizedTextScale,
      horizontalPadding: width >= 1200
          ? 56
          : width >= 760
          ? 36
          : width >= 600
          ? 28
          : isVeryNarrow
          ? 16
          : 20,
      verticalPadding: height < 520
          ? 10
          : isCompact
          ? 14
          : 21,
      topGap: isCompact ? 10 : 20,
      bottomPadding: isCompact ? 16 : 32,
      contentMaxWidth: width >= 1200
          ? 1000
          : width >= 760
          ? 880
          : width >= 600
          ? 640
          : 560,
      heroHeight: math
          .min(heroBaseHeight + (normalizedTextScale - 1) * 42, 276)
          .toDouble(),
      sectionGap: isCompact ? 10 : 14,
      cardGap: width >= 760 ? 16 : 12,
    );
  }
}

class _EntryAtmosphere extends StatelessWidget {
  const _EntryAtmosphere({
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
            Color.lerp(AppColors.background, NabiPalette.violet, 0.07)!,
            Color.lerp(AppColors.background, NabiPalette.cyan, 0.09)!,
            AppColors.background,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _EntryAtmospherePainter(
              phase: reduceMotion ? 0.5 : controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _EntryAtmospherePainter extends CustomPainter {
  final double phase;

  const _EntryAtmospherePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(phase * math.pi * 2);
    final inverseWave = math.cos(phase * math.pi * 2);

    _drawGlow(
      canvas: canvas,
      center: Offset(size.width * 0.12 + wave * 18, size.height * 0.13),
      radius: size.width * 0.34,
      color: NabiPalette.violet.withValues(alpha: 0.15),
    );

    _drawGlow(
      canvas: canvas,
      center: Offset(size.width * 0.9, size.height * 0.78 + inverseWave * 20),
      radius: size.width * 0.42,
      color: NabiPalette.cyan.withValues(alpha: 0.14),
    );

    _drawGlow(
      canvas: canvas,
      center: Offset(size.width * 0.46 + inverseWave * 14, size.height * 0.53),
      radius: size.width * 0.25,
      color: NabiPalette.rose.withValues(alpha: 0.08),
    );

    final wavePaint = Paint()
      ..color = NabiPalette.violet.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final upperWave = Path()
      ..moveTo(-24, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * (0.13 + wave * 0.025),
        size.width + 24,
        size.height * 0.26,
      );

    final lowerWave = Path()
      ..moveTo(-24, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * (0.65 + inverseWave * 0.028),
        size.width + 24,
        size.height * 0.8,
      );

    canvas.drawPath(upperWave, wavePaint);
    canvas.drawPath(lowerWave, wavePaint);

    final particlePaint = Paint()..color = Colors.white.withValues(alpha: 0.48);

    for (var index = 0; index < 7; index++) {
      final x = size.width * (0.08 + (index / 7) * 0.84);
      final y =
          size.height *
          (0.1 + ((math.sin((phase * math.pi * 2) + index * 1.4) + 1) * 0.29));

      canvas.drawCircle(Offset(x, y), index.isEven ? 1.6 : 1.15, particlePaint);
    }
  }

  void _drawGlow({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _EntryAtmospherePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _EntryTopBar extends StatelessWidget {
  const _EntryTopBar({required this.compact, required this.pulseController});

  final bool compact;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LaunchPill(compact: compact, pulseController: pulseController),
        const Spacer(),
        if (!compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            ),
            child: Text(
              'CÁ NHÂN HÓA',
              style: AppTextStyles.overline.copyWith(
                color: NabiPalette.mutedInk,
                fontSize: 8.5,
                height: 1,
                letterSpacing: 1.04,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _LaunchPill extends StatelessWidget {
  const _LaunchPill({required this.compact, required this.pulseController});

  final bool compact;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final scale = 0.78 + pulseController.value * 0.22;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            boxShadow: [
              BoxShadow(
                color: NabiPalette.violet.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NabiPalette.cyan,
                    boxShadow: [
                      BoxShadow(
                        color: NabiPalette.cyan.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'SẴN SÀNG BẮT ĐẦU',
                style: AppTextStyles.overline.copyWith(
                  color: NabiPalette.mutedInk,
                  fontSize: compact ? 8.3 : 9,
                  height: 1,
                  letterSpacing: 1.06,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EntryHero extends StatelessWidget {
  const _EntryHero({
    required this.compact,
    required this.height,
    required this.showOrbit,
    required this.ambientController,
    required this.pulseController,
    required this.reduceMotion,
  });

  final bool compact;
  final double height;
  final bool showOrbit;
  final AnimationController ambientController;
  final AnimationController pulseController;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ambientController, pulseController]),
      builder: (context, _) {
        final phase = reduceMotion ? 0.5 : ambientController.value;
        final wave = math.sin(phase * math.pi * 2);

        return LayoutBuilder(
          builder: (context, constraints) {
            final orbitSize = compact ? 108.0 : 122.0;
            final leftInset = compact ? 18.0 : 22.0;
            final rightInset =
                (compact ? 18.0 : 22.0) + (showOrbit ? orbitSize * 0.78 : 0);
            final textWidth = math.max(
              0.0,
              constraints.maxWidth - leftInset - rightInset,
            );
            final titleSize = compact
                ? (showOrbit ? 22.0 : 24.0)
                : (showOrbit ? 25.0 : 27.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 25 : 29),
              child: Container(
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NabiPalette.violet,
                      Color.lerp(NabiPalette.violet, NabiPalette.cyan, 0.48)!,
                      NabiPalette.cyan,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NabiPalette.violet.withValues(alpha: 0.24),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -48,
                      right: -44 + wave * 8,
                      child: _HeroBubble(
                        size: 155,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      bottom: -76,
                      left: -64 - wave * 6,
                      child: _HeroBubble(
                        size: 182,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    if (showOrbit)
                      Positioned(
                        right: compact ? 7 : 17,
                        bottom: compact ? 11 : 15,
                        child: _EntryOrbit(
                          size: orbitSize,
                          phase: phase,
                          pulse: pulseController.value,
                          reduceMotion: reduceMotion,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        leftInset,
                        compact ? 17 : 20,
                        rightInset,
                        compact ? 17 : 19,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeroEyebrow(
                            label: 'KHỞI ĐẦU THEO CÁCH CỦA BẠN',
                          ),
                          SizedBox(height: compact ? 10 : 13),
                          Text(
                            'Một hành trình khỏe hơn,\nbắt đầu thật nhẹ nhàng.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.68,
                            ),
                          ),
                          const Spacer(),
                          _HeroValueChip(maxWidth: textWidth),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroEyebrow extends StatelessWidget {
  final String label;

  const _HeroEyebrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 9.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.95,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroValueChip extends StatelessWidget {
  const _HeroValueChip({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                'Lộ trình riêng, từ những điều nhỏ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryOrbit extends StatelessWidget {
  final double size;
  final double phase;
  final double pulse;
  final bool reduceMotion;

  const _EntryOrbit({
    required this.size,
    required this.phase,
    required this.pulse,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final floating = reduceMotion ? 0.0 : math.sin(phase * math.pi * 2) * 4;
    final scale = reduceMotion ? 1.0 : 0.98 + pulse * 0.025;

    return Transform.translate(
      offset: Offset(0, floating),
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: phase * math.pi * 2,
                child: CustomPaint(
                  size: Size.square(size * 0.92),
                  painter: _OrbitPainter(),
                ),
              ),
              Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.19),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: size * 0.24,
                ),
              ),
              Positioned(
                top: 3,
                right: size * 0.16,
                child: const _OrbitBadge(
                  icon: Icons.restaurant_rounded,
                  color: NabiPalette.amber,
                ),
              ),
              Positioned(
                left: 1,
                bottom: size * 0.18,
                child: const _OrbitBadge(
                  icon: Icons.directions_walk_rounded,
                  color: NabiPalette.cyan,
                ),
              ),
              Positioned(
                right: 0,
                bottom: size * 0.29,
                child: const _OrbitBadge(
                  icon: Icons.bedtime_outlined,
                  color: NabiPalette.rose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.24);

    canvas.drawCircle(center, size.width * 0.42, ringPaint);
    canvas.drawCircle(center, size.width * 0.32, ringPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.76);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.42),
      0,
      math.pi * 0.55,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => false;
}

class _OrbitBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OrbitBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 15),
    );
  }
}

class _EntryPurposeNotice extends StatelessWidget {
  const _EntryPurposeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: NabiPalette.cyan.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: NabiPalette.cyan.withValues(alpha: 0.14)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoticeIcon(
            icon: Icons.tips_and_updates_outlined,
            color: NabiPalette.cyan,
          ),
          SizedBox(width: 9),
          Expanded(
            child: _NoticeText(
              title: 'Bạn có quyền chọn cách bắt đầu',
              description:
                  'Không cần tài khoản để tạo lộ trình đầu tiên. Bạn luôn có thể đăng nhập sau để đồng bộ hành trình.',
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _NoticeIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}

class _NoticeText extends StatelessWidget {
  final String title;
  final String description;

  const _NoticeText({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: NabiPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(
            color: NabiPalette.mutedInk,
            height: 1.34,
          ),
        ),
      ],
    );
  }
}

class _EntryPathCard extends StatelessWidget {
  final bool compact;
  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final String badge;
  final List<_PathBenefit> benefits;
  final Widget action;

  const _EntryPathCard({
    required this.compact,
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.badge,
    required this.benefits,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = compact ? 12.0 : 16.0;
    final iconSize = compact ? 36.0 : 43.0;
    final showBenefits = !compact;

    return Semantics(
      container: true,
      label: '$title. $description',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(compact ? 20 : 22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
          boxShadow: [
            BoxShadow(
              color: NabiPalette.ink.withValues(alpha: 0.055),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(compact ? 13 : 14),
                  ),
                  child: Icon(icon, color: accent, size: compact ? 20 : 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      eyebrow,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.overline.copyWith(
                        color: accent,
                        fontSize: compact ? 8.3 : 8.8,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CardBadge(label: badge, color: accent),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: NabiPalette.ink,
                fontSize: compact ? 18 : 19,
                height: 1.16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.36,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: NabiPalette.mutedInk,
                fontSize: compact ? 12.5 : 13,
                height: 1.43,
              ),
            ),
            if (showBenefits) ...[
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: benefits
                        .map(
                          (benefit) => _BenefitPill(
                            icon: benefit.icon,
                            label: benefit.label,
                            color: accent,
                            maxWidth: constraints.maxWidth,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
            SizedBox(height: compact ? 12 : 16),
            SizedBox(width: double.infinity, child: action),
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CardBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 92),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PathBenefit {
  final IconData icon;
  final String label;

  const _PathBenefit({required this.icon, required this.label});
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double maxWidth;

  const _BenefitPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: NabiPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartGuideCard extends StatelessWidget {
  const _StartGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: NabiPalette.rose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: NabiPalette.rose.withValues(alpha: 0.11)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoticeIcon(
            icon: Icons.privacy_tip_outlined,
            color: NabiPalette.rose,
          ),
          SizedBox(width: 9),
          Expanded(
            child: _NoticeText(
              title: 'Bạn luôn làm chủ thông tin của mình',
              description:
                  'NaBi chỉ dùng thông tin bạn chọn chia sẻ để tạo gợi ý phù hợp hơn. Bạn có thể cập nhật hồ sơ bất cứ lúc nào.',
            ),
          ),
        ],
      ),
    );
  }
}
