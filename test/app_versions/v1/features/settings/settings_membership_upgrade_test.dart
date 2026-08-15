import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/domain/entities/settings_preferences_entity.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/pages/settings_page.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

void main() {
  testWidgets('guest does not see membership payment controls', (tester) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: null,
      accessFactory: () async => _access('free'),
    );
    addTearDown(harness.dispose);

    expect(
      find.byKey(const Key('settings_membership_upgrade_card')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_upgrade_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_renew_button')),
      findsNothing,
    );
  });

  testWidgets('free member sees Plus upgrade action', (tester) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('free'),
    );
    addTearDown(harness.dispose);

    expect(find.text('Nâng cấp VIP'), findsOneWidget);
    expect(find.text('Nâng cấp Plus'), findsOneWidget);
    expect(find.textContaining('Gia hạn gói'), findsNothing);
  });

  testWidgets('free member upgrade opens Plus payment route', (tester) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('free'),
    );
    addTearDown(harness.dispose);

    final button = find.byKey(const Key('settings_membership_upgrade_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('payment:plus'), findsOneWidget);
  });

  testWidgets('Plus member sees normal renewal action only', (tester) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('plus'),
    );
    addTearDown(harness.dispose);

    expect(find.text('Nâng cấp VIP'), findsNothing);
    expect(find.text('Nâng cấp FamilyPlus'), findsNothing);
    expect(find.text('Gia hạn gói Plus'), findsOneWidget);
    expect(
      find.byKey(const Key('settings_membership_upgrade_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_renew_button')),
      findsOneWidget,
    );
  });

  testWidgets('Plus renewal opens Plus payment route', (tester) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('plus'),
    );
    addTearDown(harness.dispose);

    final button = find.byKey(const Key('settings_membership_renew_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('payment:plus'), findsOneWidget);
  });

  testWidgets('FamilyPlus member sees normal renewal action only', (
    tester,
  ) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('family_plus'),
    );
    addTearDown(harness.dispose);

    expect(find.text('Nâng cấp VIP'), findsNothing);
    expect(find.text('Nâng cấp FamilyPlus'), findsNothing);
    expect(find.text('Gia hạn gói FamilyPlus'), findsOneWidget);
    expect(
      find.byKey(const Key('settings_membership_upgrade_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_renew_button')),
      findsOneWidget,
    );
  });

  testWidgets('FamilyPlus renewal opens FamilyPlus payment route', (
    tester,
  ) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('family_plus'),
    );
    addTearDown(harness.dispose);

    final button = find.byKey(const Key('settings_membership_renew_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('payment:family_plus'), findsOneWidget);
  });

  testWidgets('loading membership state fails closed', (tester) async {
    final pending = Completer<EffectiveAccess?>();
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () => pending.future,
      settle: false,
    );
    addTearDown(harness.dispose);

    expect(find.text('Nâng cấp VIP'), findsNothing);
    expect(
      find.byKey(const Key('settings_membership_upgrade_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_renew_button')),
      findsNothing,
    );
  });

  testWidgets('membership error fails closed instead of assuming Free', (
    tester,
  ) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => throw StateError('offline'),
    );
    addTearDown(harness.dispose);

    expect(find.text('Nâng cấp VIP'), findsNothing);
    expect(
      find.byKey(const Key('settings_membership_upgrade_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_renew_button')),
      findsNothing,
    );
  });

  testWidgets('unknown server plan fails closed without payment CTA', (
    tester,
  ) async {
    final harness = await _pumpSettings(
      tester,
      authUserId: 'user-1',
      accessFactory: () async => _access('unexpected_plan'),
    );
    addTearDown(harness.dispose);

    expect(find.text('Nâng cấp VIP'), findsNothing);
    expect(
      find.byKey(const Key('settings_membership_upgrade_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings_membership_renew_button')),
      findsNothing,
    );
  });
}

Future<_SettingsHarness> _pumpSettings(
  WidgetTester tester, {
  required String? authUserId,
  required Future<EffectiveAccess?> Function() accessFactory,
  bool settle = true,
}) async {
  final container = ProviderContainer(
    overrides: [
      currentAuthUserIdProvider.overrideWithValue(authUserId),
      effectiveAccessProvider.overrideWith((ref) => accessFactory()),
      dashboardProvider.overrideWithValue(const AsyncData(_testDashboard)),
      settingsPreferencesControllerProvider.overrideWith(
        _TestSettingsPreferencesController.new,
      ),
      settingsCacheSizeProvider.overrideWithValue(const AsyncData(0)),
      saleStateProvider.overrideWithValue(const AsyncData(SaleState.none)),
      adminAccessControllerProvider.overrideWith(
        _TestAdminAccessController.new,
      ),
    ],
  );

  final router = GoRouter(
    initialLocation: '/settings-test',
    routes: [
      GoRoute(
        path: '/settings-test',
        builder: (_, __) => const SettingsView(),
      ),
      GoRoute(
        path: membershipPaymentRoutePath,
        builder: (_, state) => Scaffold(
          body: Center(
            child: Text(
              'payment:${state.uri.queryParameters['plan']}',
              key: const Key('payment_destination'),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return _SettingsHarness(container: container, router: router);
}

EffectiveAccess _access(String plan) {
  return EffectiveAccess(
    userId: 'user-1',
    isAnonymous: false,
    productAccess: plan,
    membershipPlan: plan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );
}

class _SettingsHarness {
  final ProviderContainer container;
  final GoRouter router;

  const _SettingsHarness({required this.container, required this.router});

  void dispose() {
    router.dispose();
    container.dispose();
  }
}

class _TestSettingsPreferencesController extends SettingsPreferencesController {
  @override
  Future<SettingsPreferencesEntity> build() async {
    return SettingsPreferencesEntity.defaults();
  }
}

class _TestAdminAccessController extends AdminAccessController {
  @override
  Future<AdminAccessState> build() async {
    return const AdminAccessState.unauthorized();
  }
}

const _testDashboard = DashboardEntity(
  userId: 'user-1',
  fullName: 'Nabi Test',
  email: 'nabi@example.com',
  phone: '',
  gender: '',
  birthYear: 1990,
  occupation: '',
  heightCm: 0,
  weightKg: 0,
  bmi: 0,
  goals: [],
  conditions: [],
  habits: [],
  sleepQuality: '',
  activityLevel: '',
  waterPerDay: '',
  allergyName: '',
  allergyNote: '',
  treatmentName: '',
  medicationName: '',
  treatmentNote: '',
  concernText: '',
  surveyAnswers: {},
);
