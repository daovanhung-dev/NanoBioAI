import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/splash/presentation/pages/splash_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': false,
    });
  });

  testWidgets('renders NanoBio and Nabi as the primary splash hierarchy', (
    tester,
  ) async {
    await _pumpSplash(tester);

    expect(find.text('NanoBio'), findsOneWidget);
    expect(find.text('TRỢ LÝ SỨC KHỎE CÁ NHÂN'), findsOneWidget);
    expect(find.text('Cùng Nabi chăm sóc sức khỏe mỗi ngày.'), findsOneWidget);
    expect(find.text('Nabi đang chuẩn bị trải nghiệm của bạn'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('does not overflow on a compact viewport with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSplash(tester, textScaler: const TextScaler.linear(1.35));

    expect(tester.takeException(), isNull);
    expect(find.text('NanoBio'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode keeps the splash hierarchy renderable', (tester) async {
    await _pumpSplash(tester, themeMode: ThemeMode.dark);

    expect(find.text('NanoBio'), findsOneWidget);
    expect(find.text('Cùng Nabi chăm sóc sức khỏe mỗi ngày.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion path remains renderable', (tester) async {
    await _pumpSplash(tester, disableAnimations: true);

    expect(find.text('NanoBio'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final router = GoRouter(
    initialLocation: V1RoutePaths.splash,
    routes: [
      GoRoute(
        path: V1RoutePaths.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: V1RoutePaths.onboardingEntry,
        builder: (_, __) => const _TargetPage(label: 'onboarding-entry'),
      ),
      GoRoute(
        path: V1RoutePaths.onboarding,
        builder: (_, __) => const _TargetPage(label: 'onboarding'),
      ),
      GoRoute(
        path: V1RoutePaths.menu,
        builder: (_, __) => const _TargetPage(label: 'menu'),
      ),
      GoRoute(
        path: AuthRoutePaths.authGate,
        builder: (_, __) => const _TargetPage(label: 'auth-gate'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: textScaler,
              disableAnimations: disableAnimations,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    ),
  );

  await tester.pump();
}

class _TargetPage extends StatelessWidget {
  const _TargetPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
