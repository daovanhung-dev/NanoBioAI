import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/features/health_modules/health_modules.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/membership_entitlement.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/constants/routes/health_module_route_paths.dart';
import 'package:nano_app/core/theme/medical_ui.dart';

void main() {
  testWidgets('Free opens the M20 coming-soon page with module copy', (
    tester,
  ) async {
    await _pumpDirectPage(
      tester,
      moduleId: 'M20',
      access: _access(membershipPlan: 'free'),
    );

    expect(find.byType(MedicalComingSoonPage), findsOneWidget);
    expect(find.text('Nhật ký huyết áp'), findsOneWidget);
    expect(find.textContaining('M20'), findsOneWidget);
  });

  testWidgets('Plus and FamilyPlus open the correct Plus placeholder', (
    tester,
  ) async {
    for (final plan in ['plus', 'family_plus']) {
      await _pumpDirectPage(
        tester,
        moduleId: 'M27',
        access: _access(membershipPlan: plan),
      );

      expect(find.byType(MedicalComingSoonPage), findsOneWidget);
      expect(find.text('Xét nghiệm & chỉ số y khoa'), findsOneWidget);
    }
  });

  testWidgets('Free is forwarded from a Plus module to upgrade', (
    tester,
  ) async {
    final router = _testRouter(
      initialLocation: HealthModuleRoutePaths.detail('M23'),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveAccessProvider.overrideWith(
            (ref) async => _access(membershipPlan: 'free'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      V2RoutePaths.payments,
    );
    expect(find.text('UPGRADE_DESTINATION'), findsOneWidget);
  });

  testWidgets('Guest is forwarded to login when the gate is reached', (
    tester,
  ) async {
    final router = _testRouter(
      initialLocation: HealthModuleRoutePaths.detail('M20'),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveAccessProvider.overrideWith(
            (ref) async =>
                _access(productAccess: 'guest', membershipPlan: 'free'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, V2RoutePaths.login);
    expect(find.text('LOGIN_DESTINATION'), findsOneWidget);
  });

  testWidgets('access error fails closed and offers retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveAccessProvider.overrideWith(
            (ref) => Future<EffectiveAccess?>.error(StateError('offline')),
          ),
        ],
        child: const MaterialApp(home: HealthModuleAccessPage(moduleId: 'M20')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa kiểm tra được quyền truy cập'), findsWidgets);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(MedicalComingSoonPage), findsNothing);
  });

  testWidgets('unknown module fails closed before reading access', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HealthModuleAccessPage(moduleId: 'M99')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy chức năng'), findsWidgets);
    expect(find.byType(MedicalComingSoonPage), findsNothing);
  });
}

Future<void> _pumpDirectPage(
  WidgetTester tester, {
  required String moduleId,
  required EffectiveAccess access,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [effectiveAccessProvider.overrideWith((ref) async => access)],
      child: MaterialApp(home: HealthModuleAccessPage(moduleId: moduleId)),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _testRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: HealthModuleRoutePaths.detailPattern,
        builder: (context, state) => HealthModuleAccessPage(
          moduleId: state.pathParameters['moduleId'] ?? '',
        ),
      ),
      GoRoute(
        path: V2RoutePaths.login,
        builder: (context, state) =>
            const Scaffold(body: Text('LOGIN_DESTINATION')),
      ),
      GoRoute(
        path: V2RoutePaths.payments,
        builder: (context, state) =>
            const Scaffold(body: Text('UPGRADE_DESTINATION')),
      ),
    ],
  );
}

EffectiveAccess _access({
  String userId = 'user-1',
  bool isAnonymous = false,
  String productAccess = 'member',
  required String membershipPlan,
}) {
  return EffectiveAccess(
    userId: userId,
    isAnonymous: isAnonymous,
    productAccess: productAccess,
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );
}
