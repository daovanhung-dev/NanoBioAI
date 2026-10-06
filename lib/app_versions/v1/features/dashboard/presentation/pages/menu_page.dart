import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/main_navigation_state_provider.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';
import 'package:nano_app/app_versions/v1/features/nabi/nabi.dart';
import 'package:nano_app/app_versions/v1/features/other/presentation/pages/other_page.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/pages/settings_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  static const double _bottomNavigationReserve = 0;

  late final PageController _pageController;
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
    _currentIndex = widget.initialIndex.clamp(0, 3).toInt();
    _pageController = PageController(initialPage: _currentIndex);
    Future<void>.microtask(() {
      if (mounted) {
        ref.read(mainNavigationIndexProvider.notifier).state = _currentIndex;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    ref.nabi.setRoute(
      index < contextByTab.length ? contextByTab[index] : V1RoutePaths.menu,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MedicalPageScaffold(
        ambientBackground: false,
        backgroundColor: context.semanticColors.background,
        extendBody: true,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
            NabiFloatingOverlay(
              bottomReserve: _bottomNavigationReserve,
              visible: _currentIndex == 0 || _currentIndex == 2,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: RepaintBoundary(child: _buildNavigationBar(context)),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final colors = context.semanticColors;
    final borderRadius = BorderRadius.circular(AppRadius.xl);

    return Semantics(
      label: 'Điều hướng chính',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: borderRadius,
            border: Border.all(color: colors.borderLight),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: .06),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _changeTab,
            height: 68,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: colors.primarySoft,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Hôm nay',
                tooltip: 'Về trang hôm nay của bạn',
              ),
              NavigationDestination(
                icon: Icon(Icons.widgets_outlined),
                selectedIcon: Icon(Icons.widgets_rounded),
                label: 'Tiện ích',
                tooltip: 'Mở các tiện ích chăm sóc sức khỏe',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_mosaic_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Góc Nabi',
                tooltip: 'Mở góc đồng hành cùng Nabi',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Của bạn',
                tooltip: 'Mở không gian tùy chỉnh của bạn',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
