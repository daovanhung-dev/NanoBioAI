import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/main_navigation_state_provider.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/app_versions/v1/features/other/presentation/pages/other_page.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/pages/settings_page.dart';
import 'package:nano_app/app_versions/v1/features/nabi/nabi.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage>
    with TickerProviderStateMixin {
  static const double _bottomNavigationReserve = 0;

  late final PageController _pageController;
  late final AnimationController _ambientController;
  late final AnimationController _floatingController;

  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    DashboardPage(showStandaloneChatButton: false),
    FeaturesHubPage(),
    HealthInsightsView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    Future<void>.microtask(() {
      if (mounted) ref.read(mainNavigationIndexProvider.notifier).state = 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final policy = AppMotionScope.of(context);
    final reduceMotion = AppMotionScope.reduceMotionOf(context);
    if (reduceMotion ||
        policy.performanceTier == AppPerformanceTier.economical) {
      _ambientController
        ..stop()
        ..value = .42;
      _floatingController
        ..stop()
        ..value = .5;
      return;
    }
    if (!_ambientController.isAnimating) _ambientController.repeat();
    if (!_floatingController.isAnimating) {
      _floatingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ambientController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    if (_currentIndex == index) return;
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    setState(() => _currentIndex = index);
    ref.read(mainNavigationIndexProvider.notifier).state = index;

    if (AppMotionScope.reduceMotionOf(context)) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: AppDuration.slow,
        curve: AppAnimations.emphasizedCurve,
      );
    }

    const contextByTab = [
      V1RoutePaths.dashboard,
      '/features',
      '/health-insights',
      '/settings',
    ];
    ref.nabi.setRoute(index < contextByTab.length
        ? contextByTab[index]
        : V1RoutePaths.menu);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MedicalPageScaffold(
        ambientBackground: false,
        backgroundColor: context.semanticColors.background,
        extendBody: true,
        body: Stack(
          children: [
            RepaintBoundary(
              child: _AnimatedBackground(
                ambientAnimation: _ambientController,
                floatingAnimation: _floatingController,
              ),
            ),
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
            NabiFloatingOverlay(
              bottomReserve: _bottomNavigationReserve,
              visible: _currentIndex != 1,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.lg,
          ),
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, lerpDouble(0, -3, _floatingController.value)!),
              child: RepaintBoundary(child: _buildNavigationBar(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.semanticColors;
    final items = [
      _NavItemData(
        label: 'Hôm nay',
        semanticLabel: 'Về trang hôm nay của bạn',
        icon: Icons.home_rounded,
        activeIcon: Icons.home_filled,
        baseColor: colors.primary,
        accentColor: colors.primaryLight,
      ),
      _NavItemData(
        label: 'Tiện ích',
        semanticLabel: 'Mở các tiện ích chăm sóc sức khỏe',
        icon: Icons.widgets_rounded,
        activeIcon: Icons.dashboard_customize_rounded,
        baseColor: colors.secondary,
        accentColor: colors.info,
      ),
      _NavItemData(
        label: 'Góc Nabi',
        semanticLabel: 'Mở góc đồng hành cùng Nabi',
        icon: Icons.auto_awesome_mosaic_rounded,
        activeIcon: Icons.auto_awesome_rounded,
        baseColor: colors.warning,
        accentColor: colors.secondary,
      ),
      _NavItemData(
        label: 'Của bạn',
        semanticLabel: 'Mở không gian tùy chỉnh của bạn',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        baseColor: colors.textPrimary,
        accentColor: colors.textSecondary,
      ),
    ];
    final tier = AppMotionScope.of(context).performanceTier;
    final blurSigma = switch (tier) {
      AppPerformanceTier.economical => 0.0,
      AppPerformanceTier.balanced => 14.0,
      AppPerformanceTier.rich => 22.0,
    };
    final glassColors = isDark
        ? [
            colors.surface.withValues(alpha: .12),
            colors.surface.withValues(alpha: .07),
          ]
        : [
            colors.surface.withValues(alpha: .84),
            colors.surface.withValues(alpha: .66),
          ];
    final borderColor = isDark
        ? colors.surface.withValues(alpha: .14)
        : colors.surface.withValues(alpha: .58);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          height: 78,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: glassColors,
            ),
            boxShadow: [
              ...AppShadows.xl,
              BoxShadow(
                color: colors.primary.withValues(alpha: .08),
                blurRadius: 34,
                spreadRadius: 1,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) => Expanded(
              child: _AnimatedNavItem(
                item: items[index],
                isActive: _currentIndex == index,
                pulseValue: _floatingController.value,
                onTap: () => _changeTab(index),
              ),
            )),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isActive;
  final double pulseValue;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.item,
    required this.isActive,
    required this.pulseValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final inactiveColor = colors.textHint;
    final glowOpacity = lerpDouble(.10, .22, pulseValue)!;

    return Semantics(
      label: item.semanticLabel,
      selected: isActive,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isActive ? 1 : 0),
          duration: AppDuration.normal,
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => AnimatedScale(
            scale: isActive ? lerpDouble(1, 1.035, pulseValue)! : 1,
            duration: AppDuration.fast,
            curve: Curves.easeOutCubic,
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: isActive ? 1 : 0,
                      duration: AppDuration.normal,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [item.baseColor, item.accentColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.baseColor.withValues(alpha: glowOpacity),
                              blurRadius: 24,
                              spreadRadius: 1,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 72;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive ? colors.textInverse : inactiveColor,
                              size: lerpDouble(23, 28, value)!,
                            ),
                            if (!isCompact) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isActive
                                      ? colors.textInverse
                                      : inactiveColor,
                                  fontWeight: isActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final Animation<double> ambientAnimation;
  final Animation<double> floatingAnimation;

  const _AnimatedBackground({
    required this.ambientAnimation,
    required this.floatingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return AnimatedBuilder(
      animation: Listenable.merge([ambientAnimation, floatingAnimation]),
      builder: (_, __) => IgnorePointer(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, colors.surface],
                ),
              ),
            ),
            _AmbientOrb(
              top: -116,
              left: -84,
              size: 284,
              color: colors.primary,
              opacity: .16,
              animationValue: ambientAnimation.value,
              floatingValue: floatingAnimation.value,
              rotateFactor: 2.2,
            ),
            _AmbientOrb(
              top: 172,
              right: -92,
              size: 236,
              color: colors.secondary,
              opacity: .13,
              animationValue: ambientAnimation.value,
              floatingValue: floatingAnimation.value,
              rotateFactor: -1.4,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;
  final double animationValue;
  final double floatingValue;
  final double rotateFactor;

  const _AmbientOrb({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.opacity,
    required this.animationValue,
    required this.floatingValue,
    required this.rotateFactor,
  }) : bottom = null;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top == null ? null : top! + lerpDouble(-10, 10, floatingValue)!,
      left: left,
      right: right,
      bottom: bottom == null ? null : bottom! + lerpDouble(8, -8, floatingValue)!,
      child: Transform.rotate(
        angle: animationValue * rotateFactor,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: .01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final String semanticLabel;
  final IconData icon;
  final IconData activeIcon;
  final Color baseColor;
  final Color accentColor;

  const _NavItemData({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.activeIcon,
    required this.baseColor,
    required this.accentColor,
  });
}
