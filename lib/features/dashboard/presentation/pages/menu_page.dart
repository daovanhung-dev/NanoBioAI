import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nano_app/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/features/other/presentation/pages/other_page.dart';
import 'package:nano_app/features/settings/presentation/pages/settings_page.dart';
import 'package:nano_app/shared/widgets/ai_chat_fab.dart';

import '../../../../core/theme/theme.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;

  late final AnimationController _backgroundController;
  late final AnimationController _pulseController;
  late final AnimationController _floatingController;
  late final AnimationController _rotationController;
  late final AnimationController _indicatorController;

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(), //LifestyleSchedulePage(),
    FeaturesHubPage(),
    HealthInsightsView(),
    SettingsView(),
  ];

  final List<_NavItemData> _items = const [
    _NavItemData(
      label: 'Trang chủ',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
      gradient: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    ),
    _NavItemData(
      label: 'Tính năng',
      icon: Icons.widgets_rounded,
      activeIcon: Icons.dashboard_customize_rounded,
      gradient: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    ),
    _NavItemData(
      label: 'Góc của bạn',
      icon: Icons.auto_awesome_mosaic_rounded,
      activeIcon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    ),
    _NavItemData(
      label: 'Tùy chỉnh',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      gradient: [Color(0xFF0F172A), Color(0xFF334155)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _indicatorController = AnimationController(
      vsync: this,
      duration: AppDuration.normal,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _rotationController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });

    _indicatorController
      ..reset()
      ..forward();

    _pageController.animateToPage(
      index,
      duration: AppDuration.slow,
      curve: Curves.easeOutExpo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          _AnimatedBackground(
            backgroundController: _backgroundController,
            floatingController: _floatingController,
            rotationController: _rotationController,
          ),

          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (_, index) {
              return AnimatedSwitcher(
                duration: AppDuration.slow,
                switchInCurve: Curves.easeOutExpo,
                switchOutCurve: Curves.easeInExpo,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutExpo,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _pages[index],
              );
            },
          ),
        ],
      ),
      floatingActionButton: const AIChatFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _floatingController]),
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, lerpDouble(0, -4, _floatingController.value)!),
              child: _buildNavigationBar(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: Colors.white.withOpacity(.5)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.78),
                Colors.white.withOpacity(.60),
              ],
            ),
            boxShadow: [
              ...AppShadows.xl,
              BoxShadow(
                color: AppColors.primary.withOpacity(.10),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = _currentIndex == index;

              return Expanded(
                child: _AnimatedNavItem(
                  item: item,
                  isActive: isActive,
                  pulseValue: _pulseController.value,
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
    final glowOpacity = lerpDouble(.12, .28, pulseValue)!;

    final scale = isActive ? lerpDouble(1, 1.08, pulseValue)! : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
        duration: AppDuration.normal,
        curve: Curves.easeOutExpo,
        builder: (_, value, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: isActive ? 1 : 0,
                    duration: AppDuration.normal,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        gradient: LinearGradient(colors: item.gradient),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradient.first.withOpacity(glowOpacity),
                            blurRadius: 30,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isActive
                            ? Colors.white.withOpacity(.24)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
                          duration: AppDuration.normal,
                          curve: Curves.easeOutBack,
                          builder: (_, value, child) {
                            return Transform.translate(
                              offset: Offset(0, lerpDouble(4, 0, value)!),
                              child: Transform.scale(
                                scale: lerpDouble(.90, 1, value)!,
                                child: ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      colors: isActive
                                          ? [Colors.white, Colors.white70]
                                          : [
                                              AppColors.textHint,
                                              AppColors.textHint,
                                            ],
                                    ).createShader(rect);
                                  },
                                  child: Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    color: Colors.white,
                                    size: isActive ? 30 : 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 4),

                        AnimatedDefaultTextStyle(
                          duration: AppDuration.normal,
                          curve: Curves.easeOutExpo,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isActive ? Colors.white : AppColors.textHint,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: isActive ? 11.8 : 10.8,
                            letterSpacing: .2,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isActive)
                    Positioned(
                      top: 8,
                      child: Container(
                        width: 26,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.9),
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(.7),
                              blurRadius: 12,
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
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController backgroundController;
  final AnimationController floatingController;
  final AnimationController rotationController;

  const _AnimatedBackground({
    required this.backgroundController,
    required this.floatingController,
    required this.rotationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        backgroundController,
        floatingController,
        rotationController,
      ]),
      builder: (_, __) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                ),
              ),
            ),

            Positioned(
              top: -120,
              left: -80,
              child: Transform.rotate(
                angle: rotationController.value * 2,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(.18),
                        AppColors.primary.withOpacity(.01),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 180 + lerpDouble(-18, 18, floatingController.value)!,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(.14),
                      AppColors.secondary.withOpacity(.01),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -140,
              left: 40,
              child: Transform.rotate(
                angle: -rotationController.value,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA855F7).withOpacity(.12),
                        const Color(0xFFA855F7).withOpacity(.01),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final List<Color> gradient;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.gradient,
  });
}
