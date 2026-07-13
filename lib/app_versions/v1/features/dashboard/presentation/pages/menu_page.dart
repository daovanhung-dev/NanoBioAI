import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart';
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
  // Scaffold lays the body out above the bottom navigation bar already. Keep
  // only a small visual gap here so Nabi does not float over feature tiles.
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

  late final List<_NavItemData> _items = [
    _NavItemData(
      label: 'Hôm nay',
      semanticLabel: 'Về trang hôm nay của bạn',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
      baseColor: AppColors.primary,
      accentColor: AppColors.primaryLight,
    ),
    _NavItemData(
      label: 'Tiện ích',
      semanticLabel: 'Mở các tiện ích chăm sóc sức khỏe',
      icon: Icons.widgets_rounded,
      activeIcon: Icons.dashboard_customize_rounded,
      baseColor: AppColors.secondary,
      accentColor: AppColors.info,
    ),
    _NavItemData(
      label: 'Góc Nabi',
      semanticLabel: 'Mở góc đồng hành cùng Nabi',
      icon: Icons.auto_awesome_mosaic_rounded,
      activeIcon: Icons.auto_awesome_rounded,
      baseColor: AppColors.warning,
      accentColor: AppColors.secondary,
    ),
    _NavItemData(
      label: 'Của bạn',
      semanticLabel: 'Mở không gian tùy chỉnh của bạn',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      baseColor: AppColors.textPrimary,
      accentColor: AppColors.textSecondary,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
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

    HapticFeedback.lightImpact();

    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      index,
      duration: AppDuration.slow,
      curve: Curves.easeOutCubic,
    );

    // Cập nhật Nabi context theo tab đang active
    final routeByTab = [
      V1RoutePaths.dashboard,
      V1RoutePaths.menu, // features hub
      '/health-insights',
      V1RoutePaths.menu, // settings
    ];
    final route = index < routeByTab.length
        ? routeByTab[index]
        : V1RoutePaths.menu;
    ref.nabi.setRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle = SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MedicalPageScaffold(
        ambientBackground: false,
        backgroundColor: AppColors.background,
        extendBody: true,
        body: LayoutBuilder(
          builder: (context, _) {
            return Stack(
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
                // The feature hub is a dense, scrollable tile grid. Keeping a
                // fixed mascot on top of it obscures tile copy and tap targets;
                // the hub already exposes the dedicated Nabi chat tile.
                NabiFloatingOverlay(
                  bottomReserve: _bottomNavigationReserve,
                  visible: _currentIndex != 1,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.lg,
          ),
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(
                  0,
                  lerpDouble(0, -3, _floatingController.value)!,
                ),
                child: RepaintBoundary(child: _buildNavigationBar(context)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColors = isDark
        ? [
            Colors.white.withValues(alpha: .12),
            Colors.white.withValues(alpha: .07),
          ]
        : [
            Colors.white.withValues(alpha: .84),
            Colors.white.withValues(alpha: .66),
          ];

    final borderColor = isDark
        ? Colors.white.withValues(alpha: .14)
        : Colors.white.withValues(alpha: .58);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
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
                color: AppColors.primary.withValues(alpha: .08),
                blurRadius: 34,
                spreadRadius: 1,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];

              return Expanded(
                child: _AnimatedNavItem(
                  item: item,
                  isActive: _currentIndex == index,
                  pulseValue: _floatingController.value,
                  onTap: () => _changeTab(index),
                ),
              );
            }),
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
    final inactiveColor = AppColors.textHint;
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
          builder: (_, value, __) {
            return AnimatedScale(
              scale: isActive ? lerpDouble(1, 1.035, pulseValue)! : 1,
              duration: AppDuration.fast,
              curve: Curves.easeOutCubic,
              child: Container(
                height: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: isActive ? 1 : 0,
                        duration: AppDuration.normal,
                        curve: Curves.easeOutCubic,
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
                                color: item.baseColor.withValues(
                                  alpha: glowOpacity,
                                ),
                                blurRadius: 24,
                                spreadRadius: 1,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: AppDuration.normal,
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withValues(alpha: .24)
                              : Colors.transparent,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 72;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.translate(
                                offset: Offset(0, lerpDouble(3, 0, value)!),
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  color: isActive
                                      ? Colors.white
                                      : inactiveColor,
                                  size: lerpDouble(23, 28, value)!,
                                ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: AppDuration.normal,
                                  curve: Curves.easeOutCubic,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isActive
                                        ? Colors.white
                                        : inactiveColor,
                                    fontWeight: isActive
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: lerpDouble(10.5, 11.4, value)!,
                                    letterSpacing: .1,
                                  ),
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        top: 7,
                        child: Container(
                          width: 22,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .92),
                            borderRadius: BorderRadius.circular(
                              AppRadius.circular,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: .62),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([ambientAnimation, floatingAnimation]),
      builder: (_, __) {
        return IgnorePointer(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [AppColors.textPrimary, AppColors.textSecondary]
                        : [AppColors.background, AppColors.surface],
                  ),
                ),
              ),
              _AmbientOrb(
                top: -116,
                left: -84,
                size: 284,
                color: AppColors.primary,
                opacity: .16,
                animationValue: ambientAnimation.value,
                floatingValue: floatingAnimation.value,
                rotateFactor: 2.2,
              ),
              _AmbientOrb(
                top: 172,
                right: -92,
                size: 236,
                color: AppColors.secondary,
                opacity: .13,
                animationValue: ambientAnimation.value,
                floatingValue: floatingAnimation.value,
                rotateFactor: -1.4,
              ),
              _AmbientOrb(
                bottom: -148,
                left: 42,
                size: 276,
                color: AppColors.warning,
                opacity: .10,
                animationValue: ambientAnimation.value,
                floatingValue: floatingAnimation.value,
                rotateFactor: 1.1,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(.15, -.55),
                      radius: 1.1,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? .02 : .28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
    required this.animationValue,
    required this.floatingValue,
    required this.rotateFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top == null ? null : top! + lerpDouble(-10, 10, floatingValue)!,
      left: left,
      right: right,
      bottom: bottom == null
          ? null
          : bottom! + lerpDouble(8, -8, floatingValue)!,
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
